// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [CaptureRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(captureRepository)
final captureRepositoryProvider = CaptureRepositoryProvider._();

/// [CaptureRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class CaptureRepositoryProvider
    extends
        $FunctionalProvider<
          CaptureRepository,
          CaptureRepository,
          CaptureRepository
        >
    with $Provider<CaptureRepository> {
  /// [CaptureRepository] 인스턴스를 제공한다.
  ///
  /// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  CaptureRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureRepositoryHash();

  @$internal
  @override
  $ProviderElement<CaptureRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CaptureRepository create(Ref ref) {
    return captureRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CaptureRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CaptureRepository>(value),
    );
  }
}

String _$captureRepositoryHash() => r'6acc9a801c3914aa7577227e3cb166e81193bb2f';

/// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.

@ProviderFor(captures)
final capturesProvider = CapturesFamily._();

/// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.

final class CapturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Capture>>,
          List<Capture>,
          Stream<List<Capture>>
        >
    with $FutureModifier<List<Capture>>, $StreamProvider<List<Capture>> {
  /// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.
  CapturesProvider._({
    required CapturesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'capturesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$capturesHash();

  @override
  String toString() {
    return r'capturesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Capture>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Capture>> create(Ref ref) {
    final argument = this.argument as String;
    return captures(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CapturesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$capturesHash() => r'b6ac5d202f5a391155157f9e08ce5645cd5435ac';

/// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.

final class CapturesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Capture>>, String> {
  CapturesFamily._()
    : super(
        retry: null,
        name: r'capturesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.

  CapturesProvider call(String bookId) =>
      CapturesProvider._(argument: bookId, from: this);

  @override
  String toString() => r'capturesProvider';
}

/// 구절 관련 사용자 액션(저장·삭제·수정)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 구절 데이터는
/// [capturesProvider] 스트림에서 흐른다.

@ProviderFor(CaptureActionNotifier)
final captureActionProvider = CaptureActionNotifierProvider._();

/// 구절 관련 사용자 액션(저장·삭제·수정)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 구절 데이터는
/// [capturesProvider] 스트림에서 흐른다.
final class CaptureActionNotifierProvider
    extends $AsyncNotifierProvider<CaptureActionNotifier, void> {
  /// 구절 관련 사용자 액션(저장·삭제·수정)을 수행하는 Notifier.
  ///
  /// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 구절 데이터는
  /// [capturesProvider] 스트림에서 흐른다.
  CaptureActionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureActionNotifierHash();

  @$internal
  @override
  CaptureActionNotifier create() => CaptureActionNotifier();
}

String _$captureActionNotifierHash() =>
    r'dd2466a0a5a74938b577fc470956f624f2ecb608';

/// 구절 관련 사용자 액션(저장·삭제·수정)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 구절 데이터는
/// [capturesProvider] 스트림에서 흐른다.

abstract class _$CaptureActionNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
