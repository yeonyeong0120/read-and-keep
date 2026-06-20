import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../captures/data/models/capture.dart';
import '../../captures/data/models/capture_comment.dart';
import '../../captures/domain/capture_providers.dart';
import '../data/models/book.dart';
import '../domain/book_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  Future<void> _deleteBook(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('이 책을 삭제할까요?'),
          content: Text(
            '"${book.title}" 책과 이 책에 저장된 구절이 함께 삭제됩니다.\n\n'
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
    if (!context.mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      final bookRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(book.bookId);

      await _deleteBookCaptures(bookRef);
      await bookRef.delete();

      ref.invalidate(booksProvider());
      ref.invalidate(bookProvider(book.bookId));
      ref.invalidate(bookCapturesProvider(bookId: book.bookId));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('책을 삭제했어요.')),
      );

      context.pop();
    } catch (e) {
      if (!context.mounted) return;

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

      for (final captureDoc in capturesSnapshot.docs) {
        await _deleteCaptureComments(captureDoc.reference);
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

  Future<void> _deleteCaptureComments(
    DocumentReference<Map<String, dynamic>> captureRef,
  ) async {
    const int batchSize = 300;

    while (true) {
      final commentsSnapshot =
          await captureRef.collection('comments').limit(batchSize).get();

      if (commentsSnapshot.docs.isEmpty) {
        break;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }

      await batch.commit();

      if (commentsSnapshot.docs.length < batchSize) {
        break;
      }
    }
  }

  void _goToBookshelfEdit(BuildContext context) {
    context.push(AppRoutes.bookshelfEdit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookProvider(bookId));

    return bookAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('책 상세')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('책 상세')),
        body: const Center(
          child: Text('책을 불러오지 못했습니다', style: AppTextStyles.body),
        ),
      ),
      data: (book) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('책 상세'),
            actions: [
              PopupMenuButton<_BookDetailMenuAction>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _BookDetailMenuAction.editBookshelf:
                      _goToBookshelfEdit(context);
                      break;
                    case _BookDetailMenuAction.deleteBook:
                      _deleteBook(context, ref, book);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: _BookDetailMenuAction.editBookshelf,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          SizedBox(width: AppSpacing.sm),
                          Text('책장 편집'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _BookDetailMenuAction.deleteBook,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '이 책 삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: _DetailBody(book: book),
        );
      },
    );
  }
}

enum _BookDetailMenuAction {
  editBookshelf,
  deleteBook,
}

enum _CaptureVisibilityFilter {
  all,
  publicOnly,
  privateOnly,
}

