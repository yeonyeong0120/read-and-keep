import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/book.dart';
import '../domain/book_providers.dart';

/// BK-004 책 상세 화면.
///
/// 단일 책([bookProvider])을 구독해 책 정보와 저장한 구절(현재 empty)을 보여준다.
/// 구절·코멘트 연동은 CP feature 구현 후 연결한다.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookProvider(bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('책 상세')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('책을 불러오지 못했습니다', style: AppTextStyles.body),
        ),
        data: (book) => _DetailBody(book: book),
      ),
    );
  }
}

/// 책 정보 + 저장한 구절(empty) + 하단 CTA.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _BookInfoCard(book: book),
                const SizedBox(height: AppSpacing.xl),
                const Text('저장한 구절', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                const _CaptureEmptyCard(),
                // TODO(CP): 구절 리스트 및 코멘트 영역 연결.
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        _AddCaptureBottom(
          onPressed: () {
            // TODO(CP-001): 현재 책이 선택된 상태로 문장 추가 화면으로 라우팅.
          },
        ),
      ],
    );
  }
}

/// 책 표지 + 제목/저자/출판사 + 구절 수 카운터.
class _BookInfoCard extends StatelessWidget {
  const _BookInfoCard({required this.book});

  final Book book;

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
                Text(
                  '저장한 구절 ${book.captureCount}개',
                  style: AppTextStyles.bodyStrong,
                ),
                // TODO(CP): 코멘트 수·최근 기록 카운터 연결.
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 저장한 구절 empty 상태 카드.
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

/// 하단 고정 "문장 추가" 버튼.
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

/// 상세 화면용 큰 표지.
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
      color: AppColors.surface,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }
}
