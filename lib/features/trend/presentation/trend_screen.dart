import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/public_capture.dart';

final publicCapturesProvider =
    StreamProvider.autoDispose<List<PublicCapture>>((ref) {
  return FirebaseFirestore.instance
      .collection('publicCaptures')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map(PublicCapture.fromFirestore).toList();
  });
});

class TrendScreen extends ConsumerWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicCapturesAsync = ref.watch(publicCapturesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('트렌드'),
      ),
      body: publicCapturesAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) {
          return _TrendErrorView(error: error);
        },
        data: (captures) {
          if (captures.isEmpty) {
            return const _TrendEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(publicCapturesProvider);
            },
            child: ListView(
              padding: AppSpacing.screenPadding.copyWith(
                top: AppSpacing.lg,
                bottom: AppSpacing.xxl,
              ),
              children: [
                const _TrendHeader(),
                const SizedBox(height: AppSpacing.lg),
                ...captures.map(
                  (capture) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PublicCaptureCard(
                      capture: capture,
                      onOpen: () {
                        context.push(
                          AppRoutes.publicCaptureDetail,
                          extra: capture,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendHeader extends StatelessWidget {
  const _TrendHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_graph_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공개 구절 피드',
                  style: AppTextStyles.title,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '다른 독자들이 공개한 구절을 최신순으로 확인해보세요.',
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

class _PublicCaptureCard extends StatelessWidget {
  const _PublicCaptureCard({
    required this.capture,
    required this.onOpen,
  });

  final PublicCapture capture;
  final VoidCallback onOpen;

  DocumentReference<Map<String, dynamic>> get _captureRef {
    return FirebaseFirestore.instance
        .collection('publicCaptures')
        .doc(capture.id);
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

  @override
  Widget build(BuildContext context) {
    final pageText =
        capture.pageNumber == null ? null : 'p.${capture.pageNumber}';

    final comment = capture.comment.trim();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _captureStream(),
      builder: (context, captureSnapshot) {
        final data = captureSnapshot.data?.data();

        final liveLikeCount = data?['likeCount'] as int? ?? capture.likeCount;
        final liveCommentCount =
            data?['commentCount'] as int? ?? capture.commentCount;

        return StreamBuilder<bool>(
          stream: _likedStream(),
          initialData: false,
          builder: (context, likeSnapshot) {
            final liked = likeSnapshot.data ?? false;

            return Material(
              color: AppColors.surface,
              borderRadius: AppRadius.lgRadius,
              child: InkWell(
                borderRadius: AppRadius.lgRadius,
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: AppColors.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.025),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              capture.bookTitle,
                              style: AppTextStyles.bodyStrong,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '공개',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.format_quote_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              capture.quote,
                              style: AppTextStyles.body.copyWith(
                                height: 1.55,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.mode_comment_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  comment,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          if (pageText != null) ...[
                            const Icon(
                              Icons.sticky_note_2_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pageText,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          const Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateTime(capture.createdAt),
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          _FeedAction(
                            icon: liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: '공감 $liveLikeCount',
                            selected: liked,
                            onTap: onOpen,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FeedAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '댓글 $liveCommentCount',
                            selected: false,
                            onTap: onOpen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.red : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendEmptyView extends StatelessWidget {
  const _TrendEmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.public_off_rounded,
                size: 44,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                '아직 공개된 구절이 없어요',
                style: AppTextStyles.bodyStrong,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '문장을 저장할 때 공개로 설정하면 이곳에 표시돼요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendErrorView extends StatelessWidget {
  const _TrendErrorView({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '공개 구절을 불러오지 못했어요',
                style: AppTextStyles.bodyStrong,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
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