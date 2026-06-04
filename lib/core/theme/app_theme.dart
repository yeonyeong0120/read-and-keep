import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 읽다남김 통합 테마
///
/// app_colors / app_text_styles / app_spacing / app_radius의 토큰을
/// Material 3 ThemeData로 결합한다. MaterialApp의 theme 인자에 AppTheme.light를 전달한다.
///
/// Color.withValues(alpha: value)는 Flutter 3.27 이상에서 제공된다.
/// CardThemeData, DialogThemeData 등의 *ThemeData 클래스 사용도 동일 버전대 기준이다.
abstract final class AppTheme {
  AppTheme._();

  /// 라이트 테마. 본 앱은 현재 단일 테마(라이트)만 정의한다.
  static ThemeData get light {
    final colorScheme = _colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: _textTheme,

      // 앱바: 배경과 동일 톤, 그림자 제거, 제목 중앙 정렬
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title,
      ),

      // Primary 풀폭 버튼
      filledButtonTheme: FilledButtonThemeData(style: _primaryButtonStyle),

      // Secondary 풀폭 버튼(흰 배경 + 브라운 테두리)
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size.fromHeight(AppSpacing.buttonHeight),
          ),
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
          foregroundColor: WidgetStatePropertyAll(AppColors.primary),
          textStyle: WidgetStatePropertyAll(AppTextStyles.bodyStrong),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.primary),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          ),
        ),
      ),

      // 텍스트 버튼(보조 링크)
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.primary),
          textStyle: WidgetStatePropertyAll(AppTextStyles.body),
        ),
      ),

      // 입력 필드
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdRadius,
          borderSide: BorderSide(color: AppColors.destructive),
        ),
      ),

      // 카드
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      ),

      // 하단 탭
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
      ),

      // 다이얼로그(확인 모달)
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.body,
      ),

      // 바텀시트
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheetRadius),
      ),

      // 토스트(SnackBar) — 하단 floating
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.onPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),

      // 키워드 칩(알약형)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// 파괴적 액션(회원 탈퇴, 삭제) 버튼 스타일.
  /// Material에 전용 슬롯이 없으므로, FilledButton에 본 스타일을 적용한다.
  static ButtonStyle get destructiveButtonStyle => const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size.fromHeight(AppSpacing.buttonHeight),
        ),
        backgroundColor: WidgetStatePropertyAll(AppColors.destructive),
        foregroundColor: WidgetStatePropertyAll(AppColors.onDestructive),
        textStyle: WidgetStatePropertyAll(AppTextStyles.bodyStrong),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        ),
      );

  // --- 내부 정의 ---

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.surfaceVariant,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.primaryLight,
    onSecondary: AppColors.onPrimary,
    tertiary: AppColors.warning,
    onTertiary: AppColors.textPrimary,
    error: AppColors.destructive,
    onError: AppColors.onDestructive,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
  );

  /// Primary 풀폭 버튼 스타일. 비활성 상태 색을 함께 정의한다.
  static final ButtonStyle _primaryButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size.fromHeight(AppSpacing.buttonHeight),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.disabledBackground;
      }
      return AppColors.primary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.disabledText;
      }
      return AppColors.onPrimary;
    }),
    overlayColor: WidgetStatePropertyAll(
      AppColors.onPrimary.withValues(alpha: 0.12),
    ),
    textStyle: const WidgetStatePropertyAll(AppTextStyles.bodyStrong),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
    ),
  );

  /// 화면설계서 5단계 스케일을 Material TextTheme 슬롯에 매핑한다.
  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.display,
    headlineMedium: AppTextStyles.headline,
    headlineSmall: AppTextStyles.headline,
    titleLarge: AppTextStyles.title,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.body,
    labelLarge: AppTextStyles.bodyStrong,
    bodySmall: AppTextStyles.caption,
    labelSmall: AppTextStyles.caption,
  );
}
