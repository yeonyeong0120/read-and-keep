import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../books/domain/book_providers.dart';
import '../data/models/recommendation_cache.dart';
import '../data/repositories/recommendation_repository.dart';
import 'drift_status.dart';

part 'recommendation_providers.g.dart';

/// [RecommendationRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
RecommendationRepository recommendationRepository(Ref ref) {
  return RecommendationRepository();
}

/// 추천 캐시 스트림. 캐시가 없으면 null 을 방출한다.
@riverpod
Stream<RecommendationCache?> recommendationCache(Ref ref) {
  return ref.watch(recommendationRepositoryProvider).watchCache();
}

/// 현재 추천 신선도([DriftStatus]).
///
/// 책 수(booksProvider)·누적 구절 수(countTotalCaptures)·추천 캐시
/// (recommendationCacheProvider)를 조합해 [computeDriftStatus] 로 판정한다.
///
/// books/cache 는 Stream 이므로 `.future` 로 await 하면 로딩/에러가 본 Provider
/// 로 자연스럽게 전파된다(수동 플래그 불필요). 누적 구절 수는 1회성 집계라
/// 직접 호출하며, 책이 변동되면 위 watch 로 본 Provider 가 재평가되어 갱신된다.
@riverpod
Future<DriftStatus> driftStatus(Ref ref) async {
  final books = await ref.watch(booksProvider().future);
  final cache = await ref.watch(recommendationCacheProvider.future);

  final captureCount =
      await ref.watch(recommendationRepositoryProvider).countTotalCaptures();

  return computeDriftStatus(
    bookCount: books.length,
    captureCount: captureCount,
    cache: cache,
  );
}

// LLM 호출 Notifier 는 이번 단계(RC-A)에서 만들지 않는다.
// TODO: RC-B 에서 추천 생성 AsyncNotifier 를 추가한다.
