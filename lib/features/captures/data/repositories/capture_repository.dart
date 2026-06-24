import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/capture.dart';

/// 문장 수집 저장소.
///
/// 담당 역할:
/// - 저장한 구절 추가
/// - 책별 저장 구절 목록 조회
/// - 책 문서의 구절 수 / 코멘트 수 / 최근 기록 갱신
/// - 공개 구절 publicCaptures 복제 / 삭제
class CaptureRepository {
  CaptureRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _capturesRef({
    required String userId,
    required String bookId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId)
        .collection('captures');
  }

  DocumentReference<Map<String, dynamic>> _bookRef({
    required String userId,
    required String bookId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookId);
  }

  DocumentReference<Map<String, dynamic>> _publicCaptureRef({
    required String captureId,
  }) {
    return _firestore.collection('publicCaptures').doc(captureId);
  }

  /// 특정 책에 저장된 구절 목록 실시간 조회.
  Stream<List<Capture>> watchCapturesByBook(String bookId) {
    final userId = _uid;

    return _capturesRef(userId: userId, bookId: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Capture.fromFirestore(doc)).toList(),
        );
  }

  /// 문장/구절 저장.
  Future<void> addCapture({
    required String bookId,
    required String bookTitle,
    required String quote,
    required String comment,
    required int? pageNumber,
    required bool isPublic,
    required CaptureSource source,
    String? ocrRawText,
  }) async {
    final userId = _uid;

    final captureDoc = _capturesRef(
      userId: userId,
      bookId: bookId,
    ).doc();

    final capture = Capture(
      id: captureDoc.id,
      userId: userId,
      bookId: bookId,
      bookTitle: bookTitle,
      quote: quote,
      comment: comment,
      pageNumber: pageNumber,
      isPublic: isPublic,
      source: source,
      ocrRawText: ocrRawText,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      captureDoc,
      capture.toFirestoreOnCreate(),
    );

    if (isPublic) {
      batch.set(
        _publicCaptureRef(captureId: captureDoc.id),
        _publicCaptureDataOnCreate(
          captureId: captureDoc.id,
          userId: userId,
          bookId: bookId,
          bookTitle: bookTitle,
          quote: quote,
          comment: comment,
          pageNumber: pageNumber,
          source: source,
          ocrRawText: ocrRawText,
        ),
      );
    }

    batch.set(
      _bookRef(userId: userId, bookId: bookId),
      {
        'savedQuoteCount': FieldValue.increment(1),
        'commentCount': comment.trim().isEmpty
            ? FieldValue.increment(0)
            : FieldValue.increment(1),
        'lastCapturedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// 구절 수정.
  ///
  /// 핵심:
  /// - 비공개 → 공개 전환이면 publicCaptures 새 문서 생성
  /// - 이미 공개된 구절 수정이면 기존 likeCount/commentCount/viewCount는 유지
  /// - 공개 → 비공개 전환이면 publicCaptures 및 하위 댓글/좋아요/조회 기록 삭제
  Future<void> updateCapture({
    required Capture capture,
    required String quote,
    required String comment,
    required int? pageNumber,
    required bool isPublic,
  }) async {
    final userId = _uid;

    final captureRef = _capturesRef(
      userId: userId,
      bookId: capture.bookId,
    ).doc(capture.id);

    final beforeHadComment = capture.comment.trim().isNotEmpty;
    final afterHasComment = comment.trim().isNotEmpty;

    int commentCountDelta = 0;
    if (!beforeHadComment && afterHasComment) {
      commentCountDelta = 1;
    } else if (beforeHadComment && !afterHasComment) {
      commentCountDelta = -1;
    }

    final publicRef = _publicCaptureRef(captureId: capture.id);
    final publicSnapshot = await publicRef.get();
    final publicExists = publicSnapshot.exists;

    final batch = _firestore.batch();

    batch.update(captureRef, {
      'quote': quote,
      'comment': comment,
      'pageNumber': pageNumber,
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (isPublic) {
      if (publicExists) {
        batch.set(
          publicRef,
          _publicCaptureDataOnExistingUpdate(
            capture: capture,
            userId: userId,
            quote: quote,
            comment: comment,
            pageNumber: pageNumber,
          ),
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          publicRef,
          _publicCaptureDataOnCreate(
            captureId: capture.id,
            userId: userId,
            bookId: capture.bookId,
            bookTitle: capture.bookTitle,
            quote: quote,
            comment: comment,
            pageNumber: pageNumber,
            source: capture.source,
            ocrRawText: capture.ocrRawText,
          ),
        );
      }
    }

    final bookUpdateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (commentCountDelta != 0) {
      bookUpdateData['commentCount'] = FieldValue.increment(commentCountDelta);
    }

    batch.set(
      _bookRef(userId: userId, bookId: capture.bookId),
      bookUpdateData,
      SetOptions(merge: true),
    );

    await batch.commit();

    if (!isPublic) {
      await _deletePublicCaptureTree(
        userId: userId,
        captureId: capture.id,
      );
    }
  }

  /// 저장한 구절 삭제.
  Future<void> deleteCapture({
    required String bookId,
    required String captureId,
    bool hadComment = false,
  }) async {
    final userId = _uid;

    final captureRef = _capturesRef(
      userId: userId,
      bookId: bookId,
    ).doc(captureId);

    final captureSnapshot = await captureRef.get();

    if (!captureSnapshot.exists) {
      return;
    }

    final captureData = captureSnapshot.data();
    final isPublic = captureData?['isPublic'] == true;

    await _deleteCaptureComments(captureRef);

    // 공개 구절이면 당연히 삭제.
    // 비공개여도 예전에 남은 publicCaptures 찌꺼기가 있을 수 있으므로
    // 안전하게 get + userId 확인 후 삭제한다.
    if (isPublic) {
      await _deletePublicCaptureTree(
        userId: userId,
        captureId: captureId,
      );
    } else {
      await _deletePublicCaptureTree(
        userId: userId,
        captureId: captureId,
      );
    }

    final batch = _firestore.batch();

    batch.delete(captureRef);

    batch.set(
      _bookRef(userId: userId, bookId: bookId),
      {
        'savedQuoteCount': FieldValue.increment(-1),
        'commentCount':
            hadComment ? FieldValue.increment(-1) : FieldValue.increment(0),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> _deleteCaptureComments(
    DocumentReference<Map<String, dynamic>> captureRef,
  ) async {
    await _deleteCollection(captureRef.collection('comments'));
  }

  Future<void> _deletePublicCaptureTree({
    required String userId,
    required String captureId,
  }) async {
    final exactRef = _publicCaptureRef(captureId: captureId);
    final exactSnapshot = await exactRef.get();

    // 1. 현재 구조: publicCaptures/{captureId}
    if (exactSnapshot.exists) {
      final data = exactSnapshot.data();

      if (data != null && data['userId'] == userId) {
        await _deletePublicCaptureDocument(
          publicCaptureRef: exactRef,
          userId: userId,
        );
      }
    }

    // 2. 예전 구조 대비: 문서 ID는 다르지만 captureId 필드로 연결된 경우
    final matchedSnapshot = await _firestore
        .collection('publicCaptures')
        .where('captureId', isEqualTo: captureId)
        .get();

    for (final doc in matchedSnapshot.docs) {
      final data = doc.data();

      if (data['userId'] == userId) {
        await _deletePublicCaptureDocument(
          publicCaptureRef: doc.reference,
          userId: userId,
        );
      }
    }
  }

  Future<void> _deletePublicCaptureDocument({
    required DocumentReference<Map<String, dynamic>> publicCaptureRef,
    required String userId,
  }) async {
    final snapshot = await publicCaptureRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();

    if (data == null || data['userId'] != userId) {
      return;
    }

    await _deleteCollection(publicCaptureRef.collection('comments'));
    await _deleteCollection(publicCaptureRef.collection('likes'));
    await _deleteCollection(publicCaptureRef.collection('views'));

    await publicCaptureRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collectionRef,
  ) async {
    const int batchSize = 300;

    while (true) {
      final snapshot = await collectionRef.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (snapshot.docs.length < batchSize) {
        break;
      }
    }
  }

  Map<String, dynamic> _publicCaptureDataOnCreate({
    required String captureId,
    required String userId,
    required String bookId,
    required String bookTitle,
    required String quote,
    required String comment,
    required int? pageNumber,
    required CaptureSource source,
    required String? ocrRawText,
  }) {
    return {
      'captureId': captureId,
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'quote': quote,
      'comment': comment,
      'pageNumber': pageNumber,
      'source': source.value,
      'ocrRawText': ocrRawText,
      'isPublic': true,
      'likeCount': 0,
      'commentCount': 0,
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _publicCaptureDataOnExistingUpdate({
    required Capture capture,
    required String userId,
    required String quote,
    required String comment,
    required int? pageNumber,
  }) {
    return {
      'captureId': capture.id,
      'userId': userId,
      'bookId': capture.bookId,
      'bookTitle': capture.bookTitle,
      'quote': quote,
      'comment': comment,
      'pageNumber': pageNumber,
      'source': capture.source.value,
      'ocrRawText': capture.ocrRawText,
      'isPublic': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}