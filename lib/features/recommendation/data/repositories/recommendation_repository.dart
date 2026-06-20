import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recommendation_cache.dart';

/// 추천(RC) 데이터 저장소.
///
/// 담당 역할:
/// - 추천 캐시(users/{uid}/recommendation/latest) 조회/저장
/// - 누적 구절 수 집계(DriftStatus 판정 입력)
/// - 추천에서 사용자가 숨긴 책(dismissedBooks) 관리
///
/// 본 Repository 는 예외를 그대로 전파한다. 로딩/에러 상태 관리는 호출하는
/// 쪽(Notifier)이 AsyncValue 로 처리한다.
class RecommendationRepository {
  RecommendationRepository({
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

  /// 추천 캐시 문서: users/{uid}/recommendation/latest.
  DocumentReference<Map<String, dynamic>> get _cacheRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('recommendation')
        .doc('latest');
  }

  /// 사용자 책 컬렉션: users/{uid}/books.
  CollectionReference<Map<String, dynamic>> get _booksRef {
    return _firestore.collection('users').doc(_uid).collection('books');
  }

  /// 추천에서 숨긴 책 컬렉션: users/{uid}/dismissedBooks.
  CollectionReference<Map<String, dynamic>> get _dismissedBooksRef {
    return _firestore.collection('users').doc(_uid).collection('dismissedBooks');
  }

  /// 추천 캐시 실시간 구독. 문서가 없으면 null 을 방출한다.
  Stream<RecommendationCache?> watchCache() {
    return _cacheRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return RecommendationCache.fromFirestore(doc);
    });
  }

  /// 추천 캐시 단건 조회. 없으면 null.
  Future<RecommendationCache?> getCache() async {
    final doc = await _cacheRef.get();
    if (!doc.exists) return null;
    return RecommendationCache.fromFirestore(doc);
  }

  /// 추천 캐시 저장(덮어쓰기).
  Future<void> saveCache(RecommendationCache cache) async {
    await _cacheRef.set(cache.toFirestore());
  }

  /// 사용자의 전체 누적 구절 수.
  ///
  /// captures 는 books 하위 컬렉션이므로 collectionGroup('captures') 로도 셀 수
  /// 있으나, 컬렉션 그룹 쿼리는 별도 인덱스를 요구할 수 있어 books 문서의 카운터
  /// 필드를 클라이언트에서 합산하는 방식을 쓴다(인덱스 불필요).
  ///
  /// 주의: 실제로 유지·증감되는 카운터는 savedQuoteCount 다
  /// (capture_repository 의 addCapture/deleteCapture 가 ±1 처리). captureCount
  /// 필드는 책 생성 시 0 으로만 초기화되고 갱신되지 않으므로, savedQuoteCount 를
  /// 우선 합산하고 없을 때만 captureCount 로 폴백한다.
  Future<int> countTotalCaptures() async {
    final snapshot = await _booksRef.get();

    var total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final saved = (data['savedQuoteCount'] as num?)?.toInt();
      final legacy = (data['captureCount'] as num?)?.toInt();
      total += saved ?? legacy ?? 0;
    }

    return total;
  }

  /// 추천 도서를 숨김 처리한다. dismissedAt 은 서버 타임스탬프로 기록한다.
  Future<void> dismissBook({
    required String bookId,
    required String title,
  }) async {
    await _dismissedBooksRef.doc(bookId).set({
      'title': title,
      'dismissedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 숨긴 책 ID 목록.
  Future<List<String>> getDismissedBookIds() async {
    final snapshot = await _dismissedBooksRef.get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
