import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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
      home: const _SetupPlaceholderHome(),
    );
  }
}

/// 프로젝트 셋업 검증용 임시 홈 화면.
///
/// 다음 단계에서 인증 게이트·라우터 진입점으로 대체된다.
class _SetupPlaceholderHome extends StatelessWidget {
  const _SetupPlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('읽다남김')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '프로젝트 셋업 완료\n\n각 feature 화면은 이후 단계에서 작성한다.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}