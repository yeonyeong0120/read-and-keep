import 'package:flutter/widgets.dart';

/// 읽다남김 모서리 반경(Border Radius) 토큰
///
/// 대표 화면 PNG 관찰값(버튼·입력 약 12, 카드 약 16, 키워드 칩 알약형)에 근거한다.
/// double 값과 BorderRadius 편의 상수를 함께 제공한다.
abstract final class AppRadius {
  AppRadius._();

  /// 8. 작은 요소(태그, 작은 버튼)의 반경.
  static const double sm = 8;

  /// 12. 버튼, 입력 필드의 기본 반경.
  static const double md = 12;

  /// 16. 카드, 다이얼로그, 바텀시트의 반경.
  static const double lg = 16;

  /// 알약형(칩, 토글 등)에 사용하는 충분히 큰 반경.
  static const double full = 999;

  // --- BorderRadius 편의 상수 ---

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullRadius =
      BorderRadius.all(Radius.circular(full));

  /// 바텀시트 상단만 둥글게 처리하는 반경.
  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );
}
