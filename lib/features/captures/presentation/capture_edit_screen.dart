import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../data/models/capture.dart';
import '../domain/capture_providers.dart';

/// CP-006(직접입력) + CP-005(OCR 결과 확인) 공용 구절 편집 화면.
///
/// [source]에 따라 제목/부제/좌측 버튼 라벨만 가변하고, 나머지 입력 흐름은
/// 동일하다. OCR 경로(8-C/8-D)는 [initialText]·[ocrRawText]를 채워 진입한다.
/// 화면설계서 2.2에 따라 본 화면은 탭바를 숨긴다(셸 바깥 최상위 라우트).
class CaptureEditScreen extends ConsumerStatefulWidget {
  const CaptureEditScreen({
    required this.bookId,
    required this.source,
    this.initialText,
    this.ocrRawText,
    super.key,
  });

  /// 대상 책 ID.
  final String bookId;

  /// 진입 출처(manual/camera/gallery).
  final CaptureSource source;

  /// OCR 결과 사전 입력용. 직접입력이면 null.
  final String? initialText;

  /// OCR 원본 텍스트. 직접입력이면 null.
  final String? ocrRawText;

  @override
  ConsumerState<CaptureEditScreen> createState() => _CaptureEditScreenState();
}

class _CaptureEditScreenState extends ConsumerState<CaptureEditScreen> {
  late final TextEditingController _textController;
  final _pageController = TextEditingController();
  final _commentController = TextEditingController();

  // 공개 설정. 기본은 비공개(Privacy by Default).
  bool _isPublic = false;

  // 저장 버튼 활성 여부. 본문 1자 이상이면 활성.
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _canSave = _textController.text.trim().isNotEmpty;
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSave = _textController.text.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  /// 진입 출처별 화면 제목.
  String get _title => switch (widget.source) {
        CaptureSource.manual => '문장 직접 추가',
        CaptureSource.camera || CaptureSource.gallery => '문장 수정 / 확인',
      };

  /// 진입 출처별 부연 안내.
  String get _subtitle => switch (widget.source) {
        CaptureSource.manual => '문장을 직접 입력해주세요',
        CaptureSource.camera ||
        CaptureSource.gallery =>
          '인식된 문장을 확인하고 수정해주세요',
      };

  /// 진입 출처별 좌측 보조 버튼 라벨.
  String get _secondaryLabel => switch (widget.source) {
        CaptureSource.manual => '취소',
        CaptureSource.camera => '다시 촬영',
        CaptureSource.gallery => '다른 사진 선택',
      };

  /// 좌측 보조 버튼: 입력 내용이 있으면 확인 후, 없으면 바로 뒤로.
  Future<void> _onSecondaryPressed() async {
    final hasInput = _textController.text.trim().isNotEmpty ||
        _pageController.text.trim().isNotEmpty ||
        _commentController.text.trim().isNotEmpty;

    if (!hasInput) {
      context.pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('작성을 취소할까요?'),
        content: const Text('입력한 내용은 저장되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('계속 작성'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      context.pop();
    }
  }

  /// 구절을 저장하고, 성공 시 책 상세로 이동한다.
  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final page = int.tryParse(_pageController.text.trim());

    final saved = await ref.read(captureActionProvider.notifier).save(
          bookId: widget.bookId,
          text: text,
          page: page,
          comment: _commentController.text.trim(),
          isPublic: _isPublic,
          source: widget.source,
          ocrRawText: widget.ocrRawText,
        );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (saved != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('문장이 저장되었습니다.')));
      context.go(AppRoutes.bookDetailOf(widget.bookId));
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookProvider(widget.bookId));
    final isSaving = ref.watch(captureActionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('책을 불러오지 못했습니다', style: AppTextStyles.body),
        ),
        data: (book) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                ),
                children: [
                  Text(_subtitle, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.lg),
                  _BookInfoCard(book: book),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('선택한 문장'),
                  const SizedBox(height: AppSpacing.sm),
                  _SentenceField(controller: _textController),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('페이지 번호'),
                  const SizedBox(height: AppSpacing.sm),
                  _PageField(controller: _pageController),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('코멘트'),
                  const SizedBox(height: AppSpacing.sm),
                  _CommentField(controller: _commentController),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('공개 설정'),
                  const SizedBox(height: AppSpacing.sm),
                  _VisibilityToggle(
                    isPublic: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
              ),
            ),
            _BottomActions(
              secondaryLabel: _secondaryLabel,
              canSave: _canSave,
              isSaving: isSaving,
              onSecondary: isSaving ? null : _onSecondaryPressed,
              onSave: (_canSave && !isSaving) ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 책 표지 + 제목/저자·출판사.
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력 영역 라벨.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodyStrong);
  }
}

/// 구절 본문 입력(멀티라인).
class _SentenceField extends StatelessWidget {
  const _SentenceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(hintText: '문장을 입력해주세요'),
    );
  }
}

/// 페이지 번호 입력(숫자 전용, 선택 입력).
class _PageField extends StatelessWidget {
  const _PageField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        hintText: '예: 152',
        helperText: '숫자만 입력 (선택)',
      ),
    );
  }
}

/// 코멘트 입력(멀티라인, 선택 입력).
class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        hintText: '이 문장에 대한 생각을 남겨보세요 (선택)',
      ),
    );
  }
}

/// 공개/비공개 토글 + 안내.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.isPublic, required this.onChanged});

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isPublic ? '공개' : '비공개',
                  style: AppTextStyles.bodyStrong,
                ),
              ),
              Switch(value: isPublic, onChanged: onChanged),
            ],
          ),
          const Text(
            '비공개로 저장하면 나만 볼 수 있습니다.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// 하단 액션: 좌측 보조(라벨 가변) / 우측 저장하기.
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.secondaryLabel,
    required this.canSave,
    required this.isSaving,
    required this.onSecondary,
    required this.onSave,
  });

  final String secondaryLabel;
  final bool canSave;
  final bool isSaving;
  final VoidCallback? onSecondary;
  final VoidCallback? onSave;

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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: isSaving
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
      ),
    );
  }
}
