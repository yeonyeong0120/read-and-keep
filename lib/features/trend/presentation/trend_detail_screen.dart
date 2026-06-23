import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/data/models/book.dart';
import '../../books/data/models/kakao_book.dart';
import '../../books/domain/book_providers.dart';
import '../../books/presentation/widgets/book_cover.dart';
import '../data/models/bestseller_book.dart';
import 'widgets/aladin_source_note.dart';

/// 트렌드 책 상세 (TR-003).
///
/// TR-001/002 의 베스트셀러 카드에서 [BestsellerBook] 을 extra 로 받아 진입한다.
/// publicBooks/featuredCaptures 집계가 없어 알라딘 데이터로 가능한 부분만 보여준다.
/// 책 소개(알라딘 description, 비어 있으면 카카오로 보강), 순위 기반 정적 사유,
/// "내 책장에 추가" 단일 액션, 알라딘 상품 링크를 제공한다. 트렌드 브랜치 하위
/// 중첩이라 하단 탭바가 유지된다.
class TrendDetailScreen extends ConsumerStatefulWidget {
  const TrendDetailScreen({super.key, required this.book});

  final BestsellerBook book;

  @override
  ConsumerState<TrendDetailScreen> createState() => _TrendDetailScreenState();
}

class _TrendDetailScreenState extends ConsumerState<TrendDetailScreen> {
  /// 책 소개 + 책장 추가용 카카오 매칭. 알라딘 description 이 있으면 그대로 쓴다.
  AsyncValue<_DetailExtra> _extra = const AsyncValue.loading();

  /// 책장 추가 결과. value==null 이면 미추가, 값이 있으면 추가된 책(이동 대상).
  AsyncValue<Book?> _addResult = const AsyncValue.data(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtra());
  }

  /// 책 소개를 확보한다.
  ///
  /// 알라딘 description 이 있으면 추가 호출 없이 그대로 사용한다. 비어 있을
  /// 때만 카카오로 isbn13/제목 재검색해 책 소개(contents)를 보강한다. 검색에서
  /// 매칭된 카카오 책은 책장 추가 시 더 정확한 메타데이터로 재사용한다.
  Future<void> _loadExtra() async {
    final book = widget.book;
    final aladinDescription = book.description.trim();

    final result = await AsyncValue.guard(() async {
      // 알라딘 소개가 이미 있으면 카카오를 부르지 않는다.
      if (aladinDescription.isNotEmpty) {
        return _DetailExtra(description: aladinDescription, kakaoMatch: null);
      }

      KakaoBook? match;
      try {
        final query = '${book.title} ${book.author}'.trim();
        final results = await ref.read(bookRepositoryProvider).searchBooks(query);
        match = _findMatch(results, book.isbn13);
      } catch (_) {
        match = null; // 검색 실패는 소개/매칭만 생략하고 진행.
      }

      return _DetailExtra(
        description: match?.contents.trim() ?? '',
        kakaoMatch: match,
      );
    });

    if (!mounted) return;
    setState(() => _extra = result);
  }

  /// 검색 결과에서 isbn13 이 일치하는 책을, 없으면 첫 결과를 고른다.
  KakaoBook? _findMatch(List<KakaoBook> results, String isbn13) {
    if (results.isEmpty) return null;
    if (isbn13.isNotEmpty) {
      for (final book in results) {
        if (book.isbn13 == isbn13) return book;
      }
    }
    return results.first;
  }

  /// 카카오 매칭이 없을 때 BestsellerBook 정보로 등록용 KakaoBook 을 구성한다.
  KakaoBook _fallbackKakaoBook() {
    final book = widget.book;
    return KakaoBook(
      title: book.title,
      authors: book.author.trim().isEmpty ? const [] : [book.author],
      thumbnail: book.coverUrl,
      contents: _extra.value?.description ?? book.description,
      isbn: book.isbn13,
      publisher: book.publisher,
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
      data: (_) {
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

  /// 알라딘 상품 페이지를 외부 브라우저로 연다.
  Future<void> _openAladin() async {
    final url = widget.book.aladinProductUrl;
    final messenger = ScaffoldMessenger.of(context);
    if (url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('상품 페이지 주소를 찾을 수 없어요')),
      );
      return;
    }

    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('상품 페이지를 열 수 없어요')),
      );
    }
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
        title: const Text('트렌드 상세'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            _BookInfoCard(book: book, onOpenAladin: _openAladin),
            ..._buildDescriptionSection(description),
            const SizedBox(height: AppSpacing.xl),
            _ReasonSection(rank: book.rank),
            const SizedBox(height: AppSpacing.xl),
            _buildActions(),
            const SizedBox(height: AppSpacing.lg),
            const AladinSourceNote(),
          ],
        ),
      ),
    );
  }

  /// "책 소개" 섹션. 알라딘/카카오 모두 소개가 없으면 통째로 생략한다.
  List<Widget> _buildDescriptionSection(String description) {
    // 로딩 중에는 자리만 잡아 둔다.
    if (_extra.isLoading) {
      return const [
        SizedBox(height: AppSpacing.xl),
        _SectionHeader(icon: Icons.menu_book_rounded, title: '책 소개'),
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (description.trim().isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.xl),
      const _SectionHeader(icon: Icons.menu_book_rounded, title: '책 소개'),
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
          description,
          style: AppTextStyles.body.copyWith(height: 1.5),
        ),
      ),
    ];
  }

  Widget _buildActions() {
    final added = _addResult.value != null;
    final adding = _addResult.isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (added || adding) ? null : _addToShelf,
            icon: adding
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(added ? Icons.check_rounded : Icons.library_add_outlined),
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
      ],
    );
  }
}

/// 책 소개/등록용 카카오 매칭 묶음.
class _DetailExtra {
  const _DetailExtra({required this.description, required this.kakaoMatch});

  final String description;
  final KakaoBook? kakaoMatch;
}

/// 책 정보 카드: 큰 표지 + 제목/저자 + "이번 주 N위" 배지 + 알라딘 링크.
class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({required this.book, required this.onOpenAladin});

  final BestsellerBook book;
  final VoidCallback onOpenAladin;

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
              BookCover(url: book.coverUrl, width: 88, height: 124, iconSize: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (book.rank > 0) _RankBadge(rank: book.rank),
                    if (book.rank > 0) const SizedBox(height: AppSpacing.sm),
                    Text(
                      book.title,
                      style: AppTextStyles.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        book.author,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      '많은 독자가 주목하고 있는 책이에요.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 알라딘 상품 페이지 링크(약관 의무).
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onOpenAladin,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('알라딘에서 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

/// "이번 주 N위" 왕관 배지.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '이번 주 $rank위',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "왜 주목받고 있을까요?" 섹션.
///
/// publicBooks/공감 집계가 없으므로 동적 사유 대신 순위 기반 정적 문구를 둔다.
class _ReasonSection extends StatelessWidget {
  const _ReasonSection({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final reason = rank > 0
        ? '이번 주 베스트셀러 $rank위에 오른 책이에요. 많은 독자가 함께 읽고 있어요.'
        : '많은 독자가 함께 읽고 있는 책이에요.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.local_fire_department_outlined,
          title: '왜 주목받고 있을까요?',
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
          child: Text(reason, style: AppTextStyles.body.copyWith(height: 1.5)),
        ),
      ],
    );
  }
}

/// 섹션 헤더(아이콘 + 제목).
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
