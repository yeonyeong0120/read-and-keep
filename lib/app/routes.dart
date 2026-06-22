import '../features/captures/data/models/capture.dart';
import '../features/captures/data/models/capture_comment.dart';

/// 캡처 흐름(방법 선택/OCR/확인) 화면에 공통으로 넘기는 책 정보.
///
/// 팀원 화면들의 생성자가 책 정보를 개별 필드로 받으므로,
/// go_router 의 `extra` 로 본 레코드를 넘긴 뒤 빌더에서 펼쳐 전달한다.
typedef CaptureBookArgs = ({
  String bookId,
  String bookTitle,
  String bookAuthor,
  String bookPublisher,
  String? bookCoverUrl,
});

/// 문장 확인/저장(CaptureConfirmScreen) 화면용 인자.
///
/// 책 정보에 더해 OCR/직접입력으로 들어온 초기값과 출처를 함께 넘긴다.
typedef CaptureConfirmArgs = ({
  String bookId,
  String bookTitle,
  String bookAuthor,
  String bookPublisher,
  String? bookCoverUrl,
  String initialQuote,
  int? initialPageNumber,
  String initialComment,
  CaptureSource source,
  String? ocrRawText,
});

/// 구절 코멘트 수정(CaptureCommentEditScreen) 화면용 인자.
typedef CaptureCommentEditArgs = ({
  Capture capture,
  CaptureComment comment,
});

/// 앱 라우트 경로 상수.
///
/// go_router 의 경로 문자열을 한 곳에서 관리한다. 화면 이동 시
/// 문자열 리터럴 대신 본 상수를 사용해 오타와 경로 불일치를 방지한다.
abstract final class AppRoutes {
  AppRoutes._();

  /// 스플래시 화면 (CM-001). 앱 시작 시 인증 상태 확정 전까지 머무는 진입점.
  static const String splash = '/splash';

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

  /// 추천 상세 (RC-003). 추천 브랜치 하위(탭바 유지).
  /// 실제 GoRoute path 는 '/recommend/detail'. extra 로 [RecommendedBook] 를 넘긴다.
  static const String recommendDetail = '/recommend/detail';

  /// 추천 기준 (RC-002). 셸 바깥 최상위(탭바 숨김, 풀스크린). extra 없음.
  static const String recommendCriteria = '/recommend-criteria';

  /// 트렌드 탭 (TR).
  static const String trend = '/trend';

  // --- 마이페이지 (MY) ---

  /// 마이페이지 허브 (MY-001). 홈 브랜치 하위(탭바 유지).
  static const String mypage = '/mypage';

  /// 로그아웃 확인 (MY-007). 홈 브랜치 하위(탭바 유지). 풀스크린 톤.
  static const String logoutConfirm = '/logout-confirm';

  /// 계정 관리 (MY-003). 홈 브랜치 하위(탭바 유지).
  static const String account = '/account';

  /// 회원 탈퇴 (MY-008). 홈 브랜치 하위(탭바 유지).
  static const String withdrawal = '/withdrawal';

  // --- 책 관리 (BK) ---

  /// 책 선택 화면 (BK-001). 홈 브랜치 하위(탭바 유지).
  static const String bookSelect = '/book-select';

  /// 책장 전체보기 화면 (BK-002). 홈 브랜치 하위(탭바 유지).
  static const String bookshelf = '/bookshelf';

  /// 책 상세 화면 (BK-004). 실제 GoRoute path 는 '/book-detail/:bookId'.
  static const String bookDetail = '/book-detail';

  /// 특정 책 상세 경로를 만든다.
  static String bookDetailOf(String bookId) => '$bookDetail/$bookId';

  /// 책장 편집 화면 (BK). 홈 브랜치 하위(탭바 유지). extra 없음.
  static const String bookshelfEdit = '/bookshelf-edit';

  // --- 문장 수집 (CP) ---

  /// 문장 추가 방법 선택 (CP-001). 홈 브랜치 하위(탭바 유지).
  /// extra 로 [CaptureBookArgs] 를 넘긴다.
  static const String captureMethod = '/capture-method';

  /// 카메라 OCR (CP-002/003). 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [CaptureBookArgs] 를 넘긴다.
  static const String cameraOcr = '/camera-ocr';

  /// 갤러리 OCR (CP-002/003). 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [CaptureBookArgs] 를 넘긴다.
  static const String galleryOcr = '/gallery-ocr';

  /// 문장 확인/저장 (CP-005). 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [CaptureConfirmArgs] 를 넘긴다.
  static const String captureConfirm = '/capture-confirm';

  /// 구절 편집 (CP-006). 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [Capture] 객체를 넘긴다.
  static const String captureEdit = '/capture-edit';

  /// 구절 코멘트 추가. 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [Capture] 객체를 넘긴다.
  static const String captureCommentAdd = '/capture-comment-add';

  /// 구절 코멘트 수정. 셸 바깥 최상위(탭바 숨김).
  /// extra 로 [CaptureCommentEditArgs] 를 넘긴다.
  static const String captureCommentEdit = '/capture-comment-edit';

  // --- 트렌드 (TR) ---

  /// 공개 구절 상세. 트렌드 브랜치 하위(탭바 유지).
  /// 실제 GoRoute path 는 '/trend/public-capture-detail'.
  /// extra 로 [PublicCapture] 객체를 넘긴다.
  static const String publicCaptureDetail = '/trend/public-capture-detail';

  /// 공개 구절 댓글 작성. 셸 바깥 최상위(탭바 숨김).
  /// 실제 GoRoute path 는 '/public-capture-comment-write/:captureId'.
  static const String publicCaptureCommentWrite =
      '/public-capture-comment-write';

  /// 특정 공개 구절의 댓글 작성 경로를 만든다.
  static String publicCaptureCommentWriteOf(String captureId) =>
      '$publicCaptureCommentWrite/$captureId';
}
