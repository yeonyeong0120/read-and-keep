import 'package:flutter/material.dart';

/// 1차 LLM 키워드 칩에서 허용하는 아이콘 문자열 화이트리스트.
///
/// LLM 이 이 집합을 벗어난 값을 주면 [sanitizeKeywordIcon] 으로 기본값으로
/// 치환한다. UI 는 [keywordIconData] 로 실제 [IconData] 를 얻는다.
const List<String> kAllowedKeywordIcons = [
  'lightbulb',
  'heart',
  'book',
  'city',
  'people',
  'mountain',
  'sun',
  'moon',
  'leaf',
  'star',
  'fire',
  'water',
  'music',
  'art',
  'time',
  'dream',
  'journey',
  'home',
];

/// 허용 집합을 벗어난 아이콘일 때 사용하는 기본값.
const String _defaultKeywordIcon = 'book';

/// 허용 집합을 벗어난 icon 문자열을 기본값('book')으로 치환한다.
String sanitizeKeywordIcon(String raw) {
  final normalized = raw.trim().toLowerCase();
  return kAllowedKeywordIcons.contains(normalized)
      ? normalized
      : _defaultKeywordIcon;
}

/// 아이콘 문자열을 Material [IconData] 로 매핑한다. 미지정/미허용은
/// [Icons.book_outlined] 로 떨어진다(내부에서 [sanitizeKeywordIcon] 적용).
IconData keywordIconData(String name) {
  switch (sanitizeKeywordIcon(name)) {
    case 'lightbulb':
      return Icons.lightbulb_outline_rounded;
    case 'heart':
      return Icons.favorite_outline_rounded;
    case 'book':
      return Icons.book_outlined;
    case 'city':
      return Icons.location_city_outlined;
    case 'people':
      return Icons.people_outline_rounded;
    case 'mountain':
      return Icons.terrain_outlined;
    case 'sun':
      return Icons.wb_sunny_outlined;
    case 'moon':
      return Icons.nightlight_outlined;
    case 'leaf':
      return Icons.eco_outlined;
    case 'star':
      return Icons.star_outline_rounded;
    case 'fire':
      return Icons.local_fire_department_outlined;
    case 'water':
      return Icons.water_drop_outlined;
    case 'music':
      return Icons.music_note_outlined;
    case 'art':
      return Icons.palette_outlined;
    case 'time':
      return Icons.schedule_outlined;
    case 'dream':
      return Icons.cloud_outlined;
    case 'journey':
      return Icons.explore_outlined;
    case 'home':
      return Icons.home_outlined;
    default:
      return Icons.book_outlined;
  }
}
