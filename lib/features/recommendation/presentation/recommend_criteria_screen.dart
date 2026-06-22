import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// 추천 기준(RC-002) 화면.
///
/// 추천이 어떻게 만들어지는지 안내하는 정적 화면이다. 데이터 의존성이 없어
/// [StatelessWidget] 으로 둔다. 풀스크린(셸 바깥 최상위)으로 등록되어 탭바는
/// 노출되지 않는다. "확인" 으로 RC-001 에 복귀한다.
class RecommendCriteriaScreen extends StatelessWidget {
  const RecommendCriteriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('추천 기준'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                ),
                children: const [
                  Text(
                    '추천이 어떻게 만들어졌는지 간단히 알려드려요.',
                    style: AppTextStyles.caption,
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _CriteriaCard(
                    icon: Icons.calendar_today_outlined,
                    title: '분석 기간',
                    highlight: '최근 30일',
                    description: '최근 30일 동안 저장한 구절과 책 기록을 우선 반영해요.',
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _CriteriaCard(
                    icon: Icons.menu_book_outlined,
                    title: '반영되는 기록',
                    chips: ['저장한 구절', '저장한 책', '최근 기록'],
                    description: '문장의 내용, 책 정보, 최근에 저장한 기록을 함께 살펴봐요.',
                  ),
                  SizedBox(height: AppSpacing.lg),
                  _CriteriaCard(
                    icon: Icons.youtube_searched_for_rounded,
                    title: '추천 방식',
                    highlight: '취향이 비슷한 책 추천',
                    description: '저장한 문장에서 자주 보이는 분위기와 키워드를 바탕으로 책을 추천해요.',
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _CriteriaNoticeBox(),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding.copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기준 안내 카드. [highlight](강조 한 줄) 또는 [chips](라벨 칩) 중 하나를 쓴다.
class _CriteriaCard extends StatelessWidget {
  const _CriteriaCard({
    required this.icon,
    required this.title,
    required this.description,
    this.highlight,
    this.chips,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? highlight;
  final List<String>? chips;

  @override
  Widget build(BuildContext context) {
    final chipList = chips;

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
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                if (highlight != null)
                  Text(highlight!, style: AppTextStyles.title),
                if (chipList != null)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: chipList
                        .map((label) => _CriteriaChip(label: label))
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(description, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  const _CriteriaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 하단 안내 박스(surfaceVariant 톤).
class _CriteriaNoticeBox extends StatelessWidget {
  const _CriteriaNoticeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '추천은 저장한 기록이 늘어날수록 더 정확해져요.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}
