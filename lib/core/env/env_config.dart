import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 외부 API 키 접근 헬퍼.
///
/// 모든 키는 [optional] 로 노출한다. 키가 .env 에 없거나 빈 값이면 빈 문자열을
/// 반환한다. 호출하는 쪽 (각 feature 의 data 레이어) 에서 사용 직전에 빈 값 검증을 한다.
///
/// Firebase 관련 키 (API key, project id 등) 는 firebase_options.dart 가 자동
/// 관리하므로 이 클래스에서 다루지 않는다.
class EnvConfig {
  EnvConfig._();

  static String _read(String key) => dotenv.env[key]?.trim() ?? '';

  // === 카카오 ===
  // 로그인 SDK 초기화용. 인증 기능 구현 단계에서 실제 사용한다.
  static String get kakaoNativeAppKey => _read('KAKAO_NATIVE_APP_KEY');

  // 책 검색 REST API 호출용.
  static String get kakaoRestApiKey => _read('KAKAO_REST_API_KEY');

  // === Gemini ===
  // (옵션 B 통합 후 미사용) AI Studio API Key 직접 호출용 getter 는 제거됨.
  // 현재 Gemini 호출은 보조 FirebaseApp(aiApp) + firebase_ai 로만 이뤄지며
  // .env 의 GEMINI_API_KEY 는 필요하지 않다.

  // === 알라딘 ===
  // 베스트셀러 Open API 호출용.
  static String get aladinTtbKey => _read('ALADIN_TTB_KEY');

  // === 기상청 ===
  // 단기예보 호출용. 날씨 장식은 선택 기능.
  static String get kmaServiceKey => _read('KMA_SERVICE_KEY');
}