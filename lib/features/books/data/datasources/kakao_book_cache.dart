import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// 카카오 책 검색 결과 로컬 캐시.
///
/// Hive `kakao_cache` Box 를 JSON 문자열 방식으로 다룬다(어댑터 미사용).
/// key 는 정규화한 검색어, value 는 `{ savedAt, results }` JSON 문자열이다.
///
/// Box 의 초기화(Hive.initFlutter / openBox)는 본 클래스가 아니라 앱 시작 시
/// 1회 수행한다(main.dart 참고).
class KakaoBookCache {
  KakaoBookCache({Box<String>? box})
      : _box = box ?? Hive.box<String>(boxName);

  /// 캐시 Box 이름.
  static const String boxName = 'kakao_cache';

  /// 캐시 유효 기간(24시간, 밀리초).
  static const int _ttlMillis = 24 * 60 * 60 * 1000;

  final Box<String> _box;

  /// 검색어 정규화: 소문자 + 앞뒤 공백 제거.
  String _key(String query) => query.trim().toLowerCase();

  /// 캐시 조회.
  ///
  /// savedAt 이 24시간 이내면 results(카카오 document 원본 map 리스트)를 반환한다.
  /// 미스이거나 만료된 경우 null 을 반환하며, 만료된 항목은 즉시 삭제한다.
  List<Map<String, dynamic>>? read(String query) {
    final key = _key(query);
    final raw = _box.get(key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - savedAt > _ttlMillis) {
      _box.delete(key);
      return null;
    }

    final results = (decoded['results'] as List<dynamic>?) ?? const [];
    return results
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// 검색 결과(카카오 document 원본 map 리스트)를 캐시에 저장한다.
  Future<void> write(String query, List<Map<String, dynamic>> results) async {
    final payload = jsonEncode({
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'results': results,
    });
    await _box.put(_key(query), payload);
  }
}
