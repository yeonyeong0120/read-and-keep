import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/book.dart';
import '../data/repositories/book_repository.dart';
import '../domain/book_providers.dart';
import 'widgets/book_cover.dart';
import 'widgets/book_relative_time.dart';

/// BK-002 책장 전체보기 화면.
///
/// 정렬([BookSort])과 검색(클라이언트 측 필터)을 로컬 상태로 관리하고,
/// [booksProvider] 스트림을 구독해 리스트로 보여준다.
class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  final _searchController = TextEditingController();

  // 검색어·정렬 모두 위젯 로컬 상태.
  String _query = '';
  BookSort _sort = BookSort.recentRecord;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 제목·저자 부분일치로 클라이언트에서 필터링한다(API 호출 아님).
  List<Book> _filter(List<Book> books) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return books;
    return books
        .where((book) =>
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider(sort: _sort));

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 책장'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO(BK-003): 책장 관리 메뉴(7-4).
            },
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
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
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: '내 책장에서 검색',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SortChips(
                    selected: _sort,
                    onSelected: (sort) => setState(() => _sort = sort),
                  ),
                ],
              ),
            ),
            Expanded(
              child: booksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _MessageBox(
                  icon: Icons.error_outline_rounded,
                  message: '책장을 불러오지 못했습니다',
                ),
                data: (books) => _buildList(context, books),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Book> books) {
    // 전체 0권: 책 등록 유도.
    if (books.isEmpty) {
      return _EmptyShelf(
        onRegister: () => context.go(AppRoutes.bookSelect),
      );
    }

    final filtered = _filter(books);
    // 검색 결과 0권.
    if (filtered.isEmpty) {
      return const _MessageBox(
        icon: Icons.search_off_rounded,
        message: '검색 결과가 없습니다',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('총 ${filtered.length}권의 책', style: AppTextStyles.caption),
          );
        }
        final book = filtered[index - 1];
        return _ShelfBookCard(
          book: book,
          onTap: () => context.go(AppRoutes.bookDetailOf(book.bookId)),
        );
      },
    );
  }
}

/// 정렬 칩 3종.
class _SortChips extends StatelessWidget {
  const _SortChips({required this.selected, required this.onSelected});

  final BookSort selected;
  final ValueChanged<BookSort> onSelected;

  @override
  Widget build(BuildContext context) {
    // 라벨이 길어 가로 스크롤로 둔다.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SortChip(
            label: '최근 기록순',
            value: BookSort.recentRecord,
            selected: selected,
            onSelected: onSelected,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SortChip(
            label: '저장한 구절 많은 순',
            value: BookSort.captureCount,
            selected: selected,
            onSelected: onSelected,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SortChip(
            label: '제목순',
            value: BookSort.title,
            selected: selected,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final BookSort value;
  final BookSort selected;
  final ValueChanged<BookSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outline,
      ),
    );
  }
}

/// 책장 리스트형 카드.
class _ShelfBookCard extends StatelessWidget {
  const _ShelfBookCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recordTime = book.lastRecordAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: Container(
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
                      '저장한 구절 ${book.captureCount}개',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '최근 기록 ${bookRelativeTime(recordTime)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전체 0권일 때의 안내 + 책 등록 버튼.
class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('등록된 책이 없습니다', style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              '책을 등록하고 문장을 기록해보세요',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_rounded),
              label: const Text('책 등록하기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 중앙 안내(빈 검색 결과/에러 공용).
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
