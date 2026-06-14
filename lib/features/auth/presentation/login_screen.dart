import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/auth_providers.dart';
import 'signup_screen.dart';

/// CM-002 로그인 화면.
///
/// 배경 이미지 위에 베이지 오버레이를 깔아 가독성을 확보하고, 그 위에
/// 브랜드 영역과 이메일/비밀번호 로그인 폼을 배치한다.
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

  // 위젯 로컬 UI 상태. 인증 상태(authProvider)와는 분리해서 관리한다.
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

    // 액션 트리거는 read 로 수행한다. 결과 처리는 build 의 ref.listen 이 담당한다.
    await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    // 버튼 로딩 분기는 빌드 의존이므로 watch 로 구독한다.
    final isLoading = ref.watch(authProvider).isLoading;

    // 로그인 액션 실패 시에만 토스트로 안내한다. 메시지는 보안상 통일한다.
    // 성공 분기는 currentAppUserProvider 가 갱신되어 AuthGate(STEP 5-E)에서
    // 자동 전환되므로 여기서 처리하지 않는다.
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
      body: Stack(
        children: [
          // 최하단: 배경 이미지를 화면 전체에 cover 로 깐다.
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 가독성 오버레이: 베이지 배경색을 반투명으로 한 겹 덮는다.
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.82),
            ),
          ),
          // 콘텐츠
          SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    const _BrandHeader(),
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
                    _LoginButton(isLoading: isLoading, onPressed: _submit),
                    const SizedBox(height: AppSpacing.xl),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    const _SocialLoginButtons(),
                    const SizedBox(height: AppSpacing.xxl),
                    _SignUpLink(
                      // STEP 5-E 에서 라우터(go_router)로 정리한다.
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignupScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 브랜드 영역: 펼친 책 아이콘 + 서비스명 + 서브카피.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.menu_book_rounded, size: 56, color: AppColors.primary),
        SizedBox(height: AppSpacing.lg),
        Text('읽다남김', style: AppTextStyles.display),
        SizedBox(height: AppSpacing.sm),
        Text(
          '문장을 기록하고,\n취향을 발견하는 독서 경험',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
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

/// 비밀번호 입력 필드. 눈 토글로 표시/숨김을 전환한다.
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
        hintText: '비밀번호를 입력해주세요.',
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

/// 옵션 행: 좌측 로그인 상태 유지 체크박스, 우측 비밀번호 찾기 링크.
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
            Checkbox(
              value: keepSignedIn,
              onChanged: onKeepSignedInChanged,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text('로그인 상태 유지', style: AppTextStyles.caption),
          ],
        ),
        TextButton(
          onPressed: onForgotPassword,
          child: const Text('비밀번호 찾기 >', style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

/// 로그인 제출 버튼. 로딩 중에는 인디케이터를 표시한다.
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

/// "또는" 구분선.
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

/// 소셜 로그인 버튼 묶음.
///
/// 라벨이 길어 가로 3분할은 좁으므로, 가독성을 우선해 세로 풀폭 3개로 둔다.
/// 셋 다 후속 단계 전까지 비활성(onPressed: null)이다.
class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 카카오: 말풍선 아이콘으로 연상. 골드 톤으로 브랜드 색을 암시한다.
        _SocialButton(
          icon: Icons.chat_bubble_rounded,
          iconColor: AppColors.warning,
          label: '카카오로 로그인',
        ),
        SizedBox(height: AppSpacing.md),
        // 구글: G 마크 아이콘으로 연상.
        _SocialButton(
          icon: Icons.g_mobiledata_rounded,
          iconColor: AppColors.textPrimary,
          label: '구글로 로그인',
        ),
        SizedBox(height: AppSpacing.md),
        // 애플: 사과 아이콘으로 연상.
        _SocialButton(
          icon: Icons.apple_rounded,
          iconColor: AppColors.textPrimary,
          label: 'Apple로 로그인',
        ),
      ],
    );
  }
}

/// 개별 소셜 로그인 버튼. 배경/테두리는 토큰으로 통일한다.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null, // 후속 단계에서 활성화
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.outline),
        textStyle: AppTextStyles.bodyStrong,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      icon: Icon(icon, color: iconColor),
      label: Text(label),
    );
  }
}

/// 하단 회원가입 링크.
class _SignUpLink extends StatelessWidget {
  const _SignUpLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text.rich(
        TextSpan(
          style: AppTextStyles.caption,
          children: [
            TextSpan(text: '아직 계정이 없으신가요?  '),
            TextSpan(
              text: '회원가입 >',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
