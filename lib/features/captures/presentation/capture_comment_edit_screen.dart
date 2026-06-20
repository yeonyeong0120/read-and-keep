import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/capture.dart';
import '../data/models/capture_comment.dart';

class CaptureCommentEditScreen extends StatefulWidget {
  const CaptureCommentEditScreen({
    super.key,
    required this.capture,
    required this.comment,
  });

  final Capture capture;
  final CaptureComment comment;

  @override
  State<CaptureCommentEditScreen> createState() =>
      _CaptureCommentEditScreenState();
}

class _CaptureCommentEditScreenState extends State<CaptureCommentEditScreen> {
  late final TextEditingController _commentController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.comment.text);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 입력해주세요.')),
      );
      return;
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
      final commentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(widget.capture.bookId)
          .collection('captures')
          .doc(widget.capture.id)
          .collection('comments')
          .doc(widget.comment.id);

      await commentRef.update({
        'text': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 수정했어요.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코멘트 수정 중 오류가 발생했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('코멘트 수정'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이 구절에 남긴 코멘트를 수정해요.',
                          style: AppTextStyles.title,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          widget.capture.quote,
                          style: AppTextStyles.body.copyWith(
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('코멘트', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _commentController,
                    autofocus: true,
                    maxLines: 7,
                    minLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '코멘트를 입력해주세요.',
                      alignLabelWithHint: true,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            '수정하면 기존 코멘트 박스의 내용이 바뀌고, 수정 시간이 함께 기록됩니다.',
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
                    onPressed: _isSaving ? null : _saveComment,
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