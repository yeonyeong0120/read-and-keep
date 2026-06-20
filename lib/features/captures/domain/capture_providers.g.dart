// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CaptureRepository Provider

@ProviderFor(captureRepository)
final captureRepositoryProvider = CaptureRepositoryProvider._();

/// CaptureRepository Provider

final class CaptureRepositoryProvider
    extends
        $FunctionalProvider<
          CaptureRepository,
          CaptureRepository,
          CaptureRepository
        >
    with $Provider<CaptureRepository> {
  /// CaptureRepository Provider
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

/// 특정 책에 저장된 구절 목록 Provider

@ProviderFor(bookCaptures)
final bookCapturesProvider = BookCapturesFamily._();

/// 특정 책에 저장된 구절 목록 Provider

final class BookCapturesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Capture>>,
          List<Capture>,
          Stream<List<Capture>>
        >
    with $FutureModifier<List<Capture>>, $StreamProvider<List<Capture>> {
  /// 특정 책에 저장된 구절 목록 Provider
  BookCapturesProvider._({
    required BookCapturesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookCapturesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookCapturesHash();

  @override
  String toString() {
    return r'bookCapturesProvider'
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
    return bookCaptures(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookCapturesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookCapturesHash() => r'af1490ea07c47c90c8b44a4481a8fced066bd4ac';

/// 특정 책에 저장된 구절 목록 Provider

final class BookCapturesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Capture>>, String> {
  BookCapturesFamily._()
    : super(
        retry: null,
        name: r'bookCapturesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 특정 책에 저장된 구절 목록 Provider

  BookCapturesProvider call({required String bookId}) =>
      BookCapturesProvider._(argument: bookId, from: this);

  @override
  String toString() => r'bookCapturesProvider';
}

/// 문장 저장/삭제 같은 액션을 담당하는 Provider

@ProviderFor(CaptureActionNotifier)
final captureActionProvider = CaptureActionNotifierProvider._();

/// 문장 저장/삭제 같은 액션을 담당하는 Provider
final class CaptureActionNotifierProvider
    extends $AsyncNotifierProvider<CaptureActionNotifier, void> {
  /// 문장 저장/삭제 같은 액션을 담당하는 Provider
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
    r'ab8353098df7216b8f8c92a1a47bb088837fa2ab';

/// 문장 저장/삭제 같은 액션을 담당하는 Provider

abstract class _$CaptureActionNotifier extends $AsyncNotifier<void> {
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
