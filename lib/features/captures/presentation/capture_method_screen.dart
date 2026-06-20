import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/capture.dart';

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

  void _goToManualInput(BuildContext context) {
    context.push(
      AppRoutes.captureConfirm,
      extra: (
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookPublisher: bookPublisher,
        bookCoverUrl: bookCoverUrl,
        initialQuote: '',
        initialPageNumber: null,
        initialComment: '',
        source: CaptureSource.manual,
        ocrRawText: null,
      ),
    );
  }

  /// 갤러리 진입. OS 사진 권한 상태를 진짜 기준으로 삼는다.
  ///
  /// - 이미 허용(또는 제한 허용) → 안내 생략하고 바로 OCR 화면 진입.
  /// - 미결정/거부 → 안내 다이얼로그 후 [Permission.request] 로 권한 요청 →
  ///   허용되면 바로 진입(추가 탭 불필요).
  /// - 영구 거부 → 설정으로 유도([openAppSettings]).
  ///
  /// Android 13+ 에서 [Permission.photos] 는 매니페스트에 선언된
  /// READ_MEDIA_IMAGES 를 기준으로 동작한다.
  Future<void> _goToGalleryOcr(BuildContext context) async {
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      if (!context.mounted) return;
      _pushGalleryOcr(context);
      return;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return;
      await _showSettingsGuide(
        context,
        title: '사진 접근 권한이 필요해요',
        message: '갤러리에서 사진을 선택하려면 설정에서 사진 권한을 허용해주세요.',
      );
      return;
    }

    if (!context.mounted) return;
    final accepted = await _showAccessGuide(
      context,
      title: '갤러리 접근 안내',
      message: '책 페이지 사진을 선택하기 위해 갤러리에 접근합니다.\n\n'
          '선택한 사진은 문장 인식에만 사용되며 서버에 업로드하지 않습니다.',
    );
    if (!accepted) return;

    final result = await Permission.photos.request();
    if (!context.mounted) return;

    if (result.isGranted || result.isLimited) {
      _pushGalleryOcr(context);
    } else if (result.isPermanentlyDenied) {
      await _showSettingsGuide(
        context,
        title: '사진 접근 권한이 필요해요',
        message: '갤러리에서 사진을 선택하려면 설정에서 사진 권한을 허용해주세요.',
      );
    }
    // 그 외 단순 거부는 조용히 종료한다(다시 시도 가능).
  }

  /// 카메라 진입.
  ///
  /// 카메라는 image_picker 가 시스템 카메라 인텐트(ACTION_IMAGE_CAPTURE)로
  /// 호출하므로, 앱이 보유하는 CAMERA 권한이 없다(매니페스트 미선언이 정상).
  /// 권한 처리는 시스템 카메라 앱이 직접 담당하므로 permission_handler 로
  /// 게이팅하지 않고 바로 OCR 화면으로 진입한다. 이로써 앱 재시작마다
  /// 안내 팝업이 다시 뜨던 문제가 사라진다.
  void _goToCameraOcr(BuildContext context) {
    _pushCameraOcr(context);
  }

  void _pushGalleryOcr(BuildContext context) {
    context.push(
      AppRoutes.galleryOcr,
      extra: (
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookPublisher: bookPublisher,
        bookCoverUrl: bookCoverUrl,
      ),
    );
  }

  void _pushCameraOcr(BuildContext context) {
    context.push(
      AppRoutes.cameraOcr,
      extra: (
        bookId: bookId,
        bookTitle: bookTitle,
        bookAuthor: bookAuthor,
        bookPublisher: bookPublisher,
        bookCoverUrl: bookCoverUrl,
      ),
    );
  }

  /// 권한 요청 전 사용자에게 사유를 안내한다. "동의하고 계속" 시 true.
  Future<bool> _showAccessGuide(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('동의하고 계속'),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }

  /// 영구 거부 상태 안내. "설정으로 이동" 시 앱 설정 화면을 연다.
  Future<void> _showSettingsGuide(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final goSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );

    if (goSettings == true) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('문장 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
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
                    onPressed: () => context.pop(),
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