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
import '../../auth/domain/auth_providers.dart';
import '../../books/data/models/book.dart';
import '../../books/domain/book_providers.dart';
import '../../books/presentation/widgets/book_cover.dart';
import '../../books/presentation/widgets/book_relative_time.dart';

/// 홈 화면 (MN-001).
///
/// 홈에서 내 책장 전체보기로 바로 이동할 수 있게 연결한다.
/// 최근 저장한 문장도 Firestore에서 실제 데이터로 표시한다.
/// 문장 추가는 기존처럼 책 선택 화면으로 이동한다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goToBookshelfOverview(BuildContext context) {
    context.push(AppRoutes.bookshelf);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const _GreetingHeader(),
              const SizedBox(height: AppSpacing.xl),

              _SectionHeader(
                '내 책장',
                actionLabel: '전체보기 >',
                onAction: () => _goToBookshelfOverview(context),
              ),

              const SizedBox(height: AppSpacing.md),
              const _BookshelfSection(),

              const SizedBox(height: AppSpacing.xl),
              const _SectionHeader('최근 저장한 문장'),
              const SizedBox(height: AppSpacing.md),
              const _RecentCaptureSection(),

              const SizedBox(height: AppSpacing.xl),
              const _SectionHeader('오늘의 문장'),
              const SizedBox(height: AppSpacing.md),
              const _TodayQuoteCard(),

              const SizedBox(height: AppSpacing.xl),
              const _AddCaptureHint(),
              const SizedBox(height: AppSpacing.md),

              _AddCaptureButton(
                onPressed: () => context.go(AppRoutes.bookSelect),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인사 영역. 닉네임만 실데이터([currentAppUserProvider])로 표시한다.
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);

    final nickname = userAsync.when(
      data: (user) {
        final name = user?.nickname ?? '';
        return name.isEmpty ? '독자' : name;
      },
      loading: () => '...',
      error: (_, _) => '독자',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요,\n$nickname님 👋', style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                '오늘도 좋은 문장을 기록해보세요.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          onPressed: () {
            // TODO(MY-001): 마이페이지로 라우팅.
          },
          icon: const Icon(Icons.person_outline_rounded),
          color: AppColors.textPrimary,
          iconSize: 28,
        ),
      ],
    );
  }
}

/// 섹션 헤더. 우측 액션(전체보기 등)은 선택적으로 노출한다.
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

/// 책장 섹션. booksProvider 를 구독해 0권이면 empty,
/// 1권 이상이면 최근 활동순 상위 3권을 가로 스크롤 카드로 보여준다.
class _BookshelfSection extends ConsumerWidget {
  const _BookshelfSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider());

    return booksAsync.when(
      loading: () => const SizedBox(height: 224),
      error: (_, _) => const _BookshelfEmptyCard(),
      data: (books) {
        if (books.isEmpty) return const _BookshelfEmptyCard();

        final top = books.take(3).toList();

        return _BookshelfHorizontalList(books: top);
      },
    );
  }
}

/// 가로 스크롤 책 카드 목록.
class _BookshelfHorizontalList extends StatelessWidget {
  const _BookshelfHorizontalList({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: books.length,
        separatorBuilder: (context, _) {
          return const SizedBox(width: AppSpacing.md);
        },
        itemBuilder: (context, index) {
          final book = books[index];

          return _HomeBookCard(
            book: book,
            onTap: () => context.go(AppRoutes.bookDetailOf(book.bookId)),
          );
        },
      ),
    );
  }
}

