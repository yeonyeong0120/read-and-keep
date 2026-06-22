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

/// Gemini 호출 클라이언트. keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(geminiClient)
final geminiClientProvider = GeminiClientProvider._();

/// Gemini 호출 클라이언트. keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class GeminiClientProvider
    extends $FunctionalProvider<GeminiClient, GeminiClient, GeminiClient>
    with $Provider<GeminiClient> {
  /// Gemini 호출 클라이언트. keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  GeminiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiClientHash();

  @$internal
  @override
  $ProviderElement<GeminiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeminiClient create(Ref ref) {
    return geminiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiClient>(value),
    );
  }
}

String _$geminiClientHash() => r'bc18b16c5a6ed019feeeb1c616ce4b8899ba4f86';

/// 추천 LLM 서비스(1차 구절 분석 + 2차 도서 랭킹). keepAlive 로 단일 유지.
///
/// 2차 랭킹의 후보 수집에 카카오 검색이 필요해 [bookRepositoryProvider] 를
/// 함께 주입한다.

@ProviderFor(recommendationAiService)
final recommendationAiServiceProvider = RecommendationAiServiceProvider._();

/// 추천 LLM 서비스(1차 구절 분석 + 2차 도서 랭킹). keepAlive 로 단일 유지.
///
/// 2차 랭킹의 후보 수집에 카카오 검색이 필요해 [bookRepositoryProvider] 를
/// 함께 주입한다.

final class RecommendationAiServiceProvider
    extends
        $FunctionalProvider<
          RecommendationAiService,
          RecommendationAiService,
          RecommendationAiService
        >
    with $Provider<RecommendationAiService> {
  /// 추천 LLM 서비스(1차 구절 분석 + 2차 도서 랭킹). keepAlive 로 단일 유지.
  ///
  /// 2차 랭킹의 후보 수집에 카카오 검색이 필요해 [bookRepositoryProvider] 를
  /// 함께 주입한다.
  RecommendationAiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationAiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationAiServiceHash();

  @$internal
  @override
  $ProviderElement<RecommendationAiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecommendationAiService create(Ref ref) {
    return recommendationAiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecommendationAiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecommendationAiService>(value),
    );
  }
}

String _$recommendationAiServiceHash() =>
    r'fe0d1d0a9de763fc880cf35ce9c7c3cf2a3db160';

/// 전체 추천 생성 Notifier(1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
///
/// build 는 즉시 완료(idle)하며, 진입만으로는 생성이 일어나지 않는다. UI 의
/// 명시적 액션(첫 진입/갱신 버튼)에서 [generate] 를 호출해야 파이프라인이 돈다.
/// 에러는 state 로 전파하고(UI 가 AsyncValue.when 처리), state 할당만
/// ref.mounted 로 가드한다.

@ProviderFor(RecommendationGenerator)
final recommendationGeneratorProvider = RecommendationGeneratorProvider._();

/// 전체 추천 생성 Notifier(1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
///
/// build 는 즉시 완료(idle)하며, 진입만으로는 생성이 일어나지 않는다. UI 의
/// 명시적 액션(첫 진입/갱신 버튼)에서 [generate] 를 호출해야 파이프라인이 돈다.
/// 에러는 state 로 전파하고(UI 가 AsyncValue.when 처리), state 할당만
/// ref.mounted 로 가드한다.
final class RecommendationGeneratorProvider
    extends $AsyncNotifierProvider<RecommendationGenerator, void> {
  /// 전체 추천 생성 Notifier(1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
  ///
  /// build 는 즉시 완료(idle)하며, 진입만으로는 생성이 일어나지 않는다. UI 의
  /// 명시적 액션(첫 진입/갱신 버튼)에서 [generate] 를 호출해야 파이프라인이 돈다.
  /// 에러는 state 로 전파하고(UI 가 AsyncValue.when 처리), state 할당만
  /// ref.mounted 로 가드한다.
  RecommendationGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationGeneratorHash();

  @$internal
  @override
  RecommendationGenerator create() => RecommendationGenerator();
}

String _$recommendationGeneratorHash() =>
    r'7736a07c15530922cd9162c012c4ed54cf5e1f3d';

/// 전체 추천 생성 Notifier(1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
///
/// build 는 즉시 완료(idle)하며, 진입만으로는 생성이 일어나지 않는다. UI 의
/// 명시적 액션(첫 진입/갱신 버튼)에서 [generate] 를 호출해야 파이프라인이 돈다.
/// 에러는 state 로 전파하고(UI 가 AsyncValue.when 처리), state 할당만
/// ref.mounted 로 가드한다.

abstract class _$RecommendationGenerator extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
