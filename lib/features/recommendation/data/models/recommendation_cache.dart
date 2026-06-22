import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 의 `List<dynamic>` 를 `List<String>` 으로 안전 변환한다.
List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((e) => e.toString()).toList();
}

/// Firestore 의 `List<dynamic>` 를 `List<Map<String, dynamic>>` 로 안전 변환한다.
List<Map<String, dynamic>> _objectList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map<Object?, Object?>>()
      .map(Map<String, dynamic>.from)
      .toList();
}

/// 1차 LLM 키워드 칩. (예: label="성장", icon="seedling")
///
/// LLM JSON 파싱과 Firestore 직렬화에 [fromJson]/[toJson] 을 공용으로 쓴다.
class RecommendationKeyword {
  const RecommendationKeyword({
    required this.label,
    required this.icon,
  });

  final String label;
  final String icon;

  factory RecommendationKeyword.fromJson(Map<String, dynamic> json) {
    return RecommendationKeyword(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'icon': icon,
    };
  }
}

/// 2차 LLM 추천 도서. todaysPick(오늘의 추천) / alsoRecommended(함께 추천) 항목.
///
/// [linkedCaptureIds] 는 추천 근거가 된 사용자의 구절 ID 목록,
/// [themeMatch] 는 매칭된 테마 설명, [relatedKeywords] 는 연관 키워드다.
class RecommendedBook {
  const RecommendedBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.reason,
    required this.linkedCaptureIds,
    required this.themeMatch,
    required this.relatedKeywords,
  });

  final String bookId;
  final String title;
  final String author;

  /// 표지 이미지 URL. 환각 차단 단계에서 카카오 후보(thumbnail)로 채운다.
  /// 후보에 표지가 없으면 빈 문자열(화면이 빈 표지 위젯으로 처리).
  final String coverUrl;
  final String reason;
  final List<String> linkedCaptureIds;
  final String themeMatch;
  final List<String> relatedKeywords;

  factory RecommendedBook.fromJson(Map<String, dynamic> json) {
    return RecommendedBook(
      bookId: json['bookId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      linkedCaptureIds: _stringList(json['linkedCaptureIds']),
      themeMatch: json['themeMatch'] as String? ?? '',
      relatedKeywords: _stringList(json['relatedKeywords']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'reason': reason,
      'linkedCaptureIds': linkedCaptureIds,
      'themeMatch': themeMatch,
      'relatedKeywords': relatedKeywords,
    };
  }
}

/// 추천 캐시. Firestore `users/{uid}/recommendation/latest` 문서와 매핑된다.
///
/// 1차 LLM 출력(themes/keywords/summary)과 2차 LLM 출력(todaysPick/
/// alsoRecommended)을 한 문서에 함께 담는다. 더불어 DriftStatus(신선도) 판정에
/// 쓰는 스냅샷 메타(generatedAt/snapshotCaptureCount/snapshotBookCount)를 둔다.
class RecommendationCache {
  const RecommendationCache({
    required this.themes,
    required this.keywords,
    required this.summary,
    required this.todaysPick,
    required this.alsoRecommended,
    required this.generatedAt,
    required this.snapshotCaptureCount,
    required this.snapshotBookCount,
  });

  // --- 1차 LLM 결과 ---

  /// 사용자의 독서 취향에서 추출한 핵심 테마 목록.
  final List<String> themes;

  /// 1차 LLM 키워드 칩 목록.
  final List<RecommendationKeyword> keywords;

  /// 취향 요약 문장.
  final String summary;

  // --- 2차 LLM 결과 ---

  /// 오늘의 추천 1권. 생성 실패 시 null.
  final RecommendedBook? todaysPick;

  /// 함께 추천하는 도서 목록.
  final List<RecommendedBook> alsoRecommended;

  // --- 스냅샷 메타(DriftStatus 판정용) ---

  /// 캐시 생성 시각.
  final DateTime generatedAt;

  /// 캐시 생성 당시의 누적 구절 수. 현재 값과 비교해 신선도를 판정한다.
  final int snapshotCaptureCount;

  /// 캐시 생성 당시의 책 수.
  final int snapshotBookCount;

  factory RecommendationCache.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final generatedAtValue = data['generatedAt'];
    final todaysPickValue = data['todaysPick'];

    return RecommendationCache(
      themes: _stringList(data['themes']),
      keywords: _objectList(data['keywords'])
          .map(RecommendationKeyword.fromJson)
          .toList(),
      summary: data['summary'] as String? ?? '',
      todaysPick: todaysPickValue is Map
          ? RecommendedBook.fromJson(
              Map<String, dynamic>.from(todaysPickValue),
            )
          : null,
      alsoRecommended: _objectList(data['alsoRecommended'])
          .map(RecommendedBook.fromJson)
          .toList(),
      generatedAt: generatedAtValue is Timestamp
          ? generatedAtValue.toDate()
          : DateTime.now(),
      snapshotCaptureCount: (data['snapshotCaptureCount'] as num?)?.toInt() ?? 0,
      snapshotBookCount: (data['snapshotBookCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'themes': themes,
      'keywords': keywords.map((k) => k.toJson()).toList(),
      'summary': summary,
      'todaysPick': todaysPick?.toJson(),
      'alsoRecommended': alsoRecommended.map((b) => b.toJson()).toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'snapshotCaptureCount': snapshotCaptureCount,
      'snapshotBookCount': snapshotBookCount,
    };
  }
}
