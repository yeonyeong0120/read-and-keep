# recommendation feature

RC-001~003. Gemini 2단계 추천(1차 테마/키워드 → 2차 도서 추천), DriftStatus 4상태.

## 데이터 레이어(RC-A, 현재 단계)
- `data/models/recommendation_cache.dart` — 추천 캐시 모델(1차+2차 LLM 출력 + 스냅샷 메타).
  하위 모델: `RecommendationKeyword`, `RecommendedBook`.
  Firestore `users/{uid}/recommendation/latest` 매핑.
- `domain/drift_status.dart` — `DriftStatus { belowThreshold, noCache, fresh, stale }` +
  순수 함수 `computeDriftStatus(...)`.
- `data/repositories/recommendation_repository.dart` — 캐시 조회/저장, 누적 구절 수 집계,
  dismissedBooks 관리. 생성자 DI(FirebaseAuth/FirebaseFirestore).
- `domain/recommendation_providers.dart` — `recommendationRepositoryProvider`,
  `recommendationCacheProvider`, `driftStatusProvider`.
- 모델명/임계값 상수는 `lib/core/ai/ai_config.dart`(`AiConfig`)에 둔다.

## 다음 단계(RC-B)
- Gemini 1차/2차 LLM 호출 AsyncNotifier 추가(Firebase AI Logic).
- 추천 화면(RC-001~003) UI 연결.
