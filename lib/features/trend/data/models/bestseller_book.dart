/// 알라딘 베스트셀러 한 권을 표현하는 모델.
///
/// 알라딘 ItemList.aspx(QueryType=Bestseller) 응답의 item 한 건을 매핑한다.
/// Firestore 가 아니라 외부 API(JSON) 에서 오므로 fromAladinJson 으로 생성한다.
class BestsellerBook {
  const BestsellerBook({
    required this.rank,
    required this.title,
    required this.author,
    required this.publisher,
    required this.isbn13,
    required this.coverUrl,
    required this.description,
    this.pubDate,
    this.link = '',
  });

  /// 베스트셀러 순위(알라딘 bestRank). 누락 시 0.
  final int rank;

  /// 책 제목.
  final String title;

  /// 저자. 알라딘은 "저자1, 저자2 (지은이)" 형태로 줄 수 있어 그대로 보존한다.
  final String author;

  /// 출판사.
  final String publisher;

  /// ISBN13(책 식별자). 누락 가능.
  final String isbn13;

  /// 표지 이미지 URL(알라딘 cover, Cover=Big 요청 기준).
  final String coverUrl;

  /// 책 소개(알라딘 description). 누락 시 빈 문자열.
  final String description;

  /// 출간일 문자열(알라딘 pubDate, 예: "2024-01-01"). 누락 가능.
  final String? pubDate;

  /// 알라딘 상품 페이지 링크(약관상 출처 링크). 누락 시 빈 문자열.
  final String link;

  /// 알라딘 상품 페이지 URL.
  ///
  /// 응답의 [link] 가 있으면 그대로 쓰고, 없으면 isbn13 기반 상품 URL 을 만든다.
  /// 둘 다 없으면 빈 문자열을 반환한다(호출 측에서 링크 노출 여부 판단).
  String get aladinProductUrl {
    if (link.isNotEmpty) return link;
    if (isbn13.isNotEmpty) {
      return 'https://www.aladin.co.kr/shop/wproduct.aspx?ISBN=$isbn13';
    }
    return '';
  }

  /// 알라딘 응답 item 한 건(JSON Map)을 [BestsellerBook] 으로 변환한다.
  ///
  /// 모든 필드는 누락에 안전한 기본값을 둔다. 숫자 필드(bestRank)는 int 또는
  /// String 으로 올 수 있어 방어적으로 파싱한다.
  factory BestsellerBook.fromAladinJson(Map<String, dynamic> json) {
    return BestsellerBook(
      rank: _asInt(json['bestRank']),
      title: (json['title'] as String?)?.trim() ?? '',
      author: (json['author'] as String?)?.trim() ?? '',
      publisher: (json['publisher'] as String?)?.trim() ?? '',
      isbn13: (json['isbn13'] as String?)?.trim() ?? '',
      coverUrl: (json['cover'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      pubDate: (json['pubDate'] as String?)?.trim(),
      link: (json['link'] as String?)?.trim() ?? '',
    );
  }

  /// bestRank 등 숫자 필드가 int/String/null 로 섞여 와도 안전하게 int 로 만든다.
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
