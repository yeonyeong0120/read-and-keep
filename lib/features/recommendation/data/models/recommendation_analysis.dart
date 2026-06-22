import 'recommendation_cache.dart';

/// 1차 LLM(구절 분석) 결과 모델.
///
/// Gemini 가 응답한 JSON({themes, keywords, summary})을 파싱한다.
/// 키워드 칩은 [RecommendationKeyword] 를 재사용한다. 본 모델은 LLM 응답
/// 파싱 전용이며, 최종 캐시 저장은 [RecommendationCache] 가 담당한다.
class RecommendationAnalysis {
  const RecommendationAnalysis({
    required this.themes,
    required this.keywords,
    required this.summary,
  });

  final List<String> themes;
  final List<RecommendationKeyword> keywords;
  final String summary;

  /// LLM JSON 을 관대하게 파싱한다. 타입이 어긋나면 안전한 기본값으로 채운다.
  factory RecommendationAnalysis.fromJson(Map<String, dynamic> json) {
    final themesRaw = json['themes'];
    final keywordsRaw = json['keywords'];

    return RecommendationAnalysis(
      themes: themesRaw is List
          ? themesRaw.map((e) => e.toString()).toList()
          : const <String>[],
      keywords: keywordsRaw is List
          ? keywordsRaw
              .whereType<Map<Object?, Object?>>()
              .map(
                (e) => RecommendationKeyword.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const <RecommendationKeyword>[],
      summary: json['summary'] as String? ?? '',
    );
  }
}
