import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/data/models/book.dart';
import '../../books/data/models/kakao_book.dart';
import '../../books/domain/book_providers.dart';
import '../../captures/data/models/capture.dart';
import '../../captures/domain/capture_providers.dart';
import '../data/models/recommendation_cache.dart';
import '../domain/recommendation_providers.dart';

/// 추천 상세(RC-003) 화면.
///
/// RC-001 의 "오늘의 추천"/"함께 보면 좋은 책" 카드에서 [RecommendedBook] 을
/// extra 로 받아 진입한다(진입 컨텍스트 무관 동일 컴포넌트). 추천 브랜치 하위
/// 중첩 라우트라 하단 탭바가 유지된다.
///
/// 책 소개(카카오 contents)와 근거 구절(linkedCaptureIds)은 진입 후 1회 비동기
/// 조회한다. "내 책장에 추가"/"관심 없음" 액션은 [AsyncValue.guard] 로 처리하고
/// state 할당만 [mounted] 로 가드한다.
class RecommendDetailScreen extends ConsumerStatefulWidget {
  const RecommendDetailScreen({super.key, required this.book});

  final RecommendedBook book;

  @override
  ConsumerState<RecommendDetailScreen> createState() =>
      _RecommendDetailScreenState();
}

class _RecommendDetailScreenState extends ConsumerState<RecommendDetailScreen> {
  /// 책 소개 + 책장 추가용 카카오 매칭 + 근거 구절 로드 결과.
  AsyncValue<_DetailExtra> _extra = const AsyncValue.loading();

  /// 책장 추가 결과. value==null 이면 미추가, 값이 있으면 추가된 책(이동 대상).
  AsyncValue<Book?> _addResult = const AsyncValue.data(null);

  /// 관심 없음 처리 진행 상태.
  AsyncValue<void> _dismissResult = const AsyncValue.data(null);

  @override
  void initState() {
    super.initState();
    // 진입 직후 1회만 부가 데이터 조회(추천 생성과 무관).
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtra());
  }

  Future<void> _loadExtra() async {
    final result = await AsyncValue.guard(() async {
      final bookRepo = ref.read(bookRepositoryProvider);

      // 1) 카카오 재검색으로 책 소개/등록 후보를 확보한다.
      KakaoBook? match;
      try {
        final query = '${widget.book.title} ${widget.book.author}'.trim();
        final results = await bookRepo.searchBooks(query);
        match = _findMatch(results, widget.book.bookId);
      } catch (_) {
        match = null; // 검색 실패는 책 소개/매칭만 생략하고 진행.
      }

      // 2) 근거 구절 조회(없으면 빈 목록).
      final linked = await _loadLinkedCaptures();

      return _DetailExtra(
        description: match?.contents ?? '',
        kakaoMatch: match,
        linkedCaptures: linked,
      );
    });

    if (!mounted) return;
    setState(() => _extra = result);
  }

  /// linkedCaptureIds 로 사용자 구절을 조회한다.
  ///
  /// 구절이 어느 책 소속인지 알 수 없으므로 사용자의 책을 순회하며
  /// watchCapturesByBook 결과에서 id 를 매칭한다. id 가 비면 빈 목록.
  Future<List<Capture>> _loadLinkedCaptures() async {
    final wanted = widget.book.linkedCaptureIds.toSet();
    if (wanted.isEmpty) return const <Capture>[];

    final books = await ref.read(bookRepositoryProvider).watchBooks().first;
    final captureRepo = ref.read(captureRepositoryProvider);

    final found = <Capture>[];
    for (final book in books) {
      final captures = await captureRepo.watchCapturesByBook(book.bookId).first;
      found.addAll(captures.where((c) => wanted.contains(c.id)));
    }
    return found;
  }

  /// 검색 결과에서 bookId(isbn13) 가 일치하는 책을, 없으면 첫 결과를 고른다.
  KakaoBook? _findMatch(List<KakaoBook> results, String bookId) {
    if (results.isEmpty) return null;
    if (bookId.isNotEmpty) {
      for (final book in results) {
        if (book.isbn13 == bookId) return book;
      }
    }
    return results.first;
  }

  /// 매칭된 카카오 책이 없을 때, 추천 정보로 최소 등록 정보를 구성한다.
  /// bookId 는 isbn13 이므로 KakaoBook.isbn13 게터가 그대로 해석한다.
  KakaoBook _fallbackKakaoBook() {
    return KakaoBook(
      title: widget.book.title,
      authors:
          widget.book.author.trim().isEmpty ? const [] : [widget.book.author],
      thumbnail: widget.book.coverUrl,
      contents: _extra.value?.description ?? '',
      isbn: widget.book.bookId,
      publisher: '',
      datetime: '',
    );
  }

  Future<void> _addToShelf() async {
    if (_addResult.isLoading || _addResult.value != null) return;

    setState(() => _addResult = const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      final kakaoBook = _extra.value?.kakaoMatch ?? _fallbackKakaoBook();
      return ref.read(bookRepositoryProvider).addBookFromKakao(kakaoBook);
    });

    if (!mounted) return;
    setState(() => _addResult = result);

    result.when(
      data: (book) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내 책장에 추가되었어요')),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('책장 추가에 실패했어요: $error')),
        );
      },
    );
  }

  Future<void> _dismiss() async {
    if (_dismissResult.isLoading) return;

    setState(() => _dismissResult = const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      await ref.read(recommendationRepositoryProvider).dismissBook(
            bookId: widget.book.bookId,
            title: widget.book.title,
          );
    });

    if (!mounted) return;
    setState(() => _dismissResult = result);

    result.when(
      // 관심 없음 처리 후 RC-001 로 복귀(다음 생성 시 제외된다).
      data: (_) => context.pop(),
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리에 실패했어요: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final description = _extra.value?.description ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('추천 상세'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            _BookInfoCard(book: book, description: description),
            const SizedBox(height: AppSpacing.xl),
            _ReasonSection(reason: book.reason),
            ..._buildLinkedSection(),
            ..._buildKeywordSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// "추천에 반영된 문장" 섹션. linkedCaptureIds 가 비면 통째로 생략한다.
  List<Widget> _buildLinkedSection() {
    if (widget.book.linkedCaptureIds.isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.xl),
      const _SectionHeader(
        icon: Icons.format_quote_rounded,
        title: '추천에 반영된 문장',
      ),
      const SizedBox(height: AppSpacing.md),
      _extra.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const _LinkedCapturesUnavailable(),
        data: (extra) {
          if (extra.linkedCaptures.isEmpty) {
            return const _LinkedCapturesUnavailable();
          }
          return Column(
            children: extra.linkedCaptures
                .map(
                  (capture) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _LinkedCaptureCard(capture: capture),
                  ),
                )
                .toList(),
          );
        },
      ),
    ];
  }

  /// "관련 키워드" 섹션. relatedKeywords 가 비면 생략한다.
  List<Widget> _buildKeywordSection() {
    final keywords = widget.book.relatedKeywords;
    if (keywords.isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.xl),
      const _SectionHeader(
        icon: Icons.sell_outlined,
        title: '관련 키워드',
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: keywords.map((label) => _LabelChip(label: label)).toList(),
      ),
    ];
  }

  Widget _buildActions() {
    final added = _addResult.value != null;
    final adding = _addResult.isLoading;
    final dismissing = _dismissResult.isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (added || adding || dismissing) ? null : _addToShelf,
            icon: adding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(added
                    ? Icons.check_rounded
                    : Icons.library_add_outlined),
            label: Text(added ? '내 책장에 추가됨' : '내 책장에 추가'),
          ),
        ),
        if (added) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(
                AppRoutes.bookDetailOf(_addResult.value!.bookId),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('내 책장으로 이동'),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: dismissing ? null : _dismiss,
          child: const Text('관심 없음'),
        ),
      ],
    );
  }
}

/// 부가 데이터(책 소개 / 등록용 카카오 매칭 / 근거 구절) 묶음.
class _DetailExtra {
  const _DetailExtra({
    required this.description,
    required this.kakaoMatch,
    required this.linkedCaptures,
  });

  final String description;
  final KakaoBook? kakaoMatch;
  final List<Capture> linkedCaptures;
}

// =============================================================================
// 책 정보 카드
// =============================================================================

class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({
    required this.book,
    required this.description,
  });

  final RecommendedBook book;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCover(url: book.coverUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppTextStyles.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      book.author,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: AppTextStyles.body,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const _EmptyCover();
    }

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: Image.network(
        url,
        width: 88,
        height: 124,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _EmptyCover(),
      ),
    );
  }
}

class _EmptyCover extends StatelessWidget {
  const _EmptyCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 124,
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
// 섹션들
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}

/// "왜 추천했을까?" — LLM 추천 사유.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.favorite_outline_rounded,
          title: '왜 추천했을까?',
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Text(
            reason.trim().isEmpty
                ? '저장한 구절의 분위기와 독서 취향을 바탕으로 추천한 책이에요.'
                : reason,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}

/// 근거 구절 카드(구절 텍스트 + 책 제목 메타).
class _LinkedCaptureCard extends StatelessWidget {
  const _LinkedCaptureCard({required this.capture});

  final Capture capture;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${capture.quote}”',
            style: AppTextStyles.body,
          ),
          if (capture.bookTitle.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              capture.bookTitle,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkedCapturesUnavailable extends StatelessWidget {
  const _LinkedCapturesUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: const Text(
        '반영된 문장을 불러올 수 없어요.',
        style: AppTextStyles.caption,
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

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
