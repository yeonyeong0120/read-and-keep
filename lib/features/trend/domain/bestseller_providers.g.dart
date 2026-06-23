// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bestseller_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [BestsellerRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(bestsellerRepository)
final bestsellerRepositoryProvider = BestsellerRepositoryProvider._();

/// [BestsellerRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class BestsellerRepositoryProvider
    extends
        $FunctionalProvider<
          BestsellerRepository,
          BestsellerRepository,
          BestsellerRepository
        >
    with $Provider<BestsellerRepository> {
  /// [BestsellerRepository] 인스턴스를 제공한다.
  ///
  /// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  BestsellerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bestsellerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bestsellerRepositoryHash();

  @$internal
  @override
  $ProviderElement<BestsellerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BestsellerRepository create(Ref ref) {
    return bestsellerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BestsellerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BestsellerRepository>(value),
    );
  }
}

String _$bestsellerRepositoryHash() =>
    r'a79af346bad2cb0f15bc2a145336f15cee7d1fa1';

/// 알라딘 베스트셀러 목록.
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
/// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
/// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
/// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.

@ProviderFor(bestsellers)
final bestsellersProvider = BestsellersFamily._();

/// 알라딘 베스트셀러 목록.
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
/// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
/// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
/// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.

final class BestsellersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BestsellerBook>>,
          List<BestsellerBook>,
          FutureOr<List<BestsellerBook>>
        >
    with
        $FutureModifier<List<BestsellerBook>>,
        $FutureProvider<List<BestsellerBook>> {
  /// 알라딘 베스트셀러 목록.
  ///
  /// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
  /// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
  /// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
  /// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.
  BestsellersProvider._({
    required BestsellersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bestsellersProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bestsellersHash();

  @override
  String toString() {
    return r'bestsellersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BestsellerBook>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BestsellerBook>> create(Ref ref) {
    final argument = this.argument as int;
    return bestsellers(ref, maxResults: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BestsellersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bestsellersHash() => r'0bbd86331d76dfa7114bdb7c95c4729fd617a42d';

/// 알라딘 베스트셀러 목록.
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
/// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
/// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
/// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.

final class BestsellersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BestsellerBook>>, int> {
  BestsellersFamily._()
    : super(
        retry: null,
        name: r'bestsellersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 알라딘 베스트셀러 목록.
  ///
  /// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
  /// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
  /// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
  /// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.

  BestsellersProvider call({int maxResults = 10}) =>
      BestsellersProvider._(argument: maxResults, from: this);

  @override
  String toString() => r'bestsellersProvider';
}
