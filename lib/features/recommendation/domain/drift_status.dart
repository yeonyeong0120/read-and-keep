import '../../../core/ai/ai_config.dart';
import '../data/models/recommendation_cache.dart';

/// 추천 신선도(Drift) 상태.
///
/// - [belowThreshold] : 추천 활성화 조건(최소 책/구절 수) 미달.
/// - [noCache]        : 조건은 충족하나 아직 생성된 추천 캐시가 없음.
/// - [fresh]          : 캐시가 현재 구절 수와 일치(최신).
/// - [stale]          : 캐시 생성 이후 구절 수가 변동되어 갱신 권장.
enum DriftStatus {
  belowThreshold,
  noCache,
  fresh,
  stale,
}

/// 현재 상태로부터 [DriftStatus] 를 판정하는 순수 함수.
///
/// 판정 순서:
/// 1) 책 수 또는 누적 구절 수가 임계값 미만 → [DriftStatus.belowThreshold]
/// 2) 캐시 없음 → [DriftStatus.noCache]
/// 3) 캐시의 snapshotCaptureCount 가 현재 구절 수와 같음 → [DriftStatus.fresh]
/// 4) 그 외(구절 수 변동) → [DriftStatus.stale]
DriftStatus computeDriftStatus({
  required int bookCount,
  required int captureCount,
  RecommendationCache? cache,
}) {
  if (bookCount < AiConfig.recommendationMinBooks ||
      captureCount < AiConfig.recommendationMinCaptures) {
    return DriftStatus.belowThreshold;
  }

  if (cache == null) {
    return DriftStatus.noCache;
  }

  if (cache.snapshotCaptureCount == captureCount) {
    return DriftStatus.fresh;
  }

  return DriftStatus.stale;
}
