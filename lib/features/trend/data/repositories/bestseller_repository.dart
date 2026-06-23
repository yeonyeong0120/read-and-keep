import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/env/env_config.dart';
import '../models/bestseller_book.dart';

/// 알라딘 베스트셀러 Open API 호출을 담당하는 Repository.
///
/// 본 Repository 는 예외를 그대로 던진다. 로딩/에러 상태 관리는 호출하는
/// 쪽(Provider/Notifier)이 AsyncValue 로 처리한다.
class BestsellerRepository {
  BestsellerRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                // 알라딘 응답은 Content-Type 이 JSON 이 아닐 수 있어(text/javascript)
                // dio 의 자동 JSON 파싱에 의존하지 않고 plain 으로 받아 직접 디코드한다.
                responseType: ResponseType.plain,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  /// 알라딘 상품 리스트 API. https 로 호출해 Android cleartext 차단을 피한다.
  static const String _bestsellerUrl =
      'https://www.aladin.co.kr/ttb/api/ItemList.aspx';

  /// 베스트셀러 목록을 가져온다.
  ///
  /// [maxResults] 는 가져올 개수(기본 10), [categoryId] 는 분야 필터(null=전체).
  /// 키 미설정/알라딘 errorCode 응답은 예외로 전파한다.
  Future<List<BestsellerBook>> fetchBestsellers({
    int maxResults = 10,
    int? categoryId,
  }) async {
    final ttbKey = EnvConfig.aladinTtbKey;
    if (ttbKey.isEmpty) {
      throw StateError('알라딘 TTB 키가 설정되지 않았습니다');
    }

    final queryParameters = <String, dynamic>{
      // 알라딘은 헤더가 아니라 쿼리 파라미터 ttbkey 로 인증한다.
      'ttbkey': ttbKey,
      'QueryType': 'Bestseller',
      'MaxResults': maxResults,
      'start': 1,
      'SearchTarget': 'Book',
      'output': 'js',
      'Cover': 'Big',
      'Version': '20131101',
      // null 이면 자동으로 제외되는 null-aware 맵 요소.
      'CategoryId': ?categoryId,
    };

    final response = await _dio.get<dynamic>(
      _bestsellerUrl,
      queryParameters: queryParameters,
    );

    final Map<String, dynamic> data = _decodeBody(response.data);

    // 알라딘은 키 오류 등에서 errorCode/errorMessage 를 준다.
    final errorCode = data['errorCode'];
    if (errorCode != null) {
      final message = data['errorMessage'] as String? ?? '알 수 없는 오류';
      throw AladinApiException(
        code: _asInt(errorCode),
        message: message,
      );
    }

    final items = data['item'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(BestsellerBook.fromAladinJson)
        .toList();
  }

  /// 응답 본문을 Map 으로 디코드한다.
  ///
  /// output=js 응답이 String(plain) 으로 오므로 jsonDecode 로 직접 파싱한다.
  /// 혹시 dio 가 이미 Map 으로 파싱한 경우도 방어적으로 그대로 사용한다.
  Map<String, dynamic> _decodeBody(Object? body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isEmpty) {
        throw const FormatException('알라딘 응답이 비어 있습니다');
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const FormatException('알라딘 응답 형식이 올바르지 않습니다');
    }
    throw const FormatException('알라딘 응답을 해석할 수 없습니다');
  }

  /// errorCode 등 숫자 필드가 int/String 으로 섞여 와도 안전하게 int 로 만든다.
  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? -1;
    return -1;
  }
}

/// 알라딘 API 가 errorCode 를 반환했을 때 던지는 예외(키 오류 등).
class AladinApiException implements Exception {
  const AladinApiException({required this.code, required this.message});

  final int code;
  final String message;

  @override
  String toString() => '알라딘 API 오류($code): $message';
}
