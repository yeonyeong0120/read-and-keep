import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/capture.dart';
import 'camera_ocr_screen.dart';
import 'capture_confirm_screen.dart';
import 'gallery_ocr_screen.dart';

class CaptureMethodScreen extends StatelessWidget {
  const CaptureMethodScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    this.bookCoverUrl,
  });

  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String? bookCoverUrl;

  static bool _hasAcceptedGalleryGuide = false;
  static bool _hasAcceptedCameraGuide = false;

  void _goToManualInput(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaptureConfirmScreen(
          bookId: bookId,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          bookPublisher: bookPublisher,
          bookCoverUrl: bookCoverUrl,
          source: CaptureSource.manual,
        ),
      ),
    );
  }

  Future<void> _goToGalleryOcr(BuildContext context) async {
    final accepted = await _showGalleryGuideIfNeeded(context);

    if (!accepted) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryOcrScreen(
          bookId: bookId,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          bookPublisher: bookPublisher,
          bookCoverUrl: bookCoverUrl,
        ),
      ),
    );
  }

  Future<void> _goToCameraOcr(BuildContext context) async {
    final accepted = await _showCameraGuideIfNeeded(context);

    if (!accepted) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraOcrScreen(
          bookId: bookId,
          bookTitle: bookTitle,
          bookAuthor: bookAuthor,
          bookPublisher: bookPublisher,
          bookCoverUrl: bookCoverUrl,
        ),
      ),
    );
  }

  Future<bool> _showGalleryGuideIfNeeded(BuildContext context) async {
    if (_hasAcceptedGalleryGuide) {
      return true;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('갤러리 접근 안내'),
          content: const Text(
            '책 페이지 사진을 선택하기 위해 갤러리에 접근합니다.\n\n'
            '선택한 사진은 문장 인식에만 사용되며 서버에 업로드하지 않습니다.',
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
              child: const Text('동의하고 계속'),
            ),
          ],
        );
      },
    );

    if (accepted == true) {
      _hasAcceptedGalleryGuide = true;
      return true;
    }

    return false;
  }

  Future<bool> _showCameraGuideIfNeeded(BuildContext context) async {
    if (_hasAcceptedCameraGuide) {
      return true;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('카메라 접근 안내'),
          content: const Text(
            '책 문장을 촬영하기 위해 카메라에 접근합니다.\n\n'
            '촬영한 사진은 문장 인식에만 사용되며 서버에 업로드하지 않습니다.',
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
              child: const Text('동의하고 계속'),
            ),
          ],
        );
      },
    );

    if (accepted == true) {
      _hasAcceptedCameraGuide = true;
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('문장 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: AppSpacing.lg,
            bottom: AppSpacing.xl,
          ),
          children: [
            const Text(
              '문장을 추가할 방법을 선택해주세요.',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              '책에서 찾은 문장을 기록해보세요.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.xl),
            _SelectedBookCard(
              title: bookTitle,
              author: bookAuthor,
              publisher: bookPublisher,
              coverUrl: bookCoverUrl,
            ),
            const SizedBox(height: AppSpacing.xl),
            _MethodCard(
              icon: Icons.photo_camera_rounded,
              iconBackgroundColor: const Color(0xFFE9F2F5),
              title: '카메라로 촬영하기',
              description: '책의 문장을 직접 촬영해서 텍스트로 추출해요.',
              onTap: () => _goToCameraOcr(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _MethodCard(
              icon: Icons.image_rounded,
              iconBackgroundColor: const Color(0xFFE9F4EA),
              title: '갤러리에서 선택하기',
              description: '이미 저장된 사진을 선택해서 텍스트로 추출해요.',
              onTap: () => _goToGalleryOcr(context),
            ),
            const SizedBox(height: AppSpacing.md),
            _MethodCard(
              icon: Icons.edit_rounded,
              iconBackgroundColor: const Color(0xFFFFF0D6),
              title: '직접 입력하기',
              description: '문장을 직접 입력하고 저장할 수 있어요.',
              onTap: () => _goToManualInput(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.lgRadius,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '문장을 추가하려면 먼저 책을 선택해야 해요. 저장된 문장은 책 상세 화면에서 확인할 수 있어요.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedBookCard extends StatelessWidget {
  const _SelectedBookCard({
    required this.title,
    required this.author,
    required this.publisher,
    this.coverUrl,
  });

  final String title;
  final String author;
  final String publisher;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final metaText =
        publisher.trim().isEmpty ? author : '$author · $publisher';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdRadius,
              child: Container(
                width: 72,
                height: 96,
                color: AppColors.surfaceVariant,
                child: coverUrl == null || coverUrl!.isEmpty
                    ? const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 32,
                      )
                    : Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 32,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    metaText,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('책 변경'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
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