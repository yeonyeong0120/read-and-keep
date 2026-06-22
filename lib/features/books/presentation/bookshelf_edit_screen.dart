import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/book.dart';
import '../domain/book_providers.dart';
import 'widgets/book_cover.dart';

class BookshelfEditScreen extends ConsumerStatefulWidget {
  const BookshelfEditScreen({super.key});

  @override
  ConsumerState<BookshelfEditScreen> createState() =>
      _BookshelfEditScreenState();
}

class _BookshelfEditScreenState extends ConsumerState<BookshelfEditScreen> {
  final Set<String> _selectedBookIds = {};
  bool _isDeleting = false;

  void _toggleBook(String bookId) {
    if (_isDeleting) return;

    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
      } else {
        _selectedBookIds.add(bookId);
      }
    });
  }

  void _selectAll(List<Book> books) {
    if (_isDeleting) return;

    setState(() {
      _selectedBookIds
        ..clear()
        ..addAll(books.map((book) => book.bookId));
    });
  }

  void _clearSelection() {
    if (_isDeleting) return;

    setState(() {
      _selectedBookIds.clear();
    });
  }

  Future<void> _confirmDelete(List<Book> books) async {
    if (_selectedBookIds.isEmpty || _isDeleting) {
      return;
    }

    final selectedBooks = books
        .where((book) => _selectedBookIds.contains(book.bookId))
        .toList();

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('선택한 책을 삭제할까요?'),
          content: Text(
            '선택한 책 ${selectedBooks.length}권과 해당 책에 저장된 구절이 함께 삭제됩니다.\n\n'
            '삭제 후에는 되돌릴 수 없어요.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (accepted != true) return;
    if (!mounted) return;

    await _deleteSelectedBooks(selectedBooks);
  }

  Future<void> _deleteSelectedBooks(List<Book> books) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      for (final book in books) {
        final bookRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('books')
            .doc(book.bookId);

        await _deleteBookCaptures(bookRef);
        await bookRef.delete();
      }

      ref.invalidate(booksProvider());

      if (!mounted) return;

      setState(() {
        _selectedBookIds.clear();
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${books.length}권을 삭제했어요.')),
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('책 삭제 중 오류가 발생했어요: $e')),
      );
    }
  }

  Future<void> _deleteBookCaptures(
    DocumentReference<Map<String, dynamic>> bookRef,
  ) async {
    const int batchSize = 300;

    while (true) {
      final capturesSnapshot =
          await bookRef.collection('captures').limit(batchSize).get();

      if (capturesSnapshot.docs.isEmpty) {
        break;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final captureDoc in capturesSnapshot.docs) {
        batch.delete(captureDoc.reference);
      }

      await batch.commit();

      if (capturesSnapshot.docs.length < batchSize) {
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('책장 편집'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isDeleting ? null : () => context.pop(),
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
            final selectedCount = _selectedBookIds.length;

            if (books.isEmpty) {
              return const _MessageBox(
                icon: Icons.menu_book_outlined,
                title: '등록된 책이 없어요',
                message: '삭제할 책이 없습니다.',
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '삭제할 책을 선택해주세요.',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '선택한 책과 해당 책에 저장된 구절이 함께 삭제됩니다.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isDeleting ? null : () => _selectAll(books),
                              child: const Text('전체 선택'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isDeleting ? null : _clearSelection,
                              child: const Text('선택 해제'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Text(
                          '선택 $selectedCount개 / 전체 ${books.length}권',
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      0,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xl,
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final isSelected =
                          _selectedBookIds.contains(book.bookId);

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: _EditableBookCard(
                          book: book,
                          isSelected: isSelected,
                          enabled: !_isDeleting,
                          onTap: () => _toggleBook(book.bookId),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.sm,
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: selectedCount == 0 || _isDeleting
                            ? null
                            : () => _confirmDelete(books),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          _isDeleting
                              ? '삭제 중...'
                              : '선택한 책 삭제하기 ($selectedCount권)',
                        ),
                      ),
                    ),
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

class _EditableBookCard extends StatelessWidget {
  const _EditableBookCard({
    required this.book,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final Book book;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metaText = [
      if (book.author.isNotEmpty) book.author,
      if (book.publisher.isNotEmpty) book.publisher,
    ].join(' · ');

    return Material(
      color: isSelected ? const Color(0xFFFFF1D9) : AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
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
                      '저장된 구절 ${book.captureCount}개',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
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