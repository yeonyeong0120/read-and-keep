import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/data/models/book.dart';
import '../../books/domain/book_providers.dart';
import '../../books/presentation/widgets/book_cover.dart';

/// CP-001 문장 추가 방법 선택 화면.
///
/// 선택한 책([bookProvider])을 기준으로 카메라/갤러리/직접입력 중 한 가지
/// 추가 방법을 고른다. 직접입력은 [CaptureEditScreen]으로, 카메라·갤러리는
/// OCR 경로(8-C/8-D)로 연결될 예정이다. 화면설계서 2.2에 따라 본 화면은
/// 탭바를 노출한다(홈 브랜치 중첩 라우트).
class CaptureMethodScreen extends ConsumerWidget {
  const CaptureMethodScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookProvider(bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('문장 추가')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('책을 불러오지 못했습니다', style: AppTextStyles.body),
        ),
        data: (book) => _MethodBody(bookId: bookId, book: book),
      ),
    );
  }
}

/// 부연 안내 + 책 정보 카드 + 옵션 3개 + 촬영 팁.
class _MethodBody extends StatelessWidget {
  const _MethodBody({required this.bookId, required this.book});

  final String bookId;
  final Book book;

  /// 직접 입력 경로로 이동한다.
  void _goManual(BuildContext context) {
    context.push(AppRoutes.captureEditOf(bookId, 'manual'));
  }

  /// 준비 중 기능 안내 스낵바를 띄운다.
  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
      ),
      children: [
        const Text(
          '문장을 추가할 방법을 선택해주세요',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        _BookInfoCard(book: book),
        const SizedBox(height: AppSpacing.xl),
        _MethodCard(
          icon: Icons.photo_camera_outlined,
          title: '카메라로 촬영하기',
          description: '책 페이지를 직접 촬영해 문장을 인식해요',
          onPressed: () {
            // TODO(8-D): 카메라 OCR 경로 연결.
            _showComingSoon(context, '카메라 기능은 준비 중입니다');
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _MethodCard(
          icon: Icons.photo_library_outlined,
          title: '갤러리에서 선택하기',
          description: '저장된 책 페이지 사진에서 문장을 인식해요',
          onPressed: () {
            // TODO(8-C): 갤러리 OCR 경로 연결.
            _showComingSoon(context, '갤러리 기능은 준비 중입니다');
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _MethodCard(
          icon: Icons.edit_outlined,
          title: '직접 입력하기',
          description: '문장을 직접 입력해 저장할 수 있어요',
          onPressed: () => _goManual(context),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _GuideBox(),
      ],
    );
  }
}

/// 책 표지 + 제목/저자·출판사 + "책 변경" 버튼.
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
          BookCover(url: book.coverUrl),
          const SizedBox(width: AppSpacing.lg),
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
                if (publisherText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    publisherText,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.bookSelect),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: AppTextStyles.caption,
                    ),
                    child: const Text('책 변경'),
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

/// 추가 방법 옵션 카드(아이콘 + 제목 + 설명 + 화살표). 탭 가능.
class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.lgRadius,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description, style: AppTextStyles.caption),
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

/// 하단 촬영 팁 안내 박스.
class _GuideBox extends StatelessWidget {
  const _GuideBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: AppColors.warning,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('촬영 팁', style: AppTextStyles.bodyStrong),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '책 페이지가 흔들리지 않게 촬영해주세요',
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
