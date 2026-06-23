import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/presentation/widgets/book_cover.dart';
import '../data/models/bestseller_book.dart';
import '../domain/bestseller_providers.dart';
import 'widgets/aladin_source_note.dart';

/// 기간별 베스트셀러 (TR-002).
///
/// MVP 범위: 알라딘 QueryType=Bestseller 가 주간 기준이라 "이번 주"만 동작하고
/// "한 달"/"1년" 은 비활성(탭 시 "준비 중입니다")으로 둔다. 기간 토글 상태만
/// 들고 있으면 되어 상태는 단순하다. 트렌드 브랜치 하위 중첩이라 탭바가 유지된다.
class BestsellerPeriodScreen extends ConsumerStatefulWidget {
  const BestsellerPeriodScreen({super.key});

  @override
  ConsumerState<BestsellerPeriodScreen> createState() =>
      _BestsellerPeriodScreenState();
}

/// 베스트셀러 기간 구분.
enum _BestsellerPeriod { week, month, year }

class _BestsellerPeriodScreenState
    extends ConsumerState<BestsellerPeriodScreen> {
  /// 현재 선택 기간. MVP 에서는 항상 [_BestsellerPeriod.week].
  _BestsellerPeriod _period = _BestsellerPeriod.week;

  /// TR-002 는 더 많은 권수를 보여준다.
  static const int _maxResults = 20;

  void _onSelectPeriod(_BestsellerPeriod period) {
    // 이번 주 외 기간은 아직 지원하지 않는다.
    if (period != _BestsellerPeriod.week) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('준비 중입니다')));
      return;
    }
    if (_period == period) return;
    setState(() => _period = period);
  }

  @override
  Widget build(BuildContext context) {
    final bestsellersAsync =
        ref.watch(bestsellersProvider(maxResults: _maxResults));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('트렌드'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            const Text(
              '많은 독자가 관심을 보인 책을 기간별로 확인해보세요.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PeriodToggle(selected: _period, onSelect: _onSelectPeriod),
            const SizedBox(height: AppSpacing.md),
            const Text('최근 7일 기준', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.md),
            bestsellersAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return const _PeriodMessageBox(message: '아직 베스트셀러가 없어요');
                }
                return Column(
                  children: [
                    for (final book in books)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _PeriodBookCard(
                          book: book,
                          // 책 카드 탭 → TR-003 트렌드 상세(BestsellerBook 전달).
                          onTap: () => context.push(
                            AppRoutes.trendDetail,
                            extra: book,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const _PeriodLoadingBox(),
              error: (error, _) => _PeriodMessageBox(
                message: '베스트셀러를 불러오지 못했어요',
                onRetry: () =>
                    ref.invalidate(bestsellersProvider(maxResults: _maxResults)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AladinSourceNote(),
          ],
        ),
      ),
    );
  }
}

/// 기간 토글(세그먼트). 이번 주만 활성, 한 달/1년은 비활성 톤.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.selected, required this.onSelect});

  final _BestsellerPeriod selected;
  final ValueChanged<_BestsellerPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        children: [
          _PeriodSegment(
            label: '이번 주',
            selected: selected == _BestsellerPeriod.week,
            enabled: true,
            onTap: () => onSelect(_BestsellerPeriod.week),
          ),
          _PeriodSegment(
            label: '한 달',
            selected: false,
            enabled: false,
            onTap: () => onSelect(_BestsellerPeriod.month),
          ),
          _PeriodSegment(
            label: '1년',
            selected: false,
            enabled: false,
            onTap: () => onSelect(_BestsellerPeriod.year),
          ),
        ],
      ),
    );
  }
}

/// 기간 토글의 한 칸.
class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (selected) {
      textColor = AppColors.onPrimary;
    } else if (enabled) {
      textColor = AppColors.textPrimary;
    } else {
      // 비활성 기간은 흐린 색으로 구분한다.
      textColor = AppColors.disabledText;
    }

    return Expanded(
      child: InkWell(
        borderRadius: AppRadius.fullRadius,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.fullRadius,
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// 기간별 베스트셀러 한 권 카드: 순위 + 표지 + 제목/저자 + 우측 화살표.
class _PeriodBookCard extends StatelessWidget {
  const _PeriodBookCard({required this.book, required this.onTap});

  final BestsellerBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${book.rank}',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.title.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              BookCover(url: book.coverUrl, width: 48, height: 66, iconSize: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppTextStyles.bodyStrong,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        book.author,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기간별 베스트셀러 로딩 박스(높이 고정).
class _PeriodLoadingBox extends StatelessWidget {
  const _PeriodLoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// 기간별 베스트셀러 빈/에러 안내 박스.
class _PeriodMessageBox extends StatelessWidget {
  const _PeriodMessageBox({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 32,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.caption),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}
