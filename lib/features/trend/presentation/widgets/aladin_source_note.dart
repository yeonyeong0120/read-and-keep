import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 알라딘 도서 DB 출처 표기(약관 의무).
///
/// TR-001/002/003 의 베스트셀러 영역 하단에 작은 흐린 글씨로 공통 노출한다.
class AladinSourceNote extends StatelessWidget {
  const AladinSourceNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '도서 DB 제공: 알라딘 인터넷서점(www.aladin.co.kr)',
      // caption 보다 작고 흐린 색으로 둔다.
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textHint,
        fontSize: 11,
      ),
    );
  }
}
