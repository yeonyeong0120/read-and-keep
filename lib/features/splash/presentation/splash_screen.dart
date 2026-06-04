import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// CM-001 스플래시 화면 (디자인 토큰 검증용 정적 위젯)
///
/// 화면설계서 4.1 CM-001의 default 상태 화면 구성을 따른다.
/// 본 위젯은 토큰 적용 검증을 목적으로 하므로 상태 관리를 연결하지 않는다.
/// Firebase 초기화, 인증 상태 확인, 자동 전환, error 상태(재시도 버튼)는
/// 후속 구현 단계에서 init Provider(AsyncNotifier)와 ConsumerWidget으로 추가한다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 전체 배경: background 토큰(베이지/크림)
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 무드 이미지(책 + 잎사귀). 자산 미등록 시 배경색으로 대체된다.
          // 실제 이미지는 assets/images/ 에 배치하고 pubspec.yaml에 등록한다.
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),

          // 중앙 브랜드 영역
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 브랜드 아이콘(펼친 책). 실제 마크는 커스텀 자산으로 교체 예정.
                Icon(
                  Icons.menu_book_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
                SizedBox(height: AppSpacing.xl),

                // 브랜드명: 스플래시 전용 displayLarge(44pt)
                Text('읽다남김', style: AppTextStyles.displayLarge),
                SizedBox(height: AppSpacing.md),

                // 서브 카피: 2줄, 보조 텍스트색(caption 기본색), 중앙 정렬
                Text(
                  '문장을 기록하고,\n취향을 발견하는 독서 경험',
                  textAlign: TextAlign.center,
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
