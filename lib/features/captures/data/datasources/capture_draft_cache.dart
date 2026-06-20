import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/capture.dart';

/// 오프라인 시 작성한 구절을 임시 저장하는 draft 캐시.
///
/// Hive `draft_captures` Box 를 JSON 문자열 방식으로 다룬다(어댑터 미사용,
/// kakao_book_cache 와 동일한 패턴). key 는 임시 captureId, value 는
/// `{ capture 필드..., savedAt }` JSON 문자열이다.
///
/// Box 의 초기화(Hive.initFlutter / openBox)는 본 클래스가 아니라 앱 시작 시
/// 1회 수행한다(main.dart 참고).
class CaptureDraftCache {
  CaptureDraftCache({Box<String>? box})
      : _box = box ?? Hive.box<String>(boxName);

  /// draft Box 이름.
  static const String boxName = 'draft_captures';

  final Box<String> _box;

  /// 임시 captureId 발급. 패키지 추가 없이 마이크로초 타임스탬프 기반으로 충분하다.
  static String newDraftId() =>
      'draft_${DateTime.now().microsecondsSinceEpoch}';

  /// draft 저장. [Capture.captureId] 가 비어 있으면 새 임시 id 를 발급한다.
  ///
  /// 저장에 사용한(또는 새로 발급한) id 를 반환한다.
  Future<String> save(Capture capture) async {
    final id =
        capture.captureId.isEmpty ? newDraftId() : capture.captureId;
    final payload = jsonEncode({
      'captureId': id,
      'bookId': capture.bookId,
      'text': capture.text,
      'page': capture.page,
      'comment': capture.comment,
      'isPublic': capture.isPublic,
      'captureType': capture.captureType,
      'captureSource': capture.captureSource,
      'ocrRawText': capture.ocrRawText,
      'capturedAt': capture.capturedAt.millisecondsSinceEpoch,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _box.put(id, payload);
    return id;
  }

  /// 저장된 모든 draft 를 [Capture] 로 복원해 반환한다.
  List<Capture> readAll() {
    return _box.values.map((raw) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      return Capture(
        captureId: data['captureId'] as String? ?? '',
        bookId: data['bookId'] as String? ?? '',
        text: text,
        page: (data['page'] as num?)?.toInt(),
        comment: data['comment'] as String? ?? '',
        isPublic: data['isPublic'] as bool? ?? false,
        captureType:
            data['captureType'] as String? ?? Capture.classifyType(text),
        captureSource:
            data['captureSource'] as String? ?? CaptureSource.manual.value,
        ocrRawText: data['ocrRawText'] as String?,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(
          (data['capturedAt'] as num?)?.toInt() ?? 0,
        ),
      );
    }).toList();
  }

  /// 단건 draft 삭제(서버 동기화 완료 후 호출).
  Future<void> delete(String captureId) async {
    await _box.delete(captureId);
  }
}
