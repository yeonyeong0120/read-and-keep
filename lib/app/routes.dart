/// 앱 라우트 경로 상수.
///
/// go_router 의 경로 문자열을 한 곳에서 관리한다. 화면 이동 시
/// 문자열 리터럴 대신 본 상수를 사용해 오타와 경로 불일치를 방지한다.
abstract final class AppRoutes {
  AppRoutes._();

  /// 로그인 화면 (CM-002). 미인증 사용자의 기본 진입점.
  static const String login = '/login';

  /// 회원가입 화면 (CM-003).
  static const String signup = '/signup';

  /// 비밀번호 재설정 화면 (CM-004).
  static const String passwordReset = '/password-reset';

  // --- 메인 탭 (하단 네비게이션 셸) ---

  /// 홈 탭 (MN). 인증된 사용자의 기본 진입점.
  static const String home = '/';

  /// 추천 탭 (RC).
  static const String recommend = '/recommend';

  /// 트렌드 탭 (TR).
  static const String trend = '/trend';

  // --- 책 관리 (BK) ---

  /// 책 선택 화면 (BK-001). 홈 브랜치 하위(탭바 유지).
  static const String bookSelect = '/book-select';

  /// 책장 전체보기 화면 (BK-002). 홈 브랜치 하위(탭바 유지).
  static const String bookshelf = '/bookshelf';

  /// 책 상세 화면 (BK-004). 실제 GoRoute path 는 '/book-detail/:bookId'.
  static const String bookDetail = '/book-detail';

  /// 특정 책 상세 경로를 만든다.
  static String bookDetailOf(String bookId) => '$bookDetail/$bookId';
}
