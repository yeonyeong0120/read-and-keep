import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/public_capture.dart';

class PublicCaptureDetailScreen extends StatefulWidget {
  const PublicCaptureDetailScreen({
    super.key,
    required this.capture,
  });

  final PublicCapture capture;

  @override
  State<PublicCaptureDetailScreen> createState() =>
      _PublicCaptureDetailScreenState();
}

class _PublicCaptureDetailScreenState extends State<PublicCaptureDetailScreen> {
  bool _isLikeProcessing = false;

  DocumentReference<Map<String, dynamic>> get _captureRef {
    return FirebaseFirestore.instance
        .collection('publicCaptures')
        .doc(widget.capture.id);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _captureStream() {
    return _captureRef.snapshots();
  }

  Stream<bool> _likedStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream<bool>.value(false);
    }

    return _captureRef
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<PublicCaptureComment>> _commentsStream() {
    return _captureRef
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(PublicCaptureComment.fromFirestore).toList();
    });
  }

  Future<void> _toggleLike() async {
    if (_isLikeProcessing) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isLikeProcessing = true;
    });

    final likeRef = _captureRef.collection('likes').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final likeSnapshot = await transaction.get(likeRef);
        final captureSnapshot = await transaction.get(_captureRef);

        if (!captureSnapshot.exists) {
          throw StateError('공개 구절이 존재하지 않습니다.');
        }

        final data = captureSnapshot.data() ?? {};
        final currentLikeCount = data['likeCount'] as int? ?? 0;

        if (likeSnapshot.exists) {
          transaction.delete(likeRef);
          transaction.update(_captureRef, {
            'likeCount': currentLikeCount > 0 ? currentLikeCount - 1 : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(likeRef, {
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(_captureRef, {
            'likeCount': currentLikeCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공감 처리 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeProcessing = false;
        });
      }
    }
  }

  void _openCommentWriteScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicCaptureCommentWriteScreen(
          captureId: widget.capture.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageText = widget.capture.pageNumber == null
        ? null
        : 'p.${widget.capture.pageNumber}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('공개 구절'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            _BookHeader(
              bookTitle: widget.capture.bookTitle,
              pageText: pageText,
              createdAt: widget.capture.createdAt,
            ),
            const SizedBox(height: AppSpacing.lg),
            _QuoteBox(quote: widget.capture.quote),
            if (widget.capture.comment.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _FirstCommentBox(comment: widget.capture.comment),
            ],
            const SizedBox(height: AppSpacing.lg),
            _ActionSection(
              capture: widget.capture,
              captureStream: _captureStream(),
              likedStream: _likedStream(),
              isLikeProcessing: _isLikeProcessing,
              onLikeTap: _toggleLike,
              onCommentTap: _openCommentWriteScreen,
            ),
            const SizedBox(height: AppSpacing.xl),
            _CommentListSection(
              capture: widget.capture,
              captureStream: _captureStream(),
              commentsStream: _commentsStream(),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicCaptureCommentWriteScreen extends StatefulWidget {
  const PublicCaptureCommentWriteScreen({
    super.key,
    required this.captureId,
  });

  final String captureId;

  @override
  State<PublicCaptureCommentWriteScreen> createState() =>
      _PublicCaptureCommentWriteScreenState();
}

class _PublicCaptureCommentWriteScreenState
    extends State<PublicCaptureCommentWriteScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isSending = false;

  DocumentReference<Map<String, dynamic>> get _captureRef {
    return FirebaseFirestore.instance
        .collection('publicCaptures')
        .doc(widget.captureId);
  }

  Future<void> _submit() async {
    if (_isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final commentRef = _captureRef.collection('comments').doc();

      final batch = FirebaseFirestore.instance.batch();

      batch.set(commentRef, {
        'userId': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      batch.update(_captureRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 작성 중 오류가 발생했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('댓글 작성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: TextField(
                controller: _controller,
                minLines: 6,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '이 구절에 대한 생각을 남겨보세요.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSending ? null : _submit,
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('댓글 등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublicCaptureComment {
  const PublicCaptureComment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PublicCaptureComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAtValue = data['createdAt'];
    final updatedAtValue = data['updatedAt'];

    return PublicCaptureComment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
      updatedAt: updatedAtValue is Timestamp ? updatedAtValue.toDate() : null,
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.capture,
    required this.captureStream,
    required this.likedStream,
    required this.isLikeProcessing,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  final PublicCapture capture;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> captureStream;
  final Stream<bool> likedStream;
  final bool isLikeProcessing;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: captureStream,
      builder: (context, captureSnapshot) {
        final data = captureSnapshot.data?.data();
        final likeCount = data?['likeCount'] as int? ?? capture.likeCount;
        final commentCount =
            data?['commentCount'] as int? ?? capture.commentCount;

        return StreamBuilder<bool>(
          stream: likedStream,
          initialData: false,
          builder: (context, likeSnapshot) {
            final liked = likeSnapshot.data ?? false;

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: isLikeProcessing ? '처리 중...' : '공감 $likeCount',
                      selected: liked,
                      enabled: !isLikeProcessing,
                      onTap: onLikeTap,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '댓글 $commentCount',
                      selected: false,
                      enabled: true,
                      onTap: onCommentTap,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CommentListSection extends StatelessWidget {
  const _CommentListSection({
    required this.capture,
    required this.captureStream,
    required this.commentsStream,
  });

  final PublicCapture capture;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> captureStream;
  final Stream<List<PublicCaptureComment>> commentsStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: captureStream,
      builder: (context, captureSnapshot) {
        final data = captureSnapshot.data?.data();
        final commentCount =
            data?['commentCount'] as int? ?? capture.commentCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '댓글 $commentCount',
              style: AppTextStyles.bodyStrong,
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<List<PublicCaptureComment>>(
              stream: commentsStream,
              builder: (context, commentSnapshot) {
                if (commentSnapshot.hasError) {
                  return _CommentErrorBox(error: commentSnapshot.error!);
                }

                if (commentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final comments = commentSnapshot.data ?? [];

                if (comments.isEmpty) {
                  return const _EmptyComments();
                }

                return Column(
                  children: comments.map((comment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CommentCard(comment: comment),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.red : AppColors.textPrimary;
    final disabledColor = AppColors.textSecondary;

    return InkWell(
      borderRadius: AppRadius.mdRadius,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.red.withOpacity(0.08) : AppColors.background,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? color : disabledColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: enabled ? color : disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({
    required this.bookTitle,
    required this.pageText,
    required this.createdAt,
  });

  final String bookTitle;
  final String? pageText;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (pageText != null) pageText!,
      _formatDateTime(createdAt),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookTitle, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(meta, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  const _QuoteBox({
    required this.quote,
  });

  final String quote;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            quote,
            style: AppTextStyles.title.copyWith(
              height: 1.55,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstCommentBox extends StatelessWidget {
  const _FirstCommentBox({
    required this.comment,
  });

  final String comment;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mode_comment_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              comment,
              style: AppTextStyles.body.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

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
      child: const Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.textSecondary,
            size: 30,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '아직 댓글이 없어요',
            style: AppTextStyles.bodyStrong,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '이 구절에 대한 생각을 남겨보세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
  });

  final PublicCaptureComment comment;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMine = user != null && user.uid == comment.userId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceVariant,
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMine ? '나' : '독자',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  comment.text,
                  style: AppTextStyles.body.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDateTime(comment.createdAt),
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

class _CommentErrorBox extends StatelessWidget {
  const _CommentErrorBox({
    required this.error,
  });

  final Object error;

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
      child: Text(
        '댓글을 불러오지 못했어요.\n$error',
        style: AppTextStyles.caption,
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$year.$month.$day $hour:$minute';
}