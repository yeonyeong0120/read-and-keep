import 'book.dart';

/// 카카오 책 검색 API 응답의 document 항목 1건을 매핑한 모델.
///
/// 아직 책장에 등록되지 않은 "후보" 책을 표현한다. 사용자가 선택하면
/// [toBook] 으로 책장 등록용 [Book] 으로 변환한다.
class KakaoBook {
  const KakaoBook({
    required this.title,
    required this.authors,
    required this.thumbnail,
    required this.contents,
    required this.isbn,
    required this.publisher,
    required this.datetime,
  });

  final String title;
  final List<String> authors;
  final String thumbnail;
  final String contents;

  /// 원본 ISBN. "ISBN10 ISBN13" 처럼 공백으로 두 값이 함께 오는 경우가 있다.
  final String isbn;
  final String publisher;
  final String datetime;

  /// [isbn] 을 공백으로 분리해 13자리 ISBN 을 추출한다.
  ///
  /// 13자리 토큰이 있으면 그 값을, 없으면 첫 토큰을, 토큰이 전혀 없으면 빈 문자열을 반환한다.
  String get isbn13 {
    final tokens =
        isbn.split(' ').where((token) => token.isNotEmpty).toList();
    if (tokens.isEmpty) return '';
    for (final token in tokens) {
      if (token.length == 13) return token;
    }
    return tokens.first;
  }

  /// 저자 목록을 ", " 로 결합한다. 비어 있으면 "저자 미상".
  String get authorText => authors.isEmpty ? '저자 미상' : authors.join(', ');

  /// 카카오 응답 document 항목 1건을 파싱한다.
  factory KakaoBook.fromJson(Map<String, dynamic> json) {
    return KakaoBook(
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      thumbnail: json['thumbnail'] as String? ?? '',
      contents: json['contents'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
    );
  }

  /// 책장 등록용 [Book] 으로 변환한다.
  ///
  /// [bookId] 는 빈 문자열로 두고, Firestore 문서 ID 는 Repository 가 채운다.
  /// 시간 필드는 자리만 채우며, 실제 저장값은 [Book.toFirestoreOnCreate] 의
  /// 서버 타임스탬프가 사용된다.
  Book toBook() {
    final now = DateTime.now();
    return Book(
      bookId: '',
      title: title,
      author: authorText,
      coverUrl: thumbnail,
      description: contents,
      isbn13: isbn13,
      kakaoBookId: isbn13,
      publisher: publisher,
      createdAt: now,
      lastSelectedAt: now,
      lastCapturedAt: null,
      captureCount: 0,
    );
  }
}
