import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/domain/book_providers.dart';
import '../data/models/capture.dart';
import '../domain/capture_providers.dart';

class CaptureEditScreen extends ConsumerStatefulWidget {
  const CaptureEditScreen({
    super.key,
    required this.capture,
  });

  final Capture capture;

  @override
  ConsumerState<CaptureEditScreen> createState() => _CaptureEditScreenState();
}

class _CaptureEditScreenState extends ConsumerState<CaptureEditScreen> {
  late final TextEditingController _quoteController;
  late final TextEditingController _pageController;
  late final TextEditingController _commentController;

  late bool _isPublic;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _quoteController = TextEditingController(text: widget.capture.quote);
    _pageController = TextEditingController(
      text: widget.capture.pageNumber == null
          ? ''
          : widget.capture.pageNumber.toString(),
    );
    _commentController = TextEditingController(text: widget.capture.comment);
    _isPublic = widget.capture.isPublic;
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveCapture() async {
    final quote = _quoteController.text.trim();
    final comment = _commentController.text.trim();
    final pageText = _pageController.text.trim();

    if (quote.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문장을 입력해주세요.')),
      );
      return;
    }

    int? pageNumber;

    if (pageText.isNotEmpty) {
      pageNumber = int.tryParse(pageText);

      if (pageNumber == null || pageNumber <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지 번호는 1 이상의 숫자로 입력해주세요.')),
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(captureRepositoryProvider).updateCapture(
            capture: widget.capture,
            quote: quote,
            comment: comment,
            pageNumber: pageNumber,
            isPublic: _isPublic,
          );

      ref.invalidate(bookCapturesProvider(bookId: widget.capture.bookId));
      ref.invalidate(bookProvider(widget.capture.bookId));
      ref.invalidate(booksProvider());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구절을 수정했어요.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구절 수정 중 오류가 발생했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceText = switch (widget.capture.source) {
      CaptureSource.camera => '카메라로 저장한 문장',
      CaptureSource.gallery => '갤러리에서 저장한 문장',
      CaptureSource.manual => '직접 입력한 문장',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('구절 편집'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.capture.bookTitle,
                                style: AppTextStyles.bodyStrong,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                sourceText,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('문장', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _quoteController,
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '저장할 문장을 입력해주세요.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('페이지', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '예: 25',
                      prefixText: 'p. ',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('첫 코멘트', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    minLines: 2,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '이 문장에 대한 첫 생각을 남겨보세요.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lgRadius,
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPublic
                              ? Icons.language_rounded
                              : Icons.lock_outline_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPublic ? '공개 구절' : '비공개 구절',
                                style: AppTextStyles.bodyStrong,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _isPublic
                                    ? '공개 피드에 표시될 수 있어요.'
                                    : '나만 볼 수 있는 구절로 저장돼요.',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPublic,
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _isPublic = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
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
                    onPressed: _isSaving ? null : _saveCapture,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? '저장 중...' : '수정 완료'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}