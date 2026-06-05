import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/auth_providers.dart';

/// CM-002 로그인 화면.
///
/// 이메일/비밀번호 로그인은 [AuthNotifier.signIn] 으로 실동작한다.
/// 소셜 로그인 / 비밀번호 찾기 / 회원가입은 후속 단계에서 활성화한다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _keepSignedIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // 결과 처리는 ref.listen 이 담당한다.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 로그인 액션 실패 시 토스트로 안내. 성공 분기는 currentAppUserProvider
    // 가 갱신되므로 AuthGate(STEP 5-E)에서 자동 전환된다.
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        error: (_, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이메일 또는 비밀번호가 일치하지 않습니다.'),
            ),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                _BrandHeader(),
                const SizedBox(height: AppSpacing.xxxl),
                _EmailField(controller: _emailController),
                const SizedBox(height: AppSpacing.md),
                _PasswordField(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggleObscure: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  onSubmitted: _submit,
                ),
                const SizedBox(height: AppSpacing.sm),
                _OptionsRow(
                  keepSignedIn: _keepSignedIn,
                  onKeepSignedInChanged: (value) => setState(
                    () => _keepSignedIn = value ?? false,
                  ),
                  onForgotPassword: () {
                    // TODO(step5-e): 비밀번호 찾기 화면(CM-004)으로 라우팅.
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _LoginButton(
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _OrDivider(),
                const SizedBox(height: AppSpacing.xl),
                const _SocialLoginRow(),
                const SizedBox(height: AppSpacing.xxxl),
                _SignUpLink(
                  onPressed: () {
                    // TODO(step5-d): 회원가입 화면(CM-003)으로 라우팅.
                  },
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

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.menu_book_rounded, size: 64, color: AppColors.primary),
        SizedBox(height: AppSpacing.lg),
        Text('읽다남김', style: AppTextStyles.display),
        SizedBox(height: AppSpacing.sm),
        Text(
          '문장을 기록하고, 취향을 발견하는 독서 경험',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

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
        hintText: '이메일',
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Future<void> Function() onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: '비밀번호',
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
      validator: (value) {
        if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
        return null;
      },
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.keepSignedIn,
    required this.onKeepSignedInChanged,
    required this.onForgotPassword,
  });

  final bool keepSignedIn;
  final ValueChanged<bool?> onKeepSignedInChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(value: keepSignedIn, onChanged: onKeepSignedInChanged),
            const Text('로그인 상태 유지', style: AppTextStyles.body),
          ],
        ),
        TextButton(onPressed: onForgotPassword, child: const Text('비밀번호 찾기')),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

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
          : const Text('로그인'),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('또는', style: AppTextStyles.caption),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialLoginRow extends StatelessWidget {
  const _SocialLoginRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 카카오 — 사용자 결정에 따라 보류
        _SocialButton(icon: Icons.chat_bubble_outline_rounded, label: '카카오'),
        // Google — STEP 5-F 에서 활성화
        _SocialButton(icon: Icons.g_mobiledata_rounded, label: 'Google'),
        // Apple — iOS 미고려로 비활성
        _SocialButton(icon: Icons.apple_rounded, label: 'Apple'),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: null, // 후속 단계에서 활성화
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 64),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _SignUpLink extends StatelessWidget {
  const _SignUpLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '아직 계정이 없으신가요?  '),
            TextSpan(
              text: '회원가입',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}