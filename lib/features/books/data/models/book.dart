import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}/books/{bookId}` 문서와 매핑되는 책 모델.
///
/// 카카오 검색으로 찾은 책을 사용자가 "선택"하면 책장에 등록되며, 이후
/// 구절 저장·재선택에 따라 [lastCapturedAt]·[lastSelectedAt]·[captureCount] 가 갱신된다.
class Book {
  const Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
    required this.isbn13,
    required this.kakaoBookId,
    required this.publisher,
    required this.createdAt,
    required this.lastSelectedAt,
    this.lastCapturedAt,
    this.captureCount = 0,
  });

  /// Firestore 문서 ID.
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final String description;

  /// 카카오/알라딘 교차 키.
  final String isbn13;
  final String kakaoBookId;
  final String publisher;
  final DateTime createdAt;

  /// BK-001 마지막 선택 시각.
  final DateTime lastSelectedAt;

  /// 마지막 구절 저장 시각. 아직 구절이 없으면 null.
  final DateTime? lastCapturedAt;

  /// 누적 구절 저장 수.
  final int captureCount;

  /// Firestore 문서에서 모델로 변환. Timestamp 는 DateTime 으로 바꾸고,
  /// 누락 필드는 안전한 기본값으로 채운다.
  factory Book.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime? toDate(Object? value) => (value as Timestamp?)?.toDate();

    return Book(
      bookId: doc.id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isbn13: data['isbn13'] as String? ?? '',
      kakaoBookId: data['kakaoBookId'] as String? ?? '',
      publisher: data['publisher'] as String? ?? '',
      createdAt: toDate(data['createdAt']) ?? DateTime.now(),
      lastSelectedAt: toDate(data['lastSelectedAt']) ?? DateTime.now(),
      lastCapturedAt: toDate(data['lastCapturedAt']),
      captureCount: (data['captureCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 신규 등록 시 Firestore 에 쓸 데이터.
  ///
  /// [createdAt]·[lastSelectedAt] 은 클라이언트 시간이 아닌 서버 타임스탬프를 쓴다.
  /// [captureCount] 는 0, [lastCapturedAt] 은 null 로 초기화한다.
  Map<String, dynamic> toFirestoreOnCreate() {
    return {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'isbn13': isbn13,
      'kakaoBookId': kakaoBookId,
      'publisher': publisher,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSelectedAt': FieldValue.serverTimestamp(),
      'lastCapturedAt': null,
      'captureCount': 0,
    };
  }
}
