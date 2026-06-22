import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_providers.dart';

/// 계정 관리 화면 (MY-003).
///
/// 닉네임 변경(다이얼로그), 이메일 표시(변경 불가), 비밀번호 변경(이메일 재설정
/// 링크 발송)을 제공한다. 계정 연동(소셜)은 보류 상태로 "준비 중" 처리한다.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('준비 중입니다')));
  }

  /// 닉네임 변경 다이얼로그를 띄우고, 새 닉네임을 받아 갱신한다.
  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    String currentNickname,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) => _NicknameEditDialog(initialValue: currentNickname),
    );

    if (newNickname == null || newNickname == currentNickname) return;

    await ref.read(authProvider.notifier).updateNickname(newNickname);

    final state = ref.read(authProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.hasError ? '닉네임 변경에 실패했어요. 잠시 후 다시 시도해주세요.' : '닉네임을 변경했어요.',
        ),
      ),
    );
  }

  /// 현재 사용자 이메일로 비밀번호 재설정 링크를 발송한다(CM-004 재사용, 화면 이동 없음).
  Future<void> _changePassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    await ref.read(authProvider.notifier).sendPasswordResetEmail(email: email);

    final state = ref.read(authProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? '메일 발송에 실패했어요. 잠시 후 다시 시도해주세요.'
              : '비밀번호 재설정 링크를 이메일로 보냈어요.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);

    final nickname =
        userAsync.whenOrNull(data: (user) => user?.nickname) ?? '';
    final email = userAsync.whenOrNull(data: (user) => user?.email) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('계정 관리'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '계정 정보를 확인하고 관리할 수 있어요.',
                style: AppTextStyles.caption,
              ),

              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('계정 정보'),
              const SizedBox(height: AppSpacing.md),
              _Card(
                children: [
                  _AccountRow(
                    icon: Icons.person_outline_rounded,
                    title: '닉네임',
                    valueText: nickname.isEmpty ? '독자' : nickname,
                    onTap: () => _editNickname(context, ref, nickname),
                  ),
                  // 이메일은 변경 불가. 회색 처리 + 탭 동작 없음.
                  _AccountRow(
                    icon: Icons.mail_outline_rounded,
                    title: '이메일',
                    valueText: email,
                    enabled: false,
                  ),
                  _AccountRow(
                    icon: Icons.lock_outline_rounded,
                    title: '비밀번호 변경',
                    subtitle: '보안을 위해 주기적으로 변경해주세요.',
                    onTap: email.isEmpty
                        ? null
                        : () => _changePassword(context, ref, email),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel('계정 연동'),
              const SizedBox(height: AppSpacing.md),
              // 소셜 로그인은 보류 상태. 항목은 표시하되 "연동하기"는 비활성(준비 중).
              _Card(
                children: [
                  _AccountRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '카카오 연동',
                    trailingText: '연동하기',
                    onTap: () => _showComingSoon(context),
                  ),
                  _AccountRow(
                    icon: Icons.g_mobiledata_rounded,
                    title: 'Google 연동',
                    trailingText: '연동하기',
                    onTap: () => _showComingSoon(context),
                  ),
                  _AccountRow(
                    icon: Icons.apple_rounded,
                    title: 'Apple 연동',
                    trailingText: '연동하기',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _LinkNoticeBox(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 섹션 라벨.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.title);
  }
}

/// 카드 그룹. 자식 행 사이에 구분선을 넣는다.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
        );
      }
      rows.add(children[i]);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgRadius,
        child: Column(children: rows),
      ),
    );
  }
}

/// 계정 정보/연동 행.
///
/// [valueText](우측 현재값), [trailingText](우측 액션 라벨), [subtitle](제목 아래
/// 부연) 중 필요한 것만 쓴다. [enabled]=false 면 회색 + 비탭. [onTap] 이 있으면 ">".
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    this.valueText,
    this.trailingText,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? valueText;
  final String? trailingText;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        enabled ? AppColors.textPrimary : AppColors.textSecondary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: titleColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(color: titleColor),
                ),
                if (valueText != null && valueText!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    valueText!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...[
            Text(trailingText!, style: AppTextStyles.caption),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textHint,
            ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(onTap: onTap, child: content);
  }
}

/// 계정 연동 보류 안내 박스.
class _LinkNoticeBox extends StatelessWidget {
  const _LinkNoticeBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '소셜 계정 연동은 추후 지원 예정이에요.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// 닉네임 변경 다이얼로그. 확인 시 새 닉네임 문자열을 pop 으로 반환한다.
class _NicknameEditDialog extends StatefulWidget {
  const _NicknameEditDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_NicknameEditDialog> createState() => _NicknameEditDialogState();
}

class _NicknameEditDialogState extends State<_NicknameEditDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  /// 닉네임 최대 길이.
  static const int _maxLength = 15;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('닉네임 변경'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: _maxLength,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: '새 닉네임을 입력해주세요.'),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return '닉네임을 입력해주세요.';
            if (v.length > _maxLength) return '$_maxLength자 이하로 입력해주세요.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('변경'),
        ),
      ],
    );
  }
}