enum _CaptureSortType {
  newestFirst,
  oldestFirst,
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.book});

  final Book book;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  _CaptureVisibilityFilter _visibilityFilter = _CaptureVisibilityFilter.all;
  _CaptureSortType _sortType = _CaptureSortType.newestFirst;

  Future<void> _deleteCapture(
  BuildContext context,
  Capture capture,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('저장한 구절을 삭제할까요?'),
        content: const Text(
          '이 구절과 이 구절에 달린 코멘트가 함께 삭제됩니다.\n\n'
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
  if (!context.mounted) return;

  try {
    await ref.read(captureRepositoryProvider).deleteCapture(
          bookId: capture.bookId,
          captureId: capture.id,
          hadComment: capture.comment.trim().isNotEmpty,
        );

    ref.invalidate(booksProvider());
    ref.invalidate(bookProvider(capture.bookId));
    ref.invalidate(bookCapturesProvider(bookId: capture.bookId));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('구절을 삭제했어요.')),
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('구절 삭제 중 오류가 발생했어요: $e')),
    );
  }
}

  Future<void> _deleteCaptureComments(
    DocumentReference<Map<String, dynamic>> captureRef,
  ) async {
    const int batchSize = 300;

    while (true) {
      final commentsSnapshot =
          await captureRef.collection('comments').limit(batchSize).get();

      if (commentsSnapshot.docs.isEmpty) {
        break;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }

      await batch.commit();

      if (commentsSnapshot.docs.length < batchSize) {
        break;
      }
    }
  }

  List<Capture> _applyFilterAndSort(List<Capture> captures) {
    final filtered = captures.where((capture) {
      switch (_visibilityFilter) {
        case _CaptureVisibilityFilter.all:
          return true;
        case _CaptureVisibilityFilter.publicOnly:
          return capture.isPublic;
        case _CaptureVisibilityFilter.privateOnly:
          return !capture.isPublic;
      }
    }).toList();

    switch (_sortType) {
      case _CaptureSortType.newestFirst:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _CaptureSortType.oldestFirst:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    final capturesAsync = ref.watch(
      bookCapturesProvider(bookId: book.bookId),
    );

    return capturesAsync.when(
      loading: () => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _BookInfoCard(
                    book: book,
                    captureCount: book.captureCount,
                    commentCount: 0,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          _AddCaptureBottom(
            onPressed: () => _goToCaptureMethod(context, book),
          ),
        ],
      ),
      error: (_, _) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _BookInfoCard(
                    book: book,
                    captureCount: book.captureCount,
                    commentCount: 0,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _CaptureErrorCard(),
                ],
              ),
            ),
          ),
          _AddCaptureBottom(
            onPressed: () => _goToCaptureMethod(context, book),
          ),
        ],
      ),
      data: (captures) {
        final visibleCaptures = _applyFilterAndSort(captures);

        final legacyCommentCount = captures
            .where((capture) => capture.comment.trim().isNotEmpty)
            .length;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _BookInfoCard(
                      book: book,
                      captureCount: captures.length,
                      commentCount: legacyCommentCount,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '저장한 구절',
                            style: AppTextStyles.title,
                          ),
                        ),
                        Text(
                          _visibilityFilter == _CaptureVisibilityFilter.all
                              ? '${captures.length}개'
                              : '${visibleCaptures.length}개 / 전체 ${captures.length}개',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CaptureFilterPanel(
                      visibilityFilter: _visibilityFilter,
                      sortType: _sortType,
                      onVisibilityChanged: (filter) {
                        setState(() {
                          _visibilityFilter = filter;
                        });
                      },
                      onSortChanged: (sortType) {
                        setState(() {
                          _sortType = sortType;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (captures.isEmpty)
                      const _CaptureEmptyCard()
                    else if (visibleCaptures.isEmpty)
                      const _CaptureFilteredEmptyCard()
                    else
                      _CaptureList(
                        captures: visibleCaptures,
                        onEdit: (capture) => _goToCaptureEdit(
                          context,
                          capture,
                        ),
                        onDelete: (capture) => _deleteCapture(
                          context,
                          capture,
                        ),
                        onAddComment: (capture) => _goToAddComment(
                          context,
                          capture,
                        ),
                        onEditComment: (capture, comment) =>
                            _goToEditComment(
                          context,
                          capture,
                          comment,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            _AddCaptureBottom(
              onPressed: () => _goToCaptureMethod(context, book),
            ),
          ],
        );
      },
    );
  }

  void _goToCaptureMethod(BuildContext context, Book book) {
    context.push(
      AppRoutes.captureMethod,
      extra: (
        bookId: book.bookId,
        bookTitle: book.title,
        bookAuthor: book.author,
        bookPublisher: book.publisher,
        bookCoverUrl: book.coverUrl,
      ),
    );
  }

  void _goToCaptureEdit(BuildContext context, Capture capture) {
    context.push(AppRoutes.captureEdit, extra: capture);
  }

  void _goToAddComment(BuildContext context, Capture capture) {
    context.push(AppRoutes.captureCommentAdd, extra: capture);
  }

  void _goToEditComment(
    BuildContext context,
    Capture capture,
    CaptureComment comment,
  ) {
    context.push(
      AppRoutes.captureCommentEdit,
      extra: (capture: capture, comment: comment),
    );
  }
}

class _CaptureFilterPanel extends StatelessWidget {
  const _CaptureFilterPanel({
    required this.visibilityFilter,
    required this.sortType,
    required this.onVisibilityChanged,
    required this.onSortChanged,
  });

  final _CaptureVisibilityFilter visibilityFilter;
  final _CaptureSortType sortType;
  final ValueChanged<_CaptureVisibilityFilter> onVisibilityChanged;
  final ValueChanged<_CaptureSortType> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                '필터',
                style: AppTextStyles.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: '전체',
                  selected: visibilityFilter == _CaptureVisibilityFilter.all,
                  onTap: () => onVisibilityChanged(
                    _CaptureVisibilityFilter.all,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipButton(
                  label: '공개',
                  selected:
                      visibilityFilter == _CaptureVisibilityFilter.publicOnly,
                  onTap: () => onVisibilityChanged(
                    _CaptureVisibilityFilter.publicOnly,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipButton(
                  label: '비공개',
                  selected:
                      visibilityFilter == _CaptureVisibilityFilter.privateOnly,
                  onTap: () => onVisibilityChanged(
                    _CaptureVisibilityFilter.privateOnly,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: '최신순',
                  selected: sortType == _CaptureSortType.newestFirst,
                  onTap: () => onSortChanged(
                    _CaptureSortType.newestFirst,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterChipButton(
                  label: '오래된순',
                  selected: sortType == _CaptureSortType.oldestFirst,
                  onTap: () => onSortChanged(
                    _CaptureSortType.oldestFirst,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
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
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({
    required this.book,
    required this.captureCount,
    required this.commentCount,
  });

  final Book book;
  final int captureCount;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final publisherText = [
      if (book.author.isNotEmpty) book.author,
      if (book.publisher.isNotEmpty) book.publisher,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailCover(url: book.coverUrl),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                if (publisherText.isNotEmpty)
                  Text(publisherText, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _InfoCountItem(
                        label: '저장한 구절',
                        value: '$captureCount개',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.outline,
                    ),
                    Expanded(
                      child: _InfoCountItem(
                        label: '기존 코멘트',
                        value: '$commentCount개',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCountItem extends StatelessWidget {
  const _InfoCountItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}

class _CaptureList extends StatelessWidget {
  const _CaptureList({
    required this.captures,
    required this.onEdit,
    required this.onDelete,
    required this.onAddComment,
    required this.onEditComment,
  });

  final List<Capture> captures;
  final ValueChanged<Capture> onEdit;
  final ValueChanged<Capture> onDelete;
  final ValueChanged<Capture> onAddComment;
  final void Function(Capture capture, CaptureComment comment) onEditComment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: captures
          .map(
            (capture) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CaptureCard(
                capture: capture,
                onEdit: () => onEdit(capture),
                onDelete: () => onDelete(capture),
                onAddComment: () => onAddComment(capture),
                onEditComment: (comment) => onEditComment(capture, comment),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CaptureCard extends StatefulWidget {
  const _CaptureCard({
    required this.capture,
    required this.onEdit,
    required this.onDelete,
    required this.onAddComment,
    required this.onEditComment,
  });

  final Capture capture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddComment;
  final ValueChanged<CaptureComment> onEditComment;

  @override
  State<_CaptureCard> createState() => _CaptureCardState();
}

class _CaptureCardState extends State<_CaptureCard> {
  bool _isCommentsExpanded = false;

  Stream<List<CaptureComment>> _commentsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(widget.capture.bookId)
        .collection('captures')
        .doc(widget.capture.id)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(CaptureComment.fromFirestore)
          .where((comment) => comment.text.trim().isNotEmpty)
          .toList();
    });
  }

  Future<void> _deleteComment(CaptureComment comment) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('코멘트를 삭제할까요?'),
          content: const Text(
            '선택한 코멘트가 삭제됩니다.\n삭제 후에는 되돌릴 수 없어요.',
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

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(widget.capture.bookId)
          .collection('captures')
          .doc(widget.capture.id)
          .collection('comments')
          .doc(comment.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 삭제했어요.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코멘트 삭제 중 오류가 발생했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = widget.capture;

    final pageText =
        capture.pageNumber == null ? '' : 'p.${capture.pageNumber} · ';

    final visibilityText = capture.isPublic ? '공개' : '비공개';
    final visibilityIcon =
        capture.isPublic ? Icons.language_rounded : Icons.lock_outline_rounded;

    final createdDateText = _formatDateTime(capture.createdAt);
    final legacyComment = capture.comment.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      visibilityIcon,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      visibilityText,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<_CaptureMenuAction>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _CaptureMenuAction.edit:
                      widget.onEdit();
                      break;
                    case _CaptureMenuAction.delete:
                      widget.onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: _CaptureMenuAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          SizedBox(width: AppSpacing.sm),
                          Text('구절 편집'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _CaptureMenuAction.delete,
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '구절 삭제',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  capture.quote,
                  style: AppTextStyles.body.copyWith(
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '$pageText$createdDateText에 저장',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '코멘트',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              TextButton.icon(
                onPressed: widget.onAddComment,
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text('추가'),
              ),
            ],
          ),
          StreamBuilder<List<CaptureComment>>(
            stream: _commentsStream(),
            builder: (context, snapshot) {
              final firestoreComments = snapshot.data ?? [];

              final displayComments = <_DisplayComment>[
                if (legacyComment.isNotEmpty)
                  _DisplayComment.legacy(
                    id: 'legacy-${capture.id}',
                    text: legacyComment,
                    createdAt: capture.createdAt,
                  ),
                ...firestoreComments.map(
                  (comment) => _DisplayComment.firestore(comment),
                ),
              ];

              if (snapshot.connectionState == ConnectionState.waiting &&
                  displayComments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '코멘트를 불러오는 중이에요.',
                    style: AppTextStyles.caption,
                  ),
                );
              }

              if (displayComments.isEmpty) {
                return _EmptyCommentHint(onAdd: widget.onAddComment);
              }

              final visibleComments = _isCommentsExpanded
                  ? displayComments
                  : displayComments.take(2).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...visibleComments.map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CommentBox(
                        comment: comment,
                        onEdit: comment.firestoreComment == null
                            ? null
                            : () => widget.onEditComment(
                                  comment.firestoreComment!,
                                ),
                        onDelete: comment.firestoreComment == null
                            ? null
                            : () => _deleteComment(
                                  comment.firestoreComment!,
                                ),
                      ),
                    ),
                  ),
                  if (displayComments.length > 2)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isCommentsExpanded = !_isCommentsExpanded;
                          });
                        },
                        icon: Icon(
                          _isCommentsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _isCommentsExpanded
                              ? '코멘트 접기'
                              : '코멘트 더보기 (${displayComments.length - 2}개)',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

enum _CaptureMenuAction {
  edit,
  delete,
}

class _DisplayComment {
  const _DisplayComment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isLegacy,
    this.firestoreComment,
  });

  factory _DisplayComment.legacy({
    required String id,
    required String text,
    required DateTime createdAt,
  }) {
    return _DisplayComment(
      id: id,
      text: text,
      createdAt: createdAt,
      isLegacy: true,
    );
  }

  factory _DisplayComment.firestore(CaptureComment comment) {
    return _DisplayComment(
      id: comment.id,
      text: comment.text,
      createdAt: comment.createdAt,
      isLegacy: false,
      firestoreComment: comment,
    );
  }

  final String id;
  final String text;
  final DateTime createdAt;
  final bool isLegacy;
  final CaptureComment? firestoreComment;
}

class _CommentBox extends StatelessWidget {
  const _CommentBox({
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final _DisplayComment comment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final updatedAt = comment.firestoreComment?.updatedAt;
    final timeText = updatedAt == null
        ? _formatDateTime(comment.createdAt)
        : '${_formatDateTime(updatedAt)} 수정됨';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              comment.isLegacy
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.mode_comment_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.isLegacy ? '첫 코멘트' : '코멘트',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),

                    // 첫 코멘트는 구절 편집에서 관리하므로 개별 편집 메뉴 없음.
                    // 새로 추가한 코멘트에만 수정/삭제 메뉴 표시.
                    if (!comment.isLegacy)
                      PopupMenuButton<_CommentMenuAction>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        onSelected: (action) {
                          switch (action) {
                            case _CommentMenuAction.edit:
                              onEdit?.call();
                              break;
                            case _CommentMenuAction.delete:
                              onDelete?.call();
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          return const [
                            PopupMenuItem(
                              value: _CommentMenuAction.edit,
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded),
                                  SizedBox(width: AppSpacing.sm),
                                  Text('수정'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: _CommentMenuAction.delete,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  comment.text,
                  style: AppTextStyles.body.copyWith(
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  timeText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CommentMenuAction {
  edit,
  delete,
}

class _EmptyCommentHint extends StatelessWidget {
  const _EmptyCommentHint({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.mdRadius,
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_comment_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '이 구절에 코멘트를 추가해보세요.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureEmptyCard extends StatelessWidget {
  const _CaptureEmptyCard();

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
      child: const Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text('아직 저장된 구절이 없어요', style: AppTextStyles.bodyStrong),
          SizedBox(height: AppSpacing.xs),
          Text(
            '문장을 추가해 기록을 시작해보세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CaptureFilteredEmptyCard extends StatelessWidget {
  const _CaptureFilteredEmptyCard();

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
      child: const Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text('조건에 맞는 구절이 없어요', style: AppTextStyles.bodyStrong),
          SizedBox(height: AppSpacing.xs),
          Text(
            '필터를 변경해서 다시 확인해보세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CaptureErrorCard extends StatelessWidget {
  const _CaptureErrorCard();

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
      child: const Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text('저장한 구절을 불러오지 못했습니다', style: AppTextStyles.bodyStrong),
          SizedBox(height: AppSpacing.xs),
          Text(
            '잠시 후 다시 시도해주세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _AddCaptureBottom extends StatelessWidget {
  const _AddCaptureBottom({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.md,
          AppSpacing.screenHorizontal,
          AppSpacing.md,
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: const Text('문장 추가'),
        ),
      ),
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.url});

  final String url;

  static const double _width = 80;
  static const double _height = 112;

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
              placeholder: (context, _) {
                return const _CoverPlaceholder(width: _width, height: _height);
              },
              errorWidget: (context, _, _) {
                return const _CoverPlaceholder(width: _width, height: _height);
              },
            ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$year.$month.$day $hour:$minute';
}