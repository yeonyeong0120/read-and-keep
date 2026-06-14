import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/auth_providers.dart';

/// CM-003 회원가입 화면.
///
/// 피그마의 상단 "이메일 인증(인증번호 6자리)" 스텝퍼는 구현하지 않는다.
/// Firebase Auth 표준 링크 인증 방식으로 단순화하여, 단일 폼에서 계정 정보를
/// 입력받고 [AuthNotifier.signUp] 으로 가입 + 인증 메일 발송을 수행한다.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 위젯 로컬 UI 상태. 인증 상태(authProvider)와는 분리해서 관리한다.
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _agreedToTerms = false;
  int _nicknameLength = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) return;
    FocusScope.of(context).unfocus();

    // 액션 트리거는 read 로 수행한다. 결과 처리는 build 의 ref.listen 이 담당한다.
    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
        );
  }

  /// 가입 실패 시 사용자 친화 메시지로 변환한다.
  String _signUpErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return '이미 가입된 이메일입니다. 로그인해주세요.';
        case 'invalid-email':
          return '올바르지 않은 이메일 형식입니다.';
        case 'weak-password':
          return '비밀번호가 너무 약합니다. 다른 비밀번호를 사용해주세요.';
        case 'operation-not-allowed':
          return '현재 이메일 회원가입을 사용할 수 없습니다.';
      }
    }
    return '회원가입에 실패했습니다. 다시 시도해주세요.';
  }

  void _showTermsDialog(String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text('약관 전문은 추후 제공됩니다.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 분기는 빌드 의존이므로 watch 로 구독한다.
    final isLoading = ref.watch(authProvider).isLoading;

    // 가입 결과 처리. 직전이 로딩이었던 전이만 실제 결과로 간주한다.
    ref.listen(authProvider, (previous, next) {
      if (previous is! AsyncLoading) return;
      next.whenOrNull(
        data: (_) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('인증 메일을 보냈습니다. 메일함을 확인해주세요.'),
            ),
          );
          context.pop();
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_signUpErrorMessage(error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const _SignupHeader(),
                const SizedBox(height: AppSpacing.xl),
                _EmailField(controller: _emailController),
                const SizedBox(height: AppSpacing.md),
                _PasswordField(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggleObscure: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                  textInputAction: TextInputAction.next,
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.md),
                _PasswordField(
                  controller: _passwordConfirmController,
                  obscure: _obscurePasswordConfirm,
                  onToggleObscure: () => setState(
                    () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
                  ),
                  hintText: '비밀번호를 다시 입력해주세요.',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요.';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _NicknameField(
                  controller: _nicknameController,
                  currentLength: _nicknameLength,
                  onChanged: (value) => setState(
                    () => _nicknameLength = value.characters.length,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TermsAgreement(
                  agreed: _agreedToTerms,
                  onChanged: (value) => setState(
                    () => _agreedToTerms = value ?? false,
                  ),
                  onTapTerms: () => _showTermsDialog('이용약관'),
                  onTapPrivacy: () => _showTermsDialog('개인정보 처리방침'),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SignupButton(
                  isLoading: isLoading,
                  // 약관 미동의 또는 로딩 중이면 비활성.
                  onPressed: _agreedToTerms && !isLoading ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 비밀번호 규칙: 8자 이상 + 영문/숫자/특수문자 각 1개 이상.
  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return '비밀번호를 입력해주세요.';
    final pattern = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    if (!pattern.hasMatch(v)) {
      return '영문, 숫자, 특수문자를 포함해 8자 이상 입력해주세요.';
    }
    return null;
  }
}

/// 상단 안내 영역.
class _SignupHeader extends StatelessWidget {
  const _SignupHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('안전한 계정을 만들어보세요', style: AppTextStyles.title),
        SizedBox(height: AppSpacing.sm),
        Text(
          '이메일과 비밀번호로 읽다남김 계정을 생성합니다.',
          style: AppTextStyles.caption,
        ),
      ],
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
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        hintText: '이메일을 입력해주세요.',
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

/// 비밀번호 계열 입력 필드. 눈 토글로 표시/숨김을 전환한다.
class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.hintText,
    required this.textInputAction,
    required this.validator,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String hintText;
  final TextInputAction textInputAction;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      validator: validator,
    );
  }
}

/// 닉네임 입력 필드. 우측 하단에 글자수 카운터를 표시한다.
class _NicknameField extends StatelessWidget {
  const _NicknameField({
    required this.controller,
    required this.currentLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int currentLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.done,
      maxLength: 15,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '닉네임을 입력해주세요.',
        prefixIcon: const Icon(Icons.person_outline_rounded),
        // maxLength 기본 카운터 대신 로컬 상태 기반 카운터를 노출한다.
        counterText: '$currentLength/15',
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return '닉네임을 입력해주세요.';
        if (v.characters.length > 15) return '닉네임은 15자 이하로 입력해주세요.';
        return null;
      },
    );
  }
}

/// 약관 동의 행. 약관/처리방침 텍스트를 탭하면 안내 다이얼로그를 띄운다.
class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({
    required this.agreed,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  final bool agreed;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTextStyles.caption.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: agreed,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: onTapTerms,
                child: Text('이용약관', style: linkStyle),
              ),
              const Text(' 및 ', style: AppTextStyles.caption),
              GestureDetector(
                onTap: onTapPrivacy,
                child: Text('개인정보 처리방침', style: linkStyle),
              ),
              const Text('에 동의합니다.', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// 회원가입 제출 버튼. 로딩 중에는 인디케이터를 표시한다.
class _SignupButton extends StatelessWidget {
  const _SignupButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          : const Text('회원가입'),
    );
  }
}
