import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/capture.dart';
import '../data/models/capture_comment.dart';

class CaptureCommentAddScreen extends StatefulWidget {
  const CaptureCommentAddScreen({
    super.key,
    required this.capture,
  });

  final Capture capture;

  @override
  State<CaptureCommentAddScreen> createState() =>
      _CaptureCommentAddScreenState();
}

class _CaptureCommentAddScreenState extends State<CaptureCommentAddScreen> {
  final TextEditingController _commentController = TextEditingController();

  bool _isSaving = false;

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
          .doc();

      final comment = CaptureComment(
        id: commentRef.id,
        userId: user.uid,
        text: text,
        createdAt: DateTime.now(),
      );

      await commentRef.set(comment.toFirestoreOnCreate());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코멘트를 추가했어요.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코멘트 추가 중 오류가 발생했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('코멘트 추가'),
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
                          '이 구절에 코멘트를 남겨보세요.',
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
                      hintText: '이 문장에 대한 생각을 적어주세요.',
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
                            '코멘트는 구절 아래에 새로운 박스로 추가됩니다. 여러 번 추가하면 코멘트 박스가 아래로 계속 쌓여요.',
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
                        : const Icon(Icons.add_rounded),
                    label: Text(_isSaving ? '저장 중...' : '코멘트 추가'),
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