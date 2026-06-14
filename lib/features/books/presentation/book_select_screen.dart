import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/book.dart';
import '../data/models/kakao_book.dart';
import '../domain/book_providers.dart';

/// BK-001 책 선택 화면.
///
/// 검색어가 비어 있으면 내 책장([booksProvider])을, 검색 중이면 카카오 검색
/// 결과([bookSearchProvider])를 보여준다. 책을 "선택" 하면 책 상세로 이동한다.
class BookSelectScreen extends ConsumerStatefulWidget {
  const BookSelectScreen({super.key});

  @override
  ConsumerState<BookSelectScreen> createState() => _BookSelectScreenState();
}

class _BookSelectScreenState extends ConsumerState<BookSelectScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // 디바운스가 확정한 검색어. 본문 분기는 이 값을 기준으로 한다.
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 입력 변화 시 기존 타이머를 취소하고 400ms 디바운스 후 검색/초기화한다.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final query = value.trim();
      setState(() => _query = query);
      if (query.isEmpty) {
        ref.read(bookSearchProvider.notifier).clear();
      } else {
        ref.read(bookSearchProvider.notifier).search(query);
      }
    });
  }

  /// 카카오 검색 결과 책을 책장에 등록하고 상세로 이동한다.
  Future<void> _addFromKakao(KakaoBook kakaoBook) async {
    final book =
        await ref.read(bookActionProvider.notifier).addFromKakao(kakaoBook);
    if (book != null && mounted) {
      context.go(AppRoutes.bookDetailOf(book.bookId));
    }
  }

  /// 이미 책장에 있는 책을 선택(마지막 선택 시각 갱신)하고 상세로 이동한다.
  Future<void> _selectExisting(Book book) async {
    await ref.read(bookActionProvider.notifier).selectExisting(book.bookId);
    if (mounted) {
      context.go(AppRoutes.bookDetailOf(book.bookId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('책 선택')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  const Text(
                    '문장을 기록할 책을 먼저 선택해주세요',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isSearching
                  ? _SearchResults(onSelect: _addFromKakao)
                  : _BookshelfContent(onSelect: _selectExisting),
            ),
            _BottomNotice(isSearching: isSearching),
          ],
        ),
      ),
    );
  }
}

/// 검색 입력 필드.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: '책 제목, 저자, ISBN 검색',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

/// 검색어가 없을 때: 내 책장 + 최근 선택한 책.
class _BookshelfContent extends ConsumerWidget {
  const _BookshelfContent({required this.onSelect});

  final ValueChanged<Book> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider());

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _MessageBox(
        icon: Icons.error_outline_rounded,
        message: '책장을 불러오지 못했습니다',
      ),
      data: (books) {
        if (books.isEmpty) {
          return const _MessageBox(
            icon: Icons.menu_book_outlined,
            message: '찾는 책이 없다면 검색해서\n내 책장에 추가해보세요',
          );
        }

        // 최근 선택한 책 1건(lastSelectedAt 최신).
        final recent = books.reduce(
          (a, b) => a.lastSelectedAt.isAfter(b.lastSelectedAt) ? a : b,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: [
            const _SectionHeader('최근 선택한 책'),
            const SizedBox(height: AppSpacing.md),
            _BookCard(
              book: recent,
              metaText: '최근 기록 ${_relativeTime(recent.lastSelectedAt)}',
              onSelect: () => onSelect(recent),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              '내 책장',
              actionLabel: '전체보기 >',
              onAction: () {
                // TODO(BK-002): 책장 전체보기 화면으로 라우팅.
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ...books.map(
              (book) => _BookCard(
                book: book,
                metaText: '저장된 구절 ${book.captureCount}개',
                onSelect: () => onSelect(book),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 검색어가 있을 때: 카카오 검색 결과.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.onSelect});

  final ValueChanged<KakaoBook> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(bookSearchProvider);

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _MessageBox(
        icon: Icons.error_outline_rounded,
        message: '검색 중 문제가 발생했습니다',
      ),
      data: (results) {
        if (results.isEmpty) {
          return const _MessageBox(
            icon: Icons.search_off_rounded,
            message: '검색 결과가 없습니다\n다른 검색어로 시도해보세요',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          children: results
              .map(
                (kakaoBook) => _KakaoCard(
                  kakaoBook: kakaoBook,
                  onSelect: () => onSelect(kakaoBook),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// 내 책장 책 카드.
class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.metaText,
    required this.onSelect,
  });

  final Book book;
  final String metaText;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          _BookCover(url: book.coverUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
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
                Text(metaText, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _SelectButton(onPressed: onSelect),
        ],
      ),
    );
  }
}

/// 카카오 검색 결과 카드.
class _KakaoCard extends StatelessWidget {
  const _KakaoCard({required this.kakaoBook, required this.onSelect});

  final KakaoBook kakaoBook;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final year = _yearOf(kakaoBook.datetime);
    final meta = [
      if (kakaoBook.publisher.isNotEmpty) kakaoBook.publisher,
      if (year.isNotEmpty) year,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          _BookCover(url: kakaoBook.thumbnail),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kakaoBook.title,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  kakaoBook.authorText,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meta,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _SelectButton(onPressed: onSelect),
        ],
      ),
    );
  }
}

/// 책 표지. 없거나 로드 실패 시 placeholder 박스로 대체한다.
class _BookCover extends StatelessWidget {
  const _BookCover({required this.url});

  final String url;

  static const double _width = 48;
  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smRadius,
      child: url.isEmpty
          ? const _CoverPlaceholder(width: _width, height: _height)
          : CachedNetworkImage(
              imageUrl: url,
              width: _width,
              height: _height,
              fit: BoxFit.cover,
              placeholder: (context, _) =>
                  const _CoverPlaceholder(width: _width, height: _height),
              errorWidget: (context, _, _) =>
                  const _CoverPlaceholder(width: _width, height: _height),
            ),
    );
  }
}

/// 표지 placeholder.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 24,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// 작은 "선택" 버튼. 풀폭 테마를 누르고 컴팩트하게 만든다.
class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: AppTextStyles.caption,
      ),
      child: const Text('선택'),
    );
  }
}

/// 섹션 헤더(우측 액션 선택적).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.title),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: AppTextStyles.caption),
          ),
      ],
    );
  }
}

/// 중앙 안내(빈 상태/에러 공용).
class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단 안내 박스. 검색 여부에 따라 문구가 바뀐다.
class _BottomNotice extends StatelessWidget {
  const _BottomNotice({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final message = isSearching
        ? '책을 선택하면 내 책장에 추가됩니다'
        : '찾는 책이 없다면 검색해서 내 책장에 추가해보세요';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(message, style: AppTextStyles.caption),
            ),
          ],
        ),
      ),
    );
  }
}

/// datetime(ISO 문자열)에서 연도 4자리를 추출한다. 없으면 빈 문자열.
String _yearOf(String datetime) {
  if (datetime.length < 4) return '';
  return datetime.substring(0, 4);
}

/// 과거 시각을 상대 표현으로 바꾼다.
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inDays >= 1) return '${diff.inDays}일 전';
  if (diff.inHours >= 1) return '${diff.inHours}시간 전';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}분 전';
  return '방금 전';
}
