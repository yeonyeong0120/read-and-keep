import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_providers.dart';
import '../domain/mypage_providers.dart';

/// 회원 탈퇴 화면 (MY-008).
///
/// 학부 과제 안전 방식: 즉시 완전 삭제 대신 `withdrawals` 컬렉션에 요청만 기록한
/// 뒤 로그아웃한다. 동의 체크박스를 1차 게이트로 두고, 비가역성을 본문에 명시한다.
class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  /// 탈퇴 사유 선택지(선택 입력).
  static const List<String> _reasons = [
    '사용하지 않게 됨',
    '기능이 부족함',
    '사용법이 어려움',
    '개인정보 우려',
    '기타',
  ];

  /// 남기고 싶은 말 최대 길이.
  static const int _maxMessageLength = 300;

  final TextEditingController _messageController = TextEditingController();

  String? _selectedReason;
  bool _agreed = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _onWithdraw() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = _messageController.text.trim();

    await ref.read(withdrawalProvider.notifier).submit(
          reason: _selectedReason,
          message: message.isEmpty ? null : message,
        );

    if (!mounted) return;

    final state = ref.read(withdrawalProvider);
    state.when(
      data: (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('탈퇴 요청이 접수되었어요. 처리는 1~3 영업일 이내 완료됩니다.'),
          ),
        );
        // 요청 기록 성공 후 로그아웃 → redirect 가 /login 으로 보낸다.
        ref.read(authProvider.notifier).signOut();
      },
      loading: () {},
      error: (error, _) {
        messenger.showSnackBar(
          SnackBar(content: Text(_withdrawErrorMessage(error))),
        );
      },
    );
  }

  /// 탈퇴 요청 실패 메시지. 규칙 미설정 시의 권한 오류를 따로 안내한다.
  String _withdrawErrorMessage(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return '탈퇴 요청 권한이 없어요. 관리자에게 문의해주세요.';
    }
    return '탈퇴 요청에 실패했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    // 탈퇴 기록 또는 로그아웃이 진행 중이면 버튼을 비활성화한다.
    final isProcessing = ref.watch(withdrawalProvider).isLoading ||
        ref.watch(authProvider).isLoading;
    final canSubmit = _agreed && !isProcessing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('회원 탈퇴'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                children: [
                  const Text(
                    '회원 탈퇴 전 아래 내용을 꼭 확인해주세요.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _WarningBox(),

                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('탈퇴 사유 (선택)'),
                  const SizedBox(height: AppSpacing.sm),
                  _ReasonDropdown(
                    value: _selectedReason,
                    reasons: _reasons,
                    onChanged: isProcessing
                        ? null
                        : (value) => setState(() => _selectedReason = value),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const _FieldLabel('남기고 싶은 말 (선택)'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _messageController,
                    enabled: !isProcessing,
                    maxLength: _maxMessageLength,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '서비스를 이용하며 느낀 점이 있다면 남겨주세요.',
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  _AgreementCheckbox(
                    value: _agreed,
                    onChanged: isProcessing
                        ? null
                        : (value) =>
                            setState(() => _agreed = value ?? false),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding.copyWith(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // 주 액션: 파괴적 버튼(destructive 토큰). 미동의/진행 중 비활성.
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeight,
                    child: FilledButton(
                      onPressed: canSubmit ? _onWithdraw : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.destructive,
                        foregroundColor: AppColors.onDestructive,
                        disabledBackgroundColor: AppColors.disabledBackground,
                        disabledForegroundColor: AppColors.disabledText,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onDestructive,
                              ),
                            )
                          : const Text('회원 탈퇴'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // 보조 액션: 취소 → MY-001 복귀.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isProcessing ? null : () => context.pop(),
                      child: const Text('취소'),
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

/// 비가역성 경고 박스(느낌표 + destructive 톤).
class _WarningBox extends StatelessWidget {
  const _WarningBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: AppColors.destructive,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WarningLine('저장한 책, 구절, 코멘트가 모두 삭제됩니다.'),
                SizedBox(height: AppSpacing.xs),
                _WarningLine('공개한 구절과 활동 기록도 함께 삭제됩니다.'),
                SizedBox(height: AppSpacing.xs),
                _WarningLine('탈퇴 후에는 계정을 복구할 수 없습니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 경고 박스의 한 줄(불릿 + 텍스트).
class _WarningLine extends StatelessWidget {
  const _WarningLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('· ', style: AppTextStyles.body),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}

/// 필드 라벨.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.bodyStrong);
  }
}

/// 탈퇴 사유 드롭다운.
class _ReasonDropdown extends StatelessWidget {
  const _ReasonDropdown({
    required this.value,
    required this.reasons,
    required this.onChanged,
  });

  final String? value;
  final List<String> reasons;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: const Text('탈퇴 사유를 선택해주세요.', style: AppTextStyles.body),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      items: reasons
          .map(
            (reason) => DropdownMenuItem<String>(
              value: reason,
              child: Text(reason, style: AppTextStyles.body),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// 동의 체크박스 행.
class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.smRadius,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            const Expanded(
              child: Text(
                '안내 내용을 모두 확인했으며, 회원 탈퇴에 동의합니다.',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
