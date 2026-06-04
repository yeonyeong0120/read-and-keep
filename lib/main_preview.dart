import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

/// 디자인 토큰/화면 검증 전용 임시 진입점.
/// Firebase·dotenv 초기화 없이 단일 화면만 렌더링한다.
/// 실행: flutter run -t lib/main_preview.dart
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    ),
  );
}