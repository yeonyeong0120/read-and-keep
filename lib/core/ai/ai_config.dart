/// 추천(RC) 기능의 AI 설정 상수.
///
/// Firebase AI Logic(Gemini Developer API) 를 사용한다. 모델이 종료되면
/// [geminiModel] 한 줄만 교체하면 1차/2차 LLM 호출 모두에 반영된다.
/// 참고: https://firebase.google.com/docs/ai-logic/models
abstract final class AiConfig {
  AiConfig._();

  /// 사용하는 Gemini 모델명. 모델 종료 시 이 한 줄만 교체하면 된다.
  static const String geminiModel = 'gemini-3.1-flash-lite';

  /// 보조 FirebaseApp 이름. Gemini 호출 전용 보조 프로젝트(read-and-keep-ai)를
  /// 가리킨다. 데이터(Firestore/Storage/Auth)는 기본 앱을 그대로 쓴다.
  static const String aiAppName = 'aiApp';

  /// 추천 활성화 최소 책 수.
  static const int recommendationMinBooks = 1;

  /// 추천 활성화 최소 누적 구절 수.
  static const int recommendationMinCaptures = 3;

  /// 추천 분석 시 우선 고려할 최근 기간(일). 최근 30일을 우선한다.
  static const int recommendationAnalysisDays = 30;

  /// 데모 폴백 스위치. 결제/쿼터 이슈로 LLM 호출이 막히면 true 로 바꿔
  /// mock 추천 데이터를 사용한다(LLM 호출 없이 동일 형식의 결과 반환).
  static const bool useMockRecommendation = false;
}
