import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';

/// 트렌드 화면 (TR) 임시 자리표시. 본 콘텐츠는 추후 구현한다.
class TrendScreen extends ConsumerWidget {
  const TrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('트렌드')),
      body: const Center(
        child: Text('트렌드 화면은 추후 구현', style: AppTextStyles.body),
      ),
    );
  }
}
