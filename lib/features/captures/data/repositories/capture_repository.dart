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

  /// 현재 사용자가 공개한 구절 수.
  ///
  /// publicCaptures 최상위 컬렉션을 userId 로 필터링한 count() 집계 1회로 구한다.
  /// publicCaptures 는 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의
  /// 단일 진실이며, 책별 captures 순회보다 가볍다. userId 단일 등가 필터라 자동
  /// 단일 필드 인덱스로 동작하고 별도 복합 인덱스가 필요 없다.
  Future<int> countPublicCaptures() async {
    final userId = _uid;

    final query = _firestore
        .collection('publicCaptures')
        .where('userId', isEqualTo: userId);

    final snapshot = await query.count().get();

    return snapshot.count ?? 0;
  }

  /// 특정 책에 저장된 구절 목록 실시간 조회.
  Stream<List<Capture>> watchCapturesByBook(String bookId) {
    final userId = _uid;

    return _capturesRef(userId: userId, bookId: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Capture.fromFirestore(doc))
              .toList(),
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
  /// - 이미 공개된 구절 수정이면 기존 likeCount/commentCount는 유지
  /// - 공개 → 비공개 전환이면 publicCaptures 삭제
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

    final publicRef = _publicCaptureRef(captureId: capture.id);

    // 중요:
    // publicCaptures 문서가 이미 있는지 확인해서
    // 새 생성 / 기존 수정 로직을 분리한다.
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
        // 이미 공개된 구절 수정:
        // 좋아요 수와 댓글 수는 건드리지 않는다.
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
        // 비공개였던 구절을 공개로 전환:
        // publicCaptures 문서를 새로 만든다.
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
    } else {
      // 공개였던 구절을 비공개로 전환:
      // 공개 피드에서 제거한다.
      if (publicExists) {
        batch.delete(publicRef);
      }
    }

    batch.set(
      _bookRef(userId: userId, bookId: capture.bookId),
      {
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
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

    await _deleteCaptureComments(captureRef);

    final batch = _firestore.batch();

    batch.delete(captureRef);

    batch.delete(
      _publicCaptureRef(captureId: captureId),
    );

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
    const int batchSize = 300;

    while (true) {
      final commentsSnapshot =
          await captureRef.collection('comments').limit(batchSize).get();

      if (commentsSnapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();

      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }

      await batch.commit();

      if (commentsSnapshot.docs.length < batchSize) {
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