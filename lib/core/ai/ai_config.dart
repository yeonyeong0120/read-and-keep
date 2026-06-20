/// 추천(RC) 기능의 AI 설정 상수.
///
/// Firebase AI Logic(Gemini Developer API) 를 사용한다. 모델이 종료되면
/// [geminiModel] 한 줄만 교체하면 1차/2차 LLM 호출 모두에 반영된다.
/// 참고: https://firebase.google.com/docs/ai-logic/models
abstract final class AiConfig {
  AiConfig._();

  /// 사용하는 Gemini 모델명. 모델 종료 시 이 한 줄만 교체하면 된다.
  static const String geminiModel = 'gemini-3.1-flash-lite';

  /// 추천 활성화 최소 책 수.
  static const int recommendationMinBooks = 1;

  /// 추천 활성화 최소 누적 구절 수.
  static const int recommendationMinCaptures = 3;

  /// 추천 분석 시 우선 고려할 최근 기간(일). 최근 30일을 우선한다.
  static const int recommendationAnalysisDays = 30;
}
