import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/capture.dart';

/// 구절(capture) CRUD(Firestore) 를 담당하는 Repository.
///
/// 본 Repository 는 예외를 그대로 던진다. 로딩/에러 상태 관리는 호출하는
/// 쪽(Notifier)이 AsyncValue.guard 등으로 처리한다.
class CaptureRepository {
  CaptureRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// `users/{uid}/books` 컬렉션. 미로그인 시 [StateError].
  CollectionReference<Map<String, dynamic>> get _booksRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    return _firestore.collection('users').doc(user.uid).collection('books');
  }

  /// 특정 책의 `captures` 서브컬렉션.
  CollectionReference<Map<String, dynamic>> _capturesRef(String bookId) =>
      _booksRef.doc(bookId).collection('captures');

  /// 특정 책의 구절 목록 스트림. capturedAt 내림차순.
  Stream<List<Capture>> watchCaptures(String bookId) {
    return _capturesRef(bookId)
        .orderBy('capturedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Capture.fromFirestore).toList());
  }

  /// 구절 저장.
  ///
  /// WriteBatch 로 다음을 원자적으로 처리한다.
  ///   1) captures 문서 생성(doc() 로 id 선확보 후 set).
  ///   2) 상위 book 문서의 captureCount 를 +1, lastCapturedAt 을 서버 타임스탬프로 갱신.
  /// 반환 [Capture] 는 선확보한 문서 id 로 채워 돌려준다(즉시 재조회에 의존하지 않는다).
  Future<Capture> addCapture({
    required String bookId,
    required String text,
    int? page,
    String comment = '',
    required bool isPublic,
    required CaptureSource source,
    String? ocrRawText,
  }) async {
    final bookRef = _booksRef.doc(bookId);
    final captureRef = _capturesRef(bookId).doc();

    // set 과 반환에 같은 객체를 쓴다. capturedAt 은 toFirestoreOnCreate 에서
    // serverTimestamp 로 치환되므로 여기 로컬 시각은 반환 객체용 자리표시값이다.
    final capture = Capture(
      captureId: captureRef.id,
      bookId: bookId,
      text: text,
      page: page,
      comment: comment,
      isPublic: isPublic,
      captureType: Capture.classifyType(text),
      captureSource: source.value,
      ocrRawText: ocrRawText,
      capturedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(captureRef, capture.toFirestoreOnCreate());
    batch.update(bookRef, {
      'captureCount': FieldValue.increment(1),
      'lastCapturedAt': FieldValue.serverTimestamp(),
    });
    // publicBooks 복제는 하지 않는다(isPublic 필드만 저장).
    // TODO: TR 단계에서 publicBooks 복제.
    await batch.commit();

    return capture;
  }

  /// 구절 삭제.
  ///
  /// batch 로 captures 문서 삭제 + 상위 book 의 captureCount 를 -1 한다.
  Future<void> deleteCapture(String bookId, String captureId) async {
    final batch = _firestore.batch();
    batch.delete(_capturesRef(bookId).doc(captureId));
    batch.update(_booksRef.doc(bookId), {
      'captureCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// 구절 수정. text/page/comment/isPublic 을 갱신하고 captureType 을 재산정한다.
  Future<void> updateCapture({
    required String bookId,
    required String captureId,
    required String text,
    int? page,
    String comment = '',
    required bool isPublic,
  }) async {
    await _capturesRef(bookId).doc(captureId).update({
      'text': text,
      'page': page,
      'comment': comment,
      'isPublic': isPublic,
      'captureType': Capture.classifyType(text),
    });
  }
}
