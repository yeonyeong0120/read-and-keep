// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [RecommendationRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(recommendationRepository)
final recommendationRepositoryProvider = RecommendationRepositoryProvider._();

/// [RecommendationRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class RecommendationRepositoryProvider
    extends
        $FunctionalProvider<
          RecommendationRepository,
          RecommendationRepository,
          RecommendationRepository
        >
    with $Provider<RecommendationRepository> {
  /// [RecommendationRepository] 인스턴스를 제공한다.
  ///
  /// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  RecommendationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecommendationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecommendationRepository create(Ref ref) {
    return recommendationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendationRepository>(value),
    );
  }
}

String _$recommendationRepositoryHash() =>
    r'2489f86bbdc429676b9979c0c924899c6160661a';

/// 추천 캐시 스트림. 캐시가 없으면 null 을 방출한다.

@ProviderFor(recommendationCache)
final recommendationCacheProvider = RecommendationCacheProvider._();

/// 추천 캐시 스트림. 캐시가 없으면 null 을 방출한다.

final class RecommendationCacheProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecommendationCache?>,
          RecommendationCache?,
          Stream<RecommendationCache?>
        >
    with
        $FutureModifier<RecommendationCache?>,
        $StreamProvider<RecommendationCache?> {
  /// 추천 캐시 스트림. 캐시가 없으면 null 을 방출한다.
  RecommendationCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationCacheHash();

  @$internal
  @override
  $StreamProviderElement<RecommendationCache?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RecommendationCache?> create(Ref ref) {
    return recommendationCache(ref);
  }
}

String _$recommendationCacheHash() =>
    r'88968e948df38297692080e88479965824eba344';

/// 현재 추천 신선도([DriftStatus]).
///
/// 책 수(booksProvider)·누적 구절 수(countTotalCaptures)·추천 캐시
/// (recommendationCacheProvider)를 조합해 [computeDriftStatus] 로 판정한다.
///
/// books/cache 는 Stream 이므로 `.future` 로 await 하면 로딩/에러가 본 Provider
/// 로 자연스럽게 전파된다(수동 플래그 불필요). 누적 구절 수는 1회성 집계라
/// 직접 호출하며, 책이 변동되면 위 watch 로 본 Provider 가 재평가되어 갱신된다.

@ProviderFor(driftStatus)
final driftStatusProvider = DriftStatusProvider._();

/// 현재 추천 신선도([DriftStatus]).
///
/// 책 수(booksProvider)·누적 구절 수(countTotalCaptures)·추천 캐시
/// (recommendationCacheProvider)를 조합해 [computeDriftStatus] 로 판정한다.
///
/// books/cache 는 Stream 이므로 `.future` 로 await 하면 로딩/에러가 본 Provider
/// 로 자연스럽게 전파된다(수동 플래그 불필요). 누적 구절 수는 1회성 집계라
/// 직접 호출하며, 책이 변동되면 위 watch 로 본 Provider 가 재평가되어 갱신된다.

final class DriftStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<DriftStatus>,
          DriftStatus,
          FutureOr<DriftStatus>
        >
    with $FutureModifier<DriftStatus>, $FutureProvider<DriftStatus> {
  /// 현재 추천 신선도([DriftStatus]).
  ///
  /// 책 수(booksProvider)·누적 구절 수(countTotalCaptures)·추천 캐시
  /// (recommendationCacheProvider)를 조합해 [computeDriftStatus] 로 판정한다.
  ///
  /// books/cache 는 Stream 이므로 `.future` 로 await 하면 로딩/에러가 본 Provider
  /// 로 자연스럽게 전파된다(수동 플래그 불필요). 누적 구절 수는 1회성 집계라
  /// 직접 호출하며, 책이 변동되면 위 watch 로 본 Provider 가 재평가되어 갱신된다.
  DriftStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driftStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driftStatusHash();

  @$internal
  @override
  $FutureProviderElement<DriftStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DriftStatus> create(Ref ref) {
    return driftStatus(ref);
  }
}

String _$driftStatusHash() => r'9d6ea3c0389f25e8c48f0508ec4a91c59b010c6a';