/// 가로 스크롤용 책 카드.
class _HomeBookCard extends StatelessWidget {
  const _HomeBookCard({
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recordTime = book.lastCapturedAt ?? book.lastSelectedAt;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              url: book.coverUrl,
              width: 104,
              height: 148,
              iconSize: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
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
              '최근 기록 ${bookRelativeTime(recordTime)}',
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 최근 저장한 문장 섹션.
/// 현재 사용자의 책 목록을 기준으로 각 책의 captures 중 최신 1건을 찾아 가장 최근 구절을 보여준다.
class _RecentCaptureSection extends ConsumerWidget {
  const _RecentCaptureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider());

    return booksAsync.when(
      loading: () => const _RecentCaptureLoadingCard(),
      error: (_, _) => const _RecentCaptureEmptyCard(),
      data: (books) {
        if (books.isEmpty) {
          return const _RecentCaptureEmptyCard();
        }

        return FutureBuilder<_RecentCaptureSummary?>(
          future: _loadRecentCapture(books),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _RecentCaptureLoadingCard();
            }

            if (snapshot.hasError) {
              return const _RecentCaptureEmptyCard();
            }

            final recent = snapshot.data;

            if (recent == null) {
              return const _RecentCaptureEmptyCard();
            }

            return _RecentCaptureCard(summary: recent);
          },
        );
      },
    );
  }

  Future<_RecentCaptureSummary?> _loadRecentCapture(List<Book> books) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    _RecentCaptureSummary? latest;

    final firestore = FirebaseFirestore.instance;

    for (final book in books) {
      final bookRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(book.bookId);

      QuerySnapshot<Map<String, dynamic>>? capturesSnapshot;

      try {
        capturesSnapshot = await bookRef
            .collection('captures')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
      } catch (_) {
        try {
          capturesSnapshot = await bookRef
              .collection('captures')
              .orderBy('capturedAt', descending: true)
              .limit(1)
              .get();
        } catch (_) {
          capturesSnapshot = await bookRef.collection('captures').limit(1).get();
        }
      }

      if (capturesSnapshot.docs.isEmpty) {
        continue;
      }

      final captureDoc = capturesSnapshot.docs.first;
      final data = captureDoc.data();

      final quote = _readString(data, ['quote', 'text']);
      final createdAt = _readDateTime(data, ['createdAt', 'capturedAt']);

      if (quote.trim().isEmpty || createdAt == null) {
        continue;
      }

      final summary = _RecentCaptureSummary(
        bookId: book.bookId,
        bookTitle: book.title,
        bookAuthor: book.author,
        bookCoverUrl: book.coverUrl,
        quote: quote.trim(),
        comment: _readString(data, ['comment']),
        pageNumber: _readInt(data, ['pageNumber']),
        createdAt: createdAt,
        isPublic: _readBool(data, ['isPublic']) ?? false,
      );

      if (latest == null || summary.createdAt.isAfter(latest.createdAt)) {
        latest = summary;
      }
    }

    return latest;
  }

  String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }
    }

    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is bool) {
        return value;
      }
    }

    return null;
  }

  DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }
    }

    return null;
  }
}

class _RecentCaptureSummary {
  const _RecentCaptureSummary({
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCoverUrl,
    required this.quote,
    required this.comment,
    required this.pageNumber,
    required this.createdAt,
    required this.isPublic,
  });

  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookCoverUrl;
  final String quote;
  final String comment;
  final int? pageNumber;
  final DateTime createdAt;
  final bool isPublic;
}

class _RecentCaptureCard extends StatelessWidget {
  const _RecentCaptureCard({
    required this.summary,
  });

  final _RecentCaptureSummary summary;

  void _goToBookDetail(BuildContext context) {
    context.push(AppRoutes.bookDetailOf(summary.bookId));
  }

  @override
  Widget build(BuildContext context) {
    final pageText =
        summary.pageNumber == null ? '' : 'p.${summary.pageNumber} · ';

    final visibilityText = summary.isPublic ? '공개' : '비공개';
    final visibilityIcon =
        summary.isPublic ? Icons.language_rounded : Icons.lock_outline_rounded;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () => _goToBookDetail(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                url: summary.bookCoverUrl,
                width: 56,
                height: 76,
                iconSize: 24,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.bookTitle,
                      style: AppTextStyles.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      summary.bookAuthor,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '“${summary.quote}”',
                      style: AppTextStyles.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$pageText${bookRelativeTime(summary.createdAt)} · $visibilityText',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          visibilityIcon,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    if (summary.comment.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '코멘트: ${summary.comment}',
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class _RecentCaptureLoadingCard extends StatelessWidget {
  const _RecentCaptureLoadingCard();

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
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '최근 저장한 문장을 불러오는 중이에요.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// 최근 저장한 문장 empty 상태 카드.
class _RecentCaptureEmptyCard extends StatelessWidget {
  const _RecentCaptureEmptyCard();

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('아직 저장한 문장이 없어요', style: AppTextStyles.bodyStrong),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '마음에 드는 문장을 저장하면 여기에 표시됩니다',
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

/// 책장 empty 상태 카드.
class _BookshelfEmptyCard extends StatelessWidget {
  const _BookshelfEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text('아직 등록된 책이 없어요', style: AppTextStyles.bodyStrong),
          SizedBox(height: AppSpacing.xs),
          Text(
            '책을 등록하고 문장을 기록해보세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// 오늘의 문장 카드.
class _TodayQuoteCard extends StatelessWidget {
  const _TodayQuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '읽는 순간 멈춘 문장이,\n나의 취향을 알려줍니다.',
            style: AppTextStyles.title,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '오늘도 한 문장을 남겨보세요.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// 문장 추가 진입 안내.
class _AddCaptureHint extends StatelessWidget {
  const _AddCaptureHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 16,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            '문장을 추가하려면 먼저 책을 선택해주세요',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

/// 주 CTA: 문장 추가 버튼.
class _AddCaptureButton extends StatelessWidget {
  const _AddCaptureButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded),
      label: const Text('문장 추가'),
    );
  }
}