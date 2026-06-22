import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/recommendation_cache.dart';
import '../domain/recommendation_providers.dart';

/// 추천(RC) 화면.
///
/// 화면 레이아웃/카드는 기존 그대로 두고, 추천 데이터 소스만 교체했다.
/// - 생성 트리거: [recommendationGeneratorProvider] 의 generate()
///   (1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
/// - 결과 표시: [recommendationCacheProvider](RecommendationCache?) 를 구독해
///   화면 카드용 [_RecommendedBook] 으로 변환(어댑터)해서 그린다.
/// 로딩/에러는 Provider 의 AsyncValue 로만 다루고(수동 플래그 없음), 표시 문구
/// 구분용 화면 상태만 [_generatedThisSession] 으로 둔다.
class RecommendScreen extends ConsumerStatefulWidget {
  const RecommendScreen({super.key});

  @override
  ConsumerState<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends ConsumerState<RecommendScreen> {
  /// 이번 세션에서 생성 버튼을 직접 눌렀는지(결과 문구의 "이전/새로" 구분용).
  /// 비동기 로딩/에러 상태와 무관한 표시 전용 화면 상태다.
  bool _generatedThisSession = false;

  Future<void> _generate() async {
    await ref.read(recommendationGeneratorProvider.notifier).generate();
    if (!mounted) return;
    setState(() => _generatedThisSession = true);
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(recommendationGeneratorProvider);
    final cacheState = ref.watch(recommendationCacheProvider);

    final isLoading = generationState.isLoading;
    final cache = cacheState.asData?.value;
    final hasResult = cache != null &&
        (cache.todaysPick != null || cache.alsoRecommended.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('추천'),
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
            _RecommendActionCard(
              isLoading: isLoading,
              captureCount: cache?.snapshotCaptureCount ?? 0,
              isCachedResult: hasResult && !_generatedThisSession,
              usedGeminiResult: !AiConfig.useMockRecommendation,
              onGenerate: _generate,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildBody(
              generationState: generationState,
              cacheState: cacheState,
            ),
          ],
        ),
      ),
    );
  }

  /// 생성 상태(우선) → 캐시 상태 순으로 본문을 그린다.
  ///
  /// 생성 중/실패는 generator 의 AsyncValue 로, 결과 유무는 cache 의 AsyncValue
  /// 로 판정한다. cache 가 null 이면 아직 생성 전, 결과가 비면 부족 안내를 띄운다.
  Widget _buildBody({
    required AsyncValue<void> generationState,
    required AsyncValue<RecommendationCache?> cacheState,
  }) {
    // 1) 생성 중 → 로딩.
    if (generationState.isLoading) {
      return const _RecommendLoadingView();
    }

    // 2) 생성 실패 → 에러.
    if (generationState.hasError) {
      return _RecommendErrorView(
        message: generationState.error.toString(),
      );
    }

    // 3) 캐시 스트림 상태로 결과를 그린다.
    return cacheState.when(
      loading: () => const _RecommendLoadingView(),
      error: (error, _) => _RecommendErrorView(message: error.toString()),
      data: (cache) {
        if (cache == null) {
          return const _RecommendReadyView();
        }

        final books = _adaptCacheToBooks(cache);
        if (books.isEmpty) {
          return _RecommendInsufficientView(
            captureCount: cache.snapshotCaptureCount,
          );
        }

        return _RecommendResultList(
          books: books,
          isCachedResult: !_generatedThisSession,
          usedGeminiResult: !AiConfig.useMockRecommendation,
        );
      },
    );
  }

  /// 추천 캐시(todaysPick + alsoRecommended)를 화면 카드용 목록으로 변환한다.
  /// 오늘의 추천을 맨 앞(대표 추천)에 두고, 함께 추천을 뒤에 잇는다.
  List<_RecommendedBook> _adaptCacheToBooks(RecommendationCache cache) {
    final books = <_RecommendedBook>[];

    final pick = cache.todaysPick;
    if (pick != null) {
      books.add(_fromRecommendedBook(pick));
    }
    for (final book in cache.alsoRecommended) {
      books.add(_fromRecommendedBook(book));
    }

    return books;
  }

  /// 내 [RecommendedBook] → 화면 [_RecommendedBook] 매핑.
  ///
  /// 표지는 엔진이 카카오 후보에서 채운 coverUrl 을 그대로 쓴다(화면의 추가
  /// 카카오 보정 없음). 칩 키워드는 연관 키워드 우선, 없으면 테마 매칭을 쓴다.
  _RecommendedBook _fromRecommendedBook(RecommendedBook book) {
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
}

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

class _RecommendActionCard extends StatelessWidget {
  const _RecommendActionCard({
    required this.isLoading,
    required this.captureCount,
    required this.isCachedResult,
    required this.usedGeminiResult,
    required this.onGenerate,
  });

  final bool isLoading;
  final int captureCount;
  final bool isCachedResult;
  final bool usedGeminiResult;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final countText = captureCount == 0 ? '아직 확인 전' : '$captureCount개 확인됨';
    final cacheText = isCachedResult ? '\n이전 추천 결과를 불러왔어요.' : '';
    final aiText =
        usedGeminiResult ? '\nGemini 분석 결과를 사용했어요.' : '\n기본 추천 로직을 사용했어요.';

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
            '추천 생성',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 구절을 분석해 추천 후보를 만들고, 카카오 책 검색 결과와 연결합니다.\n저장 구절: $countText$cacheText$aiText',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(isLoading ? '추천 생성 중...' : '추천 다시 생성하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendReadyView extends StatelessWidget {
  const _RecommendReadyView();

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
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '아직 추천을 생성하지 않았어요',
            style: AppTextStyles.bodyStrong,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 구절이 3개 이상이면 추천 결과를 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

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
            '추천 도서를 확인하는 중이에요',
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

class _RecommendInsufficientView extends StatelessWidget {
  const _RecommendInsufficientView({
    required this.captureCount,
  });

  final int captureCount;

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
            Icons.info_outline_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '추천을 위한 구절이 부족해요',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '현재 저장된 구절은 $captureCount개예요.\n최소 3개 이상 저장하면 추천을 생성할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RecommendErrorView extends StatelessWidget {
  const _RecommendErrorView({
    required this.message,
  });

  final String message;

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
        ],
      ),
    );
  }
}

class _RecommendResultList extends StatelessWidget {
  const _RecommendResultList({
    required this.books,
    required this.isCachedResult,
    required this.usedGeminiResult,
  });

  final List<_RecommendedBook> books;
  final bool isCachedResult;
  final bool usedGeminiResult;

  @override
  Widget build(BuildContext context) {
    final sourceText = usedGeminiResult ? 'Gemini 분석 기반' : '기본 추천 로직 기반';
    final cacheText = isCachedResult ? '이전에 생성한 추천 결과' : '새로 생성한 추천 결과';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 결과',
          style: AppTextStyles.title,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$cacheText · $sourceText',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        ...books.map(
          (book) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RecommendedBookCard(book: book),
          ),
        ),
      ],
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.book,
  });

  final _RecommendedBook book;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (book.publisher.trim().isNotEmpty) book.publisher,
      '카카오 책 검색 확인',
    ].join(' · ');

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
                    borderRadius: BorderRadius.circular(999),
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
      decoration: BoxDecoration(
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

/// 화면 카드 표시 전용 추천 도서 뷰 모델.
///
/// 추천 엔진의 [RecommendedBook] 을 화면이 기대하는 필드 형태로 변환한 값이다
/// (어댑터 결과). 직렬화/Firestore 접근은 하지 않는다.
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
