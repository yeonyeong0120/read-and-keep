import 'models/recommendation_analysis.dart';
import 'models/recommendation_cache.dart';

/// 발표/결제 이슈 대비 폴백 데이터. 실제 LLM 응답 형식과 동일 구조다.
///
/// [AiConfig.useMockRecommendation] 이 true 이거나 LLM 파싱이 끝내 실패할 때
/// 사용한다. 아이콘은 모두 허용 화이트리스트(kAllowedKeywordIcons) 안의 값이다.
const RecommendationAnalysis kMockRecommendationAnalysis =
    RecommendationAnalysis(
  themes: ['성장과 자기 발견', '관계와 위로', '일상의 사색'],
  keywords: [
    RecommendationKeyword(label: '성장', icon: 'leaf'),
    RecommendationKeyword(label: '위로', icon: 'heart'),
    RecommendationKeyword(label: '사색', icon: 'lightbulb'),
    RecommendationKeyword(label: '여정', icon: 'journey'),
    RecommendationKeyword(label: '일상', icon: 'home'),
  ],
  summary: '잔잔한 문장 속에서 성장과 위로를 길어 올리는 독서 취향이에요.',
);
