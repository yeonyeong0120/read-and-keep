import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../captures/presentation/capture_method_screen.dart';
import '../data/models/book.dart';
import '../data/models/kakao_book.dart';
import '../domain/book_providers.dart';
import 'bookshelf_overview_screen.dart';
import 'widgets/book_cover.dart';
import 'widgets/book_relative_time.dart';

/// BK-001 책 선택 화면.
///
/// 검색어가 비어 있으면 내 책장([booksProvider])을,
/// 검색 중이면 카카오 검색 결과([bookSearchProvider])를 보여준다.
/// 책을 "선택" 하면 문장 추가 방법 선택 화면(CP-001)으로 이동한다.
class BookSelectScreen extends ConsumerStatefulWidget {
  const BookSelectScreen({super.key});

  @override
  ConsumerState<BookSelectScreen> createState() => _BookSelectScreenState();
}

class _BookSelectScreenState extends ConsumerState<BookSelectScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      final query = value.trim();

      setState(() {
        _query = query;
      });

      if (query.isEmpty) {
        ref.read(bookSearchProvider.notifier).clear();
      } else {
        ref.read(bookSearchProvider.notifier).search(query);
      }
    });
  }

  Future<void> _addFromKakao(KakaoBook kakaoBook) async {
    final book =
        await ref.read(bookActionProvider.notifier).addFromKakao(kakaoBook);

    if (book != null && mounted) {
      _goToCaptureMethod(book);
    }
  }

  Future<void> _selectExisting(Book book) async {
    await ref.read(bookActionProvider.notifier).selectExisting(book.bookId);

    if (mounted) {
      _goToCaptureMethod(book);
    }
  }

  void _goToCaptureMethod(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureMethodScreen(
          bookId: book.bookId,
          bookTitle: book.title,
          bookAuthor: book.author,
          bookPublisher: book.publisher,
          bookCoverUrl: book.coverUrl,
        ),
      ),
    );
  }

  void _goToBookshelfOverview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BookshelfOverviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('책 선택'),
      ),
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
                  : _BookshelfContent(
                      onSelect: _selectExisting,
                      onOpenOverview: _goToBookshelfOverview,
                    ),
            ),
            _BottomNotice(isSearching: isSearching),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

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

class _BookshelfContent extends ConsumerWidget {
  const _BookshelfContent({
    required this.onSelect,
    required this.onOpenOverview,
  });

  final ValueChanged<Book> onSelect;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider());

    return booksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
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
              metaText: '최근 기록 ${bookRelativeTime(recent.lastSelectedAt)}',
              onSelect: () => onSelect(recent),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(
              '내 책장',
              actionLabel: '전체보기 >',
              onAction: onOpenOverview,
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

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.onSelect,
  });

  final ValueChanged<KakaoBook> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(bookSearchProvider);

    return searchAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
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
          BookCover(url: book.coverUrl),
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
                Text(
                  metaText,
                  style: AppTextStyles.caption,
                ),
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

class _KakaoCard extends StatelessWidget {
  const _KakaoCard({
    required this.kakaoBook,
    required this.onSelect,
  });

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
          BookCover(url: kakaoBook.thumbnail),
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

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.onPressed,
  });

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
    this.title, {
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.title,
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.message,
  });

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
            Icon(
              icon,
              size: 40,
              color: AppColors.textSecondary,
            ),
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

class _BottomNotice extends StatelessWidget {
  const _BottomNotice({
    required this.isSearching,
  });

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
              child: Text(
                message,
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _yearOf(String datetime) {
  if (datetime.length < 4) return '';
  return datetime.substring(0, 4);
}