import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}/books/{bookId}` 문서와 매핑되는 책 모델.
///
/// 카카오 검색으로 찾은 책을 사용자가 "선택"하면 책장에 등록되며, 이후
/// 구절 저장·재선택에 따라 [lastCapturedAt]·[lastSelectedAt]·[savedQuoteCount] 가 갱신된다.
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
    this.updatedAt,
    this.savedQuoteCount = 0,
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

  /// 마지막 구절 저장 시각. 아직 구절이 없으면 null. (add 때만 갱신됨)
  final DateTime? lastCapturedAt;

  /// 마지막 구절 활동 시각. 아직 구절 활동이 없으면 null.
  ///
  /// capture_repository 의 add/update/delete 가 매번 갱신하며, 오직 구절
  /// 작업에서만 갱신된다(책 생성·재선택은 건드리지 않음). 따라서 "최근 기록
  /// 시각"의 단일 진실 필드다.
  final DateTime? updatedAt;

  /// 누적 구절 저장 수(단일 진실 필드).
  ///
  /// capture_repository 의 addCapture/deleteCapture 가 ±1 로 갱신한다.
  final int savedQuoteCount;

  /// 하위 호환 별칭. 기존 화면 코드(`book.captureCount`)가 그대로 동작하도록
  /// [savedQuoteCount] 를 반환한다. 신규 코드는 [savedQuoteCount] 를 직접 쓴다.
  int get captureCount => savedQuoteCount;

  /// "최근 기록 시각"(표시·정렬용 단일 진실).
  ///
  /// 마지막 구절 활동([updatedAt])을 1순위로 하되, 레거시 문서 호환을 위해
  /// 마지막 저장([lastCapturedAt]) → 마지막 선택([lastSelectedAt]) 순으로 폴백한다.
  /// 구절을 저장/수정/삭제하면 [updatedAt] 이 갱신되어 이 값이 최신이 된다.
  DateTime get lastRecordAt => updatedAt ?? lastCapturedAt ?? lastSelectedAt;

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
      updatedAt: toDate(data['updatedAt']),
      // savedQuoteCount 가 단일 진실이며, 레거시 문서 호환을 위해
      // captureCount 를 폴백으로 읽는다.
      savedQuoteCount: (data['savedQuoteCount'] as num?)?.toInt() ??
          (data['captureCount'] as num?)?.toInt() ??
          0,
    );
  }

  /// 신규 등록 시 Firestore 에 쓸 데이터.
  ///
  /// [createdAt]·[lastSelectedAt] 은 클라이언트 시간이 아닌 서버 타임스탬프를 쓴다.
  /// [savedQuoteCount] 는 0, [lastCapturedAt] 은 null 로 초기화한다.
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
      'savedQuoteCount': 0,
    };
  }

  /// 일부 필드만 교체한 사본을 만든다.
  ///
  /// 신규 등록 시 Firestore 문서 ID 를 확정한 뒤 [bookId] 만 채워 반환하는 데 쓴다.
  Book copyWith({
    String? bookId,
    String? title,
    String? author,
    String? coverUrl,
    String? description,
    String? isbn13,
    String? kakaoBookId,
    String? publisher,
    DateTime? createdAt,
    DateTime? lastSelectedAt,
    DateTime? lastCapturedAt,
    DateTime? updatedAt,
    int? savedQuoteCount,
  }) {
    return Book(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      isbn13: isbn13 ?? this.isbn13,
      kakaoBookId: kakaoBookId ?? this.kakaoBookId,
      publisher: publisher ?? this.publisher,
      createdAt: createdAt ?? this.createdAt,
      lastSelectedAt: lastSelectedAt ?? this.lastSelectedAt,
      lastCapturedAt: lastCapturedAt ?? this.lastCapturedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      savedQuoteCount: savedQuoteCount ?? this.savedQuoteCount,
    );
  }
}
