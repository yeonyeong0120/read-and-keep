import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/auth_providers.dart';

/// CM-004 비밀번호 재설정 화면.
///
/// 가입한 이메일로 Firebase 표준 재설정 링크를 발송한다.
/// 보안상 이메일 존재 여부를 노출하지 않도록, 정상 발송과 미존재 이메일을
/// 동일한 성공 안내로 처리한다. 네트워크 등 명백한 기술 오류만 구분한다.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    // 액션 트리거는 read 로 수행한다. 결과 처리는 build 의 ref.listen 이 담당한다.
    await ref.read(authProvider.notifier).sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
  }

  /// 네트워크 등 명백한 기술 오류인지 판별한다.
  ///
  /// user-not-found / invalid-email 같은 사용자 입력 관련 오류는 보안상
  /// 성공처럼 안내해야 하므로 기술 오류로 보지 않는다.
  bool _isTechnicalError(Object error) {
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed' ||
          error.code == 'too-many-requests' ||
          error.code == 'internal-error';
    }
    // FirebaseAuthException 이 아닌 예외는 기술 오류로 간주한다.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 분기는 빌드 의존이므로 watch 로 구독한다.
    final isLoading = ref.watch(authProvider).isLoading;

    // 발송 결과 처리. 직전이 로딩이었던 전이만 실제 결과로 간주한다.
    ref.listen(authProvider, (previous, next) {
      if (previous is! AsyncLoading) return;
      next.whenOrNull(
        data: (_) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('재설정 링크를 보냈습니다. 메일함을 확인해주세요.'),
            ),
          );
          context.pop();
        },
        error: (error, _) {
          final messenger = ScaffoldMessenger.of(context);
          if (_isTechnicalError(error)) {
            // 기술 오류는 재시도를 유도하기 위해 화면을 유지한다.
            messenger.showSnackBar(
              const SnackBar(content: Text('잠시 후 다시 시도해주세요.')),
            );
            return;
          }
          // 보안상 이메일 존재 여부를 노출하지 않도록 성공처럼 안내한다.
          messenger.showSnackBar(
            const SnackBar(
              content: Text('입력하신 이메일로 재설정 링크를 보냈습니다.'),
            ),
          );
          context.pop();
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  '비밀번호 재설정\n링크를 보내드릴게요',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  '가입한 이메일 주소를 입력해주세요.\n비밀번호 재설정 링크를 보내드립니다.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                _EmailField(controller: _emailController),
                const SizedBox(height: AppSpacing.lg),
                _SendLinkButton(isLoading: isLoading, onPressed: _submit),
                const SizedBox(height: AppSpacing.xl),
                const _SocialNoticeBox(),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('로그인으로 돌아가기'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 이메일 입력 필드.
class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      decoration: const InputDecoration(
        hintText: '이메일 주소를 입력해주세요.',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return '이메일을 입력해주세요.';
        if (!v.contains('@') || !v.contains('.')) {
          return '올바른 이메일 형식이 아닙니다.';
        }
        return null;
      },
    );
  }
}

/// 재설정 링크 발송 버튼. 로딩 중에는 인디케이터를 표시한다.
class _SendLinkButton extends StatelessWidget {
  const _SendLinkButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          : const Text('재설정 링크 보내기'),
    );
  }
}

/// 소셜 로그인 계정 안내 박스.
class _SocialNoticeBox extends StatelessWidget {
  const _SocialNoticeBox();

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('소셜 로그인 계정 안내', style: AppTextStyles.bodyStrong),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Google, Kakao, Apple로 가입하신 경우\n해당 서비스 로그인을 이용해주세요.',
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
