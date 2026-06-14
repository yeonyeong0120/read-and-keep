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
/// 이번 단계의 실데이터는 인사말 닉네임뿐이다. 책장·최근 문장은
/// 책(BK)/구절(CP) feature 미구현 상태이므로 empty/placeholder 로 둔다.
/// AppBar 없이 본문 최상단에 인사 영역을 직접 배치한다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                onAction: () => context.go(AppRoutes.bookshelf),
              ),
              const SizedBox(height: AppSpacing.md),
              const _BookshelfSection(),
              const SizedBox(height: AppSpacing.xl),
              const _SectionHeader('최근 저장한 문장'),
              const SizedBox(height: AppSpacing.md),
              const _RecentCaptureEmptyCard(),
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

    // AsyncValue 를 when 으로 처리한다. 수동 로딩 플래그는 쓰지 않는다.
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
              // PNG 처럼 두 줄로 표시하고, 둘째 줄 끝에 장식용 손 흔드는 이모지를 둔다.
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
        // PNG 의 우측 프로필은 원형 테두리 없이 아이콘만 노출된다.
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

/// 책장 섹션. booksProvider 를 구독해 0권이면 empty, 1권 이상이면
/// 최근 활동순 상위 3권을 가로 스크롤 카드로 보여준다.
class _BookshelfSection extends ConsumerWidget {
  const _BookshelfSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider());

    return booksAsync.when(
      // 로딩 중에는 카드 높이만큼 빈 공간을 둬 레이아웃 점프를 막는다.
      loading: () => const SizedBox(height: 220),
      // 에러 시에는 empty 카드로 폴백한다.
      error: (_, _) => const _BookshelfEmptyCard(),
      data: (books) {
        if (books.isEmpty) return const _BookshelfEmptyCard();
        // booksProvider() 기본 정렬이 최근 활동순이므로 상위 3권을 취한다.
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
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: books.length,
        separatorBuilder: (context, _) =>
            const SizedBox(width: AppSpacing.md),
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

/// 가로 스크롤용 책 카드(표지 위, 제목·저자·최근 기록 아래).
class _HomeBookCard extends StatelessWidget {
  const _HomeBookCard({required this.book, required this.onTap});

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
            BookCover(url: book.coverUrl, width: 104, height: 148, iconSize: 32),
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

/// 책장 empty 상태 카드. 강조 섹션 톤(surfaceVariant)으로 구분한다.
class _BookshelfEmptyCard extends StatelessWidget {
  const _BookshelfEmptyCard();

  @override
  Widget build(BuildContext context) {
    // TODO(STEP 6-C): 책 데이터 연동 시 가로 스크롤 책 카드 목록으로 대체.
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

/// 최근 저장한 문장 empty 상태 카드. 흰색(surface) + 테두리(outline)로 구분한다.
class _RecentCaptureEmptyCard extends StatelessWidget {
  const _RecentCaptureEmptyCard();

  @override
  Widget build(BuildContext context) {
    // TODO(STEP 6-C): 최근 구절 1건을 연동해 카드로 표시.
    // PNG 의 실제 카드(좌측 책 썸네일 + 우측 책제목·페이지·구절·N일 전) 골격을
    // empty 상태에서도 동일하게 유지한다.
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
          // 좌측 아이콘 영역(책 썸네일 자리).
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
          // 우측 텍스트 영역.
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

/// 오늘의 문장 카드. cold start 카피만 표시(일러스트 생략).
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

/// 문장 추가 진입 안내. CTA 바로 위의 보조 안내 문구.
class _AddCaptureHint extends StatelessWidget {
  const _AddCaptureHint();

  @override
  Widget build(BuildContext context) {
    // PNG 처럼 좌측 정렬한다.
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
