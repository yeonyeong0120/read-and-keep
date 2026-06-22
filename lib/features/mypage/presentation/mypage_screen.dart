import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_providers.dart';
import '../../books/domain/book_providers.dart';
import '../domain/mypage_providers.dart';

/// 마이페이지 허브 (MY-001).
///
/// 프로필/통계, 공개 기본 설정 토글(실제 동작), 미구현 메뉴(준비 중),
/// 로그아웃 진입(MY-007)을 모은 설정 허브다. 통계와 프로필은 watch 한다.
class MypageScreen extends ConsumerWidget {
  const MypageScreen({super.key});

  /// 아직 만들지 않은 메뉴 공통 처리: "준비 중" 스낵바.
  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('준비 중입니다')),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);
    final booksAsync = ref.watch(booksProvider());
    final publicCountAsync = ref.watch(publicCaptureCountProvider);
    final authState = ref.watch(authProvider);

    final nickname = userAsync.when(
      data: (user) {
        final name = user?.nickname ?? '';
        return name.isEmpty ? '독자' : name;
      },
      loading: () => '…',
      error: (_, _) => '독자',
    );

    // 저장한 책 = booksProvider 길이.
    final bookCountText = booksAsync.when(
      data: (books) => '${books.length}권',
      loading: () => '…',
      error: (_, _) => '0권',
    );
    // 저장한 구절 = 각 책 savedQuoteCount 합산(단일 진실 필드).
    final quoteCountText = booksAsync.when(
      data: (books) =>
          '${books.fold<int>(0, (sum, book) => sum + book.savedQuoteCount)}개',
      loading: () => '…',
      error: (_, _) => '0개',
    );
    // 공개한 구절 = publicCaptures count() 집계.
    final publicCountText = publicCountAsync.when(
      data: (count) => '$count개',
      loading: () => '…',
      error: (_, _) => '0개',
    );

    // 공개 기본 설정 값. profile/필드가 없으면 false(Privacy by Default).
    final publishDefault =
        userAsync.whenOrNull(data: (user) => user?.publishDefault) ?? false;
    // 토글 쓰기 진행 중에는 토글을 비활성화한다.
    final isUpdating = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('마이페이지 / 설정'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileCard(
                nickname: nickname,
                bookCountText: bookCountText,
                quoteCountText: quoteCountText,
                publicCountText: publicCountText,
              ),

              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('설정'),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                children: [
                  _PublishDefaultRow(
                    value: publishDefault,
                    enabled: !isUpdating,
                    onChanged: (next) => ref
                        .read(authProvider.notifier)
                        .setPublishDefault(next),
                  ),
                  _MenuRow(
                    icon: Icons.notifications_none_rounded,
                    title: '알림 설정',
                    onTap: () => _showComingSoon(context),
                  ),
                  _MenuRow(
                    icon: Icons.manage_accounts_outlined,
                    title: '계정 관리',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('기타'),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                children: [
                  _MenuRow(
                    icon: Icons.campaign_outlined,
                    title: '공지사항',
                    onTap: () => _showComingSoon(context),
                  ),
                  _MenuRow(
                    icon: Icons.help_outline_rounded,
                    title: '문의하기',
                    onTap: () => _showComingSoon(context),
                  ),
                  _MenuRow(
                    icon: Icons.logout_rounded,
                    title: '로그아웃',
                    onTap: () => context.push(AppRoutes.logoutConfirm),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              // 회원 탈퇴는 파괴적 액션이라 별도 카드 + destructive 색으로 강조한다.
              // 동작은 이번 범위 외(MY-008)이므로 탭 시 "준비 중".
              _SettingsCard(
                children: [
                  _MenuRow(
                    icon: Icons.person_remove_outlined,
                    title: '회원 탈퇴',
                    destructive: true,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프로필 + 통계 카드.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.bookCountText,
    required this.quoteCountText,
    required this.publicCountText,
  });

  final String nickname;
  final String bookCountText;
  final String quoteCountText;
  final String publicCountText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // 기본 프로필 아이콘(이미지 업로드는 범위 외).
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: AppTextStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '오늘도 좋은 문장을 기록해보세요.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatItem(label: '저장한 책', value: bookCountText),
              ),
              Expanded(
                child: _StatItem(label: '저장한 구절', value: quoteCountText),
              ),
              Expanded(
                child: _StatItem(label: '공개한 구절', value: publicCountText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 통계 1종(라벨 + 값).
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

/// 섹션 라벨(설정/기타).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.title);
  }
}

/// 메뉴 카드 그룹. 자식 행 사이에 구분선을 넣는다.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
        );
      }
      rows.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: Column(children: rows),
      ),
    );
  }
}

/// 일반 메뉴 행(아이콘 + 제목 + 우측 ">"). [destructive] 면 빨간 톤.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.destructive : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: destructive ? AppColors.destructive : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// 공개 기본 설정 토글 행. 우측 인라인 토글 + 현재 모드 라벨.
class _PublishDefaultRow extends StatelessWidget {
  const _PublishDefaultRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // value=false → 비공개 우선(Privacy by Default).
    final modeLabel = value ? '공개' : '비공개 우선';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.public_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text('다른 독자에게 공개 기본 설정', style: AppTextStyles.body),
          ),
          Text(modeLabel, style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            thumbColor: const WidgetStatePropertyAll(AppColors.onPrimary),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.disabledBackground,
            ),
            trackOutlineColor:
                const WidgetStatePropertyAll(AppColors.outline),
          ),
        ],
      ),
    );
  }
}
