import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/data/models/app_user.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_reset_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/books/presentation/book_detail_screen.dart';
import '../features/books/presentation/book_select_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/recommendation/presentation/recommend_screen.dart';
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
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final userAsync = ref.read(currentAppUserProvider);

      // 사용자 상태 로딩 중에는 현재 위치를 유지한다.
      if (userAsync.isLoading) return null;

      // Riverpod 3.x 안전 접근: whenOrNull(data:) 로 값을 꺼낸다.
      final isLoggedIn = userAsync.whenOrNull(data: (user) => user) != null;

      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.passwordReset;

      // 미로그인 + 비인증 경로 → 로그인.
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      // 로그인 + 인증 경로 → 홈.
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
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
                    path: 'book-detail/:bookId',
                    builder: (context, state) => BookDetailScreen(
                      bookId: state.pathParameters['bookId']!,
                    ),
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
              ),
            ],
          ),
        ],
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
