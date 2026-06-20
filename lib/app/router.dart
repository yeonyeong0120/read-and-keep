import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/data/models/app_user.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_reset_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/books/presentation/book_detail_screen.dart';
import '../features/books/presentation/book_select_screen.dart';
import '../features/books/presentation/bookshelf_edit_screen.dart';
import '../features/books/presentation/bookshelf_overview_screen.dart';
import '../features/captures/data/models/capture.dart';
import '../features/captures/presentation/camera_ocr_screen.dart';
import '../features/captures/presentation/capture_comment_add_screen.dart';
import '../features/captures/presentation/capture_comment_edit_screen.dart';
import '../features/captures/presentation/capture_confirm_screen.dart';
import '../features/captures/presentation/capture_edit_screen.dart';
import '../features/captures/presentation/capture_method_screen.dart';
import '../features/captures/presentation/gallery_ocr_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/recommendation/presentation/recommend_screen.dart';
import '../features/trend/data/models/public_capture.dart';
import '../features/trend/presentation/public_capture_detail_screen.dart';
import '../features/trend/presentation/trend_screen.dart';
import 'routes.dart';
import 'widgets/main_shell.dart';

part 'router.g.dart';

/// 앱 전역 라우터.
///
/// 인증 상태([currentAppUserProvider])에 따라 인증/비인증 경로를 자동 분기한다.
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // currentAppUserProvider 변화를 GoRouter 의 refreshListenable 로 연결한다.
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    // 앱 시작 시에는 스플래시에서 인증 상태가 확정될 때까지 대기한다.
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final userAsync = ref.read(currentAppUserProvider);

      // 사용자 상태 로딩 중에는 현재 위치를 유지한다.
      // 앱 시작 시 위치는 splash 이므로, 확정 전까지 splash 에 머문다.
      // 이로써 로그인 화면이 잠깐 떴다 사라지는 깜빡임이 사라진다.
      if (userAsync.isLoading) return null;

      // Riverpod 3.x 안전 접근: whenOrNull(data:) 로 값을 꺼낸다.
      final isLoggedIn = userAsync.whenOrNull(data: (user) => user) != null;

      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.passwordReset;

      // 로딩이 끝나 인증이 확정되면 스플래시에서 반드시 분기한다.
      // (로그인 상태면 홈, 미로그인이면 로그인 — splash 에 머물지 않게)
      if (isSplash) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }

      // 미로그인 + 비인증 경로 → 로그인.
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      // 로그인 + 인증 경로 → 홈.
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // 스플래시: 인증 화면군과 함께 셸 바깥 최상위에 둔다.
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // 인증 화면은 탭바 비노출이므로 셸 바깥 최상위에 둔다.
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      // 메인 탭 셸: 홈/추천/트렌드 3개 브랜치를 IndexedStack 으로 유지한다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                // 책 선택/상세는 홈 브랜치 하위에 두어 탭바를 유지한다.
                // 중첩 라우트 path 는 슬래시 없는 상대경로로 둔다.
                routes: [
                  GoRoute(
                    path: 'book-select',
                    builder: (context, state) => const BookSelectScreen(),
                  ),
                  GoRoute(
                    path: 'bookshelf',
                    builder: (context, state) =>
                        const BookshelfOverviewScreen(),
                  ),
                  GoRoute(
                    path: 'bookshelf-edit',
                    builder: (context, state) => const BookshelfEditScreen(),
                  ),
                  GoRoute(
                    path: 'book-detail/:bookId',
                    builder: (context, state) => BookDetailScreen(
                      bookId: state.pathParameters['bookId']!,
                    ),
                  ),
                  // CP-001 문장 추가 방법 선택. 책 정보는 extra 로 받는다.
                  GoRoute(
                    path: 'capture-method',
                    builder: (context, state) {
                      final args = state.extra! as CaptureBookArgs;

                      return CaptureMethodScreen(
                        bookId: args.bookId,
                        bookTitle: args.bookTitle,
                        bookAuthor: args.bookAuthor,
                        bookPublisher: args.bookPublisher,
                        bookCoverUrl: args.bookCoverUrl,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recommend,
                builder: (context, state) => const RecommendScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trend,
                builder: (context, state) => const TrendScreen(),
                // 공개 구절 상세는 트렌드 브랜치 하위에 두어 탭바를 유지한다.
                routes: [
                  GoRoute(
                    path: 'public-capture-detail',
                    builder: (context, state) {
                      final capture = state.extra! as PublicCapture;

                      return PublicCaptureDetailScreen(capture: capture);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // --- 셸 바깥 최상위(탭바 숨김): 문장 수집 풀스크린 / 댓글 작성 ---
      GoRoute(
        path: AppRoutes.cameraOcr,
        builder: (context, state) {
          final args = state.extra! as CaptureBookArgs;

          return CameraOcrScreen(
            bookId: args.bookId,
            bookTitle: args.bookTitle,
            bookAuthor: args.bookAuthor,
            bookPublisher: args.bookPublisher,
            bookCoverUrl: args.bookCoverUrl,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryOcr,
        builder: (context, state) {
          final args = state.extra! as CaptureBookArgs;

          return GalleryOcrScreen(
            bookId: args.bookId,
            bookTitle: args.bookTitle,
            bookAuthor: args.bookAuthor,
            bookPublisher: args.bookPublisher,
            bookCoverUrl: args.bookCoverUrl,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.captureConfirm,
        builder: (context, state) {
          final args = state.extra! as CaptureConfirmArgs;

          return CaptureConfirmScreen(
            bookId: args.bookId,
            bookTitle: args.bookTitle,
            bookAuthor: args.bookAuthor,
            bookPublisher: args.bookPublisher,
            bookCoverUrl: args.bookCoverUrl,
            initialQuote: args.initialQuote,
            initialPageNumber: args.initialPageNumber,
            initialComment: args.initialComment,
            source: args.source,
            ocrRawText: args.ocrRawText,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.captureEdit,
        builder: (context, state) {
          final capture = state.extra! as Capture;

          return CaptureEditScreen(capture: capture);
        },
      ),
      GoRoute(
        path: AppRoutes.captureCommentAdd,
        builder: (context, state) {
          final capture = state.extra! as Capture;

          return CaptureCommentAddScreen(capture: capture);
        },
      ),
      GoRoute(
        path: AppRoutes.captureCommentEdit,
        builder: (context, state) {
          final args = state.extra! as CaptureCommentEditArgs;

          return CaptureCommentEditScreen(
            capture: args.capture,
            comment: args.comment,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.publicCaptureCommentWrite}/:captureId',
        builder: (context, state) => PublicCaptureCommentWriteScreen(
          captureId: state.pathParameters['captureId']!,
        ),
      ),
    ],
  );
}

/// [currentAppUserProvider] 의 변화를 [Listenable] 로 변환하는 어댑터.
///
/// 로그인/로그아웃 등으로 사용자 상태가 바뀔 때만 redirect 를 재평가하도록,
/// authProvider 가 아니라 currentAppUserProvider 를 기준으로 삼는다.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen(
      currentAppUserProvider,
      (previous, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AppUser?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
