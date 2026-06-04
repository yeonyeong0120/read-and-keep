import 'package:flutter/widgets.dart';

/// 읽다남김 간격(Spacing) 토큰
///
/// 4의 배수를 기준 단위로 두고 8의 배수를 주축으로 사용하는 스케일이다.
/// 대표 화면 PNG의 여백 측정값(좌우 여백 약 24px, 버튼 높이 약 52px)에 근거한다.
abstract final class AppSpacing {
  AppSpacing._();

  /// 4. 인접 요소 사이의 최소 간격.
  static const double xs = 4;

  /// 8. 아이콘과 텍스트 사이 등 좁은 간격.
  static const double sm = 8;

  /// 12. 카드 내부 요소 간 간격.
  static const double md = 12;

  /// 16. 카드 내부 패딩 기본값.
  static const double lg = 16;

  /// 24. 화면 좌우 기본 여백, 섹션 간 간격.
  static const double xl = 24;

  /// 32. 큰 섹션 구분 간격.
  static const double xxl = 32;

  /// 48. 화면 상하 여백 등 넓은 간격.
  static const double xxxl = 48;

  // --- 레이아웃 상수 ---

  /// 화면 좌우 기본 패딩.
  static const double screenHorizontal = 24;

  /// 풀폭 버튼 표준 높이.
  static const double buttonHeight = 52;

  /// 화면 좌우 패딩을 적용한 EdgeInsets.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: screenHorizontal);
}
