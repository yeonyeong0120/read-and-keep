import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../features/auth/data/models/app_user.dart';
import '../features/auth/domain/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_reset_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import 'routes.dart';

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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomePlaceholder(),
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

/// 홈 화면 임시 자리표시. STEP 6 에서 실제 홈으로 대체한다.
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('홈은 STEP 6에서 구현', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
