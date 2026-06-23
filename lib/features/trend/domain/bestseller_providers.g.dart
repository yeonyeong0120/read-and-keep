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

/// 알라딘 베스트셀러 목록(일회성 조회).
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
/// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.

@ProviderFor(bestsellers)
final bestsellersProvider = BestsellersFamily._();

/// 알라딘 베스트셀러 목록(일회성 조회).
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
/// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.

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
  /// 알라딘 베스트셀러 목록(일회성 조회).
  ///
  /// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
  /// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.
  BestsellersProvider._({
    required BestsellersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bestsellersProvider',
         isAutoDispose: true,
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

String _$bestsellersHash() => r'1d5d339ba95bd7764918382201cc4f1e66e88b32';

/// 알라딘 베스트셀러 목록(일회성 조회).
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
/// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.

final class BestsellersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BestsellerBook>>, int> {
  BestsellersFamily._()
    : super(
        retry: null,
        name: r'bestsellersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 알라딘 베스트셀러 목록(일회성 조회).
  ///
  /// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
  /// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.

  BestsellersProvider call({int maxResults = 10}) =>
      BestsellersProvider._(argument: maxResults, from: this);

  @override
  String toString() => r'bestsellersProvider';
}
