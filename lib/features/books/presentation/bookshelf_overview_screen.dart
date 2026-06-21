import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/book.dart';
import '../domain/book_providers.dart';
import 'widgets/book_cover.dart';
import 'widgets/book_relative_time.dart';

enum _BookshelfSortType {
  recent,
  captureCount,
  title,
}

class BookshelfOverviewScreen extends ConsumerStatefulWidget {
  const BookshelfOverviewScreen({super.key});

  @override
  ConsumerState<BookshelfOverviewScreen> createState() =>
      _BookshelfOverviewScreenState();
}

class _BookshelfOverviewScreenState
    extends ConsumerState<BookshelfOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  _BookshelfSortType _sortType = _BookshelfSortType.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.trim();
    });
  }

  void _changeSortType(_BookshelfSortType sortType) {
    setState(() {
      _sortType = sortType;
    });
  }

  void _goToBookDetail(Book book) {
    context.push(AppRoutes.bookDetailOf(book.bookId));
  }

  void _goToBookshelfEdit() {
    context.push(AppRoutes.bookshelfEdit);
  }

  List<Book> _filterAndSortBooks(List<Book> books) {
    final filtered = books.where((book) {
      if (_query.isEmpty) return true;

      final lowerQuery = _query.toLowerCase();
      final title = book.title.toLowerCase();
      final author = book.author.toLowerCase();
      final publisher = book.publisher.toLowerCase();

      return title.contains(lowerQuery) ||
          author.contains(lowerQuery) ||
          publisher.contains(lowerQuery);
    }).toList();

    switch (_sortType) {
      case _BookshelfSortType.recent:
        filtered.sort(
          (a, b) => b.lastRecordAt.compareTo(a.lastRecordAt),
        );
        break;
      case _BookshelfSortType.captureCount:
        filtered.sort(
          (a, b) => b.captureCount.compareTo(a.captureCount),
        );
        break;
      case _BookshelfSortType.title:
        filtered.sort(
          (a, b) => a.title.compareTo(b.title),
        );
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('내 책장'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: booksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, _) => const _MessageBox(
            icon: Icons.error_outline_rounded,
            title: '책장을 불러오지 못했어요',
            message: '잠시 후 다시 시도해주세요.',
          ),
          data: (books) {
            final visibleBooks = _filterAndSortBooks(books);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내가 저장한 모든 책을 한눈에 확인해보세요',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: '내 책장에서 검색',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SortChip(
                              label: '최근 기록순',
                              selected: _sortType == _BookshelfSortType.recent,
                              onTap: () =>
                                  _changeSortType(_BookshelfSortType.recent),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SortChip(
                              label: '저장한 구절 많은 순',
                              selected:
                                  _sortType == _BookshelfSortType.captureCount,
                              onTap: () => _changeSortType(
                                _BookshelfSortType.captureCount,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SortChip(
                              label: '제목순',
                              selected: _sortType == _BookshelfSortType.title,
                              onTap: () =>
                                  _changeSortType(_BookshelfSortType.title),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _query.isEmpty
                                  ? '총 ${books.length}권의 책'
                                  : '검색 결과 ${visibleBooks.length}권',
                              style: AppTextStyles.bodyStrong,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _goToBookshelfEdit,
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('편집'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: books.isEmpty
                      ? const _MessageBox(
                          icon: Icons.menu_book_outlined,
                          title: '등록된 책이 없어요',
                          message: '문장을 추가할 때 책을 검색해서 내 책장에 등록해보세요.',
                        )
                      : visibleBooks.isEmpty
                          ? const _MessageBox(
                              icon: Icons.search_off_rounded,
                              title: '검색 결과가 없어요',
                              message: '다른 검색어로 다시 찾아보세요.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenHorizontal,
                                0,
                                AppSpacing.screenHorizontal,
                                AppSpacing.xl,
                              ),
                              itemCount: visibleBooks.length,
                              itemBuilder: (context, index) {
                                final book = visibleBooks[index];

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _BookListCard(
                                    book: book,
                                    onTap: () => _goToBookDetail(book),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _BookListCard extends StatelessWidget {
  const _BookListCard({
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metaText = [
      if (book.author.isNotEmpty) book.author,
      if (book.publisher.isNotEmpty) book.publisher,
    ].join(' · ');

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
              BookCover(url: book.coverUrl),
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
                    if (metaText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        metaText,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '저장한 구절 ${book.captureCount}개 · 최근 기록 ${bookRelativeTime(book.lastRecordAt)}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
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
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.bodyStrong,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
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