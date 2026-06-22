import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/keyword_icons.dart';
import '../data/models/recommendation_cache.dart';
import '../domain/drift_status.dart';
import '../domain/recommendation_providers.dart';

/// 추천(RC-001) 메인 화면.
///
/// 본문은 [driftStatusProvider] 의 4상태로 분기한다.
/// - belowThreshold : 콜드스타트(책/구절 부족). LLM 호출 없음, 문장 추가 유도.
/// - noCache        : 조건 충족 + 캐시 없음. "추천 받기" 로 첫 생성.
/// - fresh          : 캐시 최신. 결과 표시 + 수동 재생성.
/// - stale          : 캐시 있으나 구절 변동. 결과 + 상단 갱신 배너.
///
/// 생성 진행/에러는 [recommendationGeneratorProvider] 의 AsyncValue 를 우선
/// 표시한다(수동 플래그 없음). 진입만으로는 generate 가 호출되지 않으며, 생성은
/// 버튼/배너 탭에서만 시작한다. 결과 데이터는 [recommendationCacheProvider].
class RecommendScreen extends ConsumerWidget {
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generationState = ref.watch(recommendationGeneratorProvider);
    final driftState = ref.watch(driftStatusProvider);

    // 생성 트리거. 진입이 아닌 버튼/배너에서만 호출된다.
    void generate() {
      ref.read(recommendationGeneratorProvider.notifier).generate();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('추천'),
        actions: [
          IconButton(
            tooltip: '추천 기준',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => context.push(AppRoutes.recommendCriteria),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            const _RecommendHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildContent(generationState, driftState, generate),
          ],
        ),
      ),
    );
  }

  /// 생성 상태(우선) → DriftStatus 순으로 본문을 그린다.
  Widget _buildContent(
    AsyncValue<void> generationState,
    AsyncValue<DriftStatus> driftState,
    VoidCallback onGenerate,
  ) {
    // 1) 생성 진행 중 → 로딩(다른 상태보다 우선).
    if (generationState.isLoading) {
      return const _RecommendLoadingView();
    }

    // 2) 생성 실패 → 에러 + 다시 시도.
    if (generationState.hasError) {
      return _RecommendErrorView(
        message: generationState.error.toString(),
        onRetry: onGenerate,
      );
    }

    // 3) DriftStatus 4상태 분기.
    return driftState.when(
      loading: () => const _DriftLoadingView(),
      error: (error, _) => _RecommendErrorView(message: error.toString()),
      data: (status) {
        switch (status) {
          case DriftStatus.belowThreshold:
            return const _ColdStartView();
          case DriftStatus.noCache:
            return _NoCacheView(onGenerate: onGenerate);
          case DriftStatus.fresh:
            return _ResultView(isStale: false, onGenerate: onGenerate);
          case DriftStatus.stale:
            return _ResultView(isStale: true, onGenerate: onGenerate);
        }
      },
    );
  }
}

// =============================================================================
// 공통 헤더
// =============================================================================

class _RecommendHeader extends StatelessWidget {
  const _RecommendHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 문장 기반 책 추천',
                  style: AppTextStyles.title,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '저장한 구절과 감상 기록을 바탕으로 나에게 어울리는 책을 추천받을 수 있어요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 1) belowThreshold — 콜드스타트
// =============================================================================

class _ColdStartView extends StatelessWidget {
  const _ColdStartView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '아직 추천을 받을 만큼 문장이 모이지 않았어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '구절을 3개 이상 모으면 맞춤 추천이 시작됩니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.bookSelect),
              icon: const Icon(Icons.add_rounded),
              label: const Text('문장 추가하러 가기'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 2) noCache — 조건 충족 + 캐시 없음
// =============================================================================

class _NoCacheView extends StatelessWidget {
  const _NoCacheView({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '맞춤 추천을 받아보세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '저장한 구절을 분석해 취향에 맞는 책을 찾아드릴게요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('추천 받기'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 3·4) fresh / stale — 결과 렌더(공통). stale 이면 상단 갱신 배너.
// =============================================================================

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.isStale,
    required this.onGenerate,
  });

  /// 캐시 생성 이후 구절 수가 변동됐는지(갱신 배너 노출 여부).
  final bool isStale;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheState = ref.watch(recommendationCacheProvider);

    return cacheState.when(
      loading: () => const _DriftLoadingView(),
      error: (error, _) => _RecommendErrorView(message: error.toString()),
      data: (cache) {
        // fresh/stale 는 캐시 존재를 전제하지만, 경쟁 상태 방어로 null 처리.
        if (cache == null) {
          return _NoCacheView(onGenerate: onGenerate);
        }

        final pick = cache.todaysPick;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStale) ...[
              _RefreshBanner(onRefresh: onGenerate),
              const SizedBox(height: AppSpacing.xl),
            ],
            _AnalysisSummaryCard(
              summary: cache.summary,
              keywords: cache.keywords,
            ),
            if (pick != null) ...[
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('오늘의 추천'),
              const SizedBox(height: AppSpacing.md),
              _RecommendedBookCard(
                book: _toCardBook(pick),
                onTap: () =>
                    context.push(AppRoutes.recommendDetail, extra: pick),
              ),
            ],
            if (cache.alsoRecommended.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('함께 보면 좋은 책'),
              const SizedBox(height: AppSpacing.md),
              ...cache.alsoRecommended.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _RecommendedBookCard(
                    book: _toCardBook(book),
                    onTap: () =>
                        context.push(AppRoutes.recommendDetail, extra: book),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('추천 다시 생성하기'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 갱신 배너(stale). surfaceVariant 톤으로 눈에 띄되 과하지 않게.
class _RefreshBanner extends StatelessWidget {
  const _RefreshBanner({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.autorenew_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              '새로 저장한 문장이 있어요. 추천을 갱신해보세요.',
              style: AppTextStyles.bodyStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: onRefresh,
            child: const Text('갱신하기'),
          ),
        ],
      ),
    );
  }
}

/// 분석 요약 카드 — 통합 때 제거된 요약 카드를 1차 분석 결과로 대체한다.
///
/// summary(한 줄 요약)와 keywords(label+icon)를 칩으로 보여준다. 아이콘은
/// [keywordIconData] 로 매핑한다.
class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({
    required this.summary,
    required this.keywords,
  });

  final String summary;
  final List<RecommendationKeyword> keywords;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '당신의 독서 취향',
            style: AppTextStyles.bodyStrong,
          ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: AppTextStyles.body,
            ),
          ],
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: keywords
                  .map((keyword) => _KeywordChip(keyword: keyword))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 키워드 칩(아이콘 + 라벨). 알약형 surfaceVariant 배경.
class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.keyword});

  final RecommendationKeyword keyword;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            keywordIconData(keyword.icon),
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            keyword.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.title,
    );
  }
}

// =============================================================================
// 로딩 / 에러 (팀원 위젯 재사용 + 보강)
// =============================================================================

/// generate 진행 중 로딩 뷰.
class _RecommendLoadingView extends StatelessWidget {
  const _RecommendLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text(
            '추천을 분석하고 있어요',
            style: AppTextStyles.bodyStrong,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 문장을 분석하고 카카오 책 검색으로 도서 정보를 확인하고 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// driftStatus 로딩용 간단 인디케이터.
class _DriftLoadingView extends StatelessWidget {
  const _DriftLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecommendErrorView extends StatelessWidget {
  const _RecommendErrorView({
    required this.message,
    this.onRetry,
  });

  final String message;

  /// 있으면 "다시 시도" 버튼을 노출한다(생성 에러용).
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '추천을 생성하지 못했어요',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('다시 시도'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 추천 책 카드 (팀원 위젯 재사용)
// =============================================================================

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.book,
    this.onTap,
  });

  final _RecommendedBook book;

  /// 카드 탭 시 RC-003 추천 상세로 이동.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (book.publisher.trim().isNotEmpty) book.publisher,
      '카카오 책 검색 확인',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecommendBookCover(url: book.thumbnail),
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meta,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      book.keyword,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    book.reason,
                    style: AppTextStyles.caption.copyWith(height: 1.4),
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

class _RecommendBookCover extends StatelessWidget {
  const _RecommendBookCover({
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const _EmptyBookCover();
    }

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: Image.network(
        url,
        width: 58,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _EmptyBookCover();
        },
      ),
    );
  }
}

class _EmptyBookCover extends StatelessWidget {
  const _EmptyBookCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 82,
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary,
      ),
    );
  }
}

// =============================================================================
// 화면 카드 표시 전용 뷰 모델 + 어댑터
// =============================================================================

/// 추천 엔진의 [RecommendedBook] 을 화면 카드용 [_RecommendedBook] 으로 변환한다.
///
/// 표지는 엔진이 카카오 후보에서 채운 coverUrl 을 그대로 쓴다(화면 추가 보정 없음).
/// 칩 키워드는 연관 키워드 우선, 없으면 테마 매칭을 쓴다.
_RecommendedBook _toCardBook(RecommendedBook book) {
  final keyword = book.relatedKeywords.isNotEmpty
      ? book.relatedKeywords.first
      : (book.themeMatch.trim().isEmpty ? '개인화 추천' : book.themeMatch);

  return _RecommendedBook(
    title: book.title,
    author: book.author,
    publisher: '',
    thumbnail: book.coverUrl,
    keyword: keyword,
    reason: book.reason,
  );
}

/// 화면 카드 표시 전용 추천 도서 뷰 모델.
class _RecommendedBook {
  const _RecommendedBook({
    required this.title,
    required this.author,
    required this.publisher,
    required this.thumbnail,
    required this.reason,
    required this.keyword,
  });

  final String title;
  final String author;
  final String publisher;
  final String thumbnail;
  final String reason;
  final String keyword;
}
