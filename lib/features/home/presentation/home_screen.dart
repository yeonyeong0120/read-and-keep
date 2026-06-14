import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_providers.dart';

/// 홈 화면 (MN-001) 임시 구현.
///
/// 책장·최근활동·오늘의문장 등 본 콘텐츠는 STEP 6-B 에서 구현한다.
/// 현재는 로그인 흐름 검증을 위해 로그아웃 버튼만 둔다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('홈 화면(STEP 6-B에서 구현)', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
