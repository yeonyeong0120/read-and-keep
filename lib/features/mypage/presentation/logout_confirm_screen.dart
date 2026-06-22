import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_providers.dart';

/// 로그아웃 확인 화면 (MY-007).
///
/// MY-001 "로그아웃" 진입점. "로그아웃" 탭 시 [AuthNotifier.signOut] 을 호출한다.
/// signOut 후 currentAppUser 가 null 이 되면 router 의 redirect 가 자동으로
/// /login 으로 보내므로 별도 수동 네비게이션은 하지 않는다.
class LogoutConfirmScreen extends ConsumerWidget {
  const LogoutConfirmScreen({super.key});

  Future<void> _onLogout(WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    // 로그아웃 성공 → currentAppUserProvider null → redirect 가 /login 처리.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoggingOut = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('로그아웃'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.xxl,
                  bottom: AppSpacing.xl,
                ),
                children: [
                  // 중앙 아이콘: 원형 베이지 배경의 문+화살표.
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    '로그아웃 하시겠어요?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '로그아웃 시 현재 계정의 모든 정보는 이 기기에서\n안전하게 로그아웃됩니다.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _InfoCard(
                    icon: Icons.person_outline_rounded,
                    title: '계정 정보 보호',
                    description: '개인 정보는 안전하게 보호됩니다.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _InfoCard(
                    icon: Icons.menu_book_outlined,
                    title: '저장된 데이터 유지',
                    description: '데이터는 서버에 안전하게 저장되어 다시 로그인 시 복구할 수 있습니다.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _InfoCard(
                    icon: Icons.smartphone_outlined,
                    title: '다시 로그인 가능',
                    description: '언제든지 로그인하여 서비스를 이용하실 수 있습니다.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding.copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // 주 액션: 로그아웃. 진행 중에는 비활성 + 인디케이터.
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoggingOut ? null : () => _onLogout(ref),
                      child: isLoggingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('로그아웃'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 보조 액션: 취소 → MY-001 복귀.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoggingOut ? null : () => context.pop(),
                      child: const Text('취소'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로그아웃 안내 카드(아이콘 + 제목 + 설명).
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
