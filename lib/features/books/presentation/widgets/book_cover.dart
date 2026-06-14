import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// 책 표지 위젯(BK 공용).
///
/// URL 이 비었거나 로드 실패 시 surfaceVariant placeholder 박스로 대체한다.
class BookCover extends StatelessWidget {
  const BookCover({
    required this.url,
    this.width = 48,
    this.height = 64,
    this.iconSize = 24,
    super.key,
  });

  final String url;
  final double width;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smRadius,
      child: url.isEmpty
          ? _placeholder()
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, _) => _placeholder(),
              errorWidget: (context, _, _) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.menu_book_rounded,
        size: iconSize,
        color: AppColors.textSecondary,
      ),
    );
  }
}
