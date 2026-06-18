import 'package:cloud_firestore/cloud_firestore.dart';

/// 구절 저장 출처.
///
/// 'camera'/'gallery' 는 OCR 경로, 'manual' 은 직접 입력이다.
enum CaptureSource {
  camera,
  gallery,
  manual;

  /// Firestore 저장용 문자열.
  String get value => name;

  /// 문자열에서 enum 으로 변환. 알 수 없는 값은 manual 로 보정한다.
  static CaptureSource fromString(String? raw) {
    return CaptureSource.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CaptureSource.manual,
    );
  }
}

/// Firestore `users/{uid}/books/{bookId}/captures/{captureId}` 문서와 매핑되는
/// 구절(capture) 모델.
///
/// 사용자가 카메라/갤러리 OCR 또는 직접 입력으로 저장한 한 구절을 표현한다.
/// 공개 여부([isPublic])는 Privacy by Default 정책에 따라 기본 비공개다.
class Capture {
  const Capture({
    required this.captureId,
    required this.bookId,
    required this.text,
    this.page,
    this.comment = '',
    this.isPublic = false,
    required this.captureType,
    required this.captureSource,
    this.ocrRawText,
    required this.capturedAt,
  });

  /// Firestore 문서 ID.
  final String captureId;

  /// 상위 책 문서 ID.
  final String bookId;

  /// 구절 본문.
  final String text;

  /// 페이지 번호. 입력하지 않으면 null.
  final int? page;

  /// 코멘트. 없으면 빈 문자열.
  final String comment;

  /// 공개 여부. 기본 비공개(Privacy by Default).
  final bool isPublic;

  /// 'short'(80자 미만) / 'long'(80자 이상). 저장 시 [classifyType] 으로 자동 산정.
  final String captureType;

  /// 'camera' / 'gallery' / 'manual'.
  final String captureSource;

  /// OCR 원본 텍스트. 직접 입력(manual)이면 null.
  final String? ocrRawText;

  /// 저장 시각.
  final DateTime capturedAt;

  /// captureType 산정 임계값(자). 미만이면 short, 이상이면 long.
  static const int longThreshold = 80;

  /// 본문 길이로 captureType('short'/'long') 을 산정한다.
  static String classifyType(String text) =>
      text.length >= longThreshold ? 'long' : 'short';

  /// Firestore 문서에서 모델로 변환. Timestamp 는 DateTime 으로 바꾸고,
  /// 누락 필드는 안전한 기본값으로 채운다.
  factory Capture.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final text = data['text'] as String? ?? '';

    return Capture(
      captureId: doc.id,
      bookId: data['bookId'] as String? ?? '',
      text: text,
      page: (data['page'] as num?)?.toInt(),
      comment: data['comment'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      captureType: data['captureType'] as String? ?? classifyType(text),
      captureSource:
          data['captureSource'] as String? ?? CaptureSource.manual.value,
      ocrRawText: data['ocrRawText'] as String?,
      capturedAt: (data['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 신규 저장 시 Firestore 에 쓸 데이터.
  ///
  /// [capturedAt] 은 클라이언트 시간이 아닌 서버 타임스탬프를 쓰고,
  /// [captureType] 은 본문 길이로 다시 산정한다.
  Map<String, dynamic> toFirestoreOnCreate() {
    return {
      'bookId': bookId,
      'text': text,
      'page': page,
      'comment': comment,
      'isPublic': isPublic,
      'captureType': classifyType(text),
      'captureSource': captureSource,
      'ocrRawText': ocrRawText,
      'capturedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 일부 필드만 교체한 사본을 만든다.
  ///
  /// 신규 저장 시 Firestore 문서 ID 를 확정한 뒤 [captureId] 만 채워 반환하는 데 쓴다.
  Capture copyWith({
    String? captureId,
    String? bookId,
    String? text,
    int? page,
    String? comment,
    bool? isPublic,
    String? captureType,
    String? captureSource,
    String? ocrRawText,
    DateTime? capturedAt,
  }) {
    return Capture(
      captureId: captureId ?? this.captureId,
      bookId: bookId ?? this.bookId,
      text: text ?? this.text,
      page: page ?? this.page,
      comment: comment ?? this.comment,
      isPublic: isPublic ?? this.isPublic,
      captureType: captureType ?? this.captureType,
      captureSource: captureSource ?? this.captureSource,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
