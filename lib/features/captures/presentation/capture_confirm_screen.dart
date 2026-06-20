import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/capture.dart';
import '../domain/capture_providers.dart';

class CaptureConfirmScreen extends ConsumerStatefulWidget {
  const CaptureConfirmScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    this.bookCoverUrl,
    this.initialQuote = '',
    this.initialPageNumber,
    this.initialComment = '',
    this.source = CaptureSource.manual,
    this.ocrRawText,
  });

  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String? bookCoverUrl;

  final String initialQuote;
  final int? initialPageNumber;
  final String initialComment;

  final CaptureSource source;
  final String? ocrRawText;

  @override
  ConsumerState<CaptureConfirmScreen> createState() =>
      _CaptureConfirmScreenState();
}

class _CaptureConfirmScreenState extends ConsumerState<CaptureConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _quoteController;
  late final TextEditingController _pageController;
  late final TextEditingController _commentController;

  bool _isPublic = false;

  @override
  void initState() {
    super.initState();

    _quoteController = TextEditingController(text: widget.initialQuote);
    _pageController = TextEditingController(
      text: widget.initialPageNumber?.toString() ?? '',
    );
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  int? _parsePageNumber() {
    final text = _pageController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    return int.tryParse(text);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    final pageNumber = _parsePageNumber();

    await ref.read(captureActionProvider.notifier).addCapture(
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
          quote: _quoteController.text.trim(),
          comment: _commentController.text.trim(),
          pageNumber: pageNumber,
          isPublic: _isPublic,
          source: widget.source,
          ocrRawText: widget.ocrRawText,
        );

    if (!mounted) return;

    final actionState = ref.read(captureActionProvider);

    actionState.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문장이 저장되었어요.')),
        );

        context.pop(true);
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했어요: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(captureActionProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('문장 수정 / 확인'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            children: [
              const Text(
                '선택한 문장을 확인하고 수정해주세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xl),

              _BookCard(
                title: widget.bookTitle,
                author: widget.bookAuthor,
                publisher: widget.bookPublisher,
                coverUrl: widget.bookCoverUrl,
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text('선택한 문장', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _quoteController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '저장할 문장을 입력해주세요.',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return '문장을 입력해주세요.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text('페이지 번호', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '페이지 번호를 입력해주세요.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return null;
                  }

                  if (int.tryParse(text) == null) {
                    return '숫자만 입력해주세요.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '숫자만 입력',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text('코멘트', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '이 문장에 대한 생각을 남겨보세요.',
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text('다른 독자에게 공개', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              _PublicToggle(
                isPublic: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isPublic
                    ? '공개로 저장하면 트렌드의 공개 구절 피드에 활용될 수 있어요.'
                    : '비공개로 저장하면 나만 볼 수 있어요.',
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: AppSpacing.xxl),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.pop();
                            },
                      child: Text(
                        widget.source == CaptureSource.manual
                            ? '이전으로'
                            : '다른 사진 선택',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading ? null : _save,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('저장하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdRadius,
              child: Container(
                width: 86,
                height: 118,
                color: AppColors.surfaceVariant,
                child: coverUrl == null || coverUrl!.isEmpty
                    ? const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 36,
                      )
                    : Image.network(
                        coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 36,
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$author · $publisher',
                    style: AppTextStyles.body,
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

class _PublicToggle extends StatelessWidget {
  const _PublicToggle({
    required this.isPublic,
    required this.onChanged,
  });

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleItem(
              selected: !isPublic,
              icon: Icons.lock_outline_rounded,
              label: '비공개',
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleItem(
              selected: isPublic,
              icon: Icons.language_rounded,
              label: '공개',
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.onPrimary : AppColors.textPrimary;

    return InkWell(
      borderRadius: AppRadius.mdRadius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}