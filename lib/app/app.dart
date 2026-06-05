import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/login_screen.dart';


/// 앱 루트 위젯.
///
/// 라우터·테마·로컬라이제이션 등 앱 전역 설정의 진입점이다.
/// 화면 트리는 이후 단계에서 go_router 또는 자체 라우터로 대체한다.
class ReadAndKeepApp extends StatelessWidget {
  const ReadAndKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '읽다남김',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}