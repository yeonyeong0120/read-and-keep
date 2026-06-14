import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// 앱 루트 위젯.
///
/// go_router 기반 라우팅의 진입점이다. 라우터는 [routerProvider] 에서 주입받으며,
/// 인증 상태에 따라 화면이 자동 분기된다.
class ReadAndKeepApp extends ConsumerWidget {
  const ReadAndKeepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '읽다남김',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
