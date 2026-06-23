import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// CM-001 스플래시 화면.
///
/// 앱 시작 시 인증 상태([currentAppUserProvider])가 확정되기 전까지 머무는 화면이다.
/// auth_background 이미지를 배경으로 사용하며, 배경을 선명하게 보여주기 위해
/// 베이지 오버레이는 두지 않는다. 중앙부가 밝은 톤이라 어두운 텍스트/로고가 잘 읽힌다.
///
/// 실제 분기(홈/로그인)는 라우터 redirect 가 담당하므로 본 화면은 표시만 한다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 최하단: 배경 이미지(오버레이 없이 선명하게 노출).
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 브랜드 영역: 펼친 책 아이콘 + 서비스명 + 서브카피를 중앙 배치.
          const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text('읽다남김', style: AppTextStyles.displayLarge),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    '문장을 기록하고,\n취향을 발견하는 독서 경험',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
