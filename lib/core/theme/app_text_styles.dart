import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 읽다남김 타이포그래피 토큰
///
/// 화면설계서 3.3.2의 5단계 스케일(Display, Headline, Title, Body, Caption)을
/// 정본으로 한다. 크기는 대표 화면 PNG의 글자 높이를 측정해 추정한 값이다.
/// 폰트는 Pretendard를 기본으로 하며, pubspec.yaml에 폰트 등록이 필요하다.
///
/// height 값은 폰트 크기에 대한 배수(line-height ratio)다.
/// 색상은 기본값을 두되, 사용처에서 copyWith로 재정의할 수 있다.
abstract final class AppTextStyles {
  AppTextStyles._();

  /// 기본 폰트 패밀리. pubspec.yaml의 fonts 항목명과 일치해야 한다.
  static const String fontFamily = 'Pretendard';

  /// 스플래시 브랜드 전용 대형 제목. 스플래시 1개 화면에서만 사용한다.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  /// 화면 진입 제목(예: 로그인 화면의 "읽다남김").
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// 화면 제목 영역(예: 홈 인사말).
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 섹션 제목, 책 제목.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 본문, 입력 필드, 카드 내용.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 본문 강조(버튼 라벨, 카드 내 책 제목 등). Body와 크기는 같고 굵기만 다르다.
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 보조 설명, 메타데이터. 기본 색은 보조 텍스트 색을 사용한다.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
