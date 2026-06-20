// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱 전역 라우터.
///
/// 인증 상태([currentAppUserProvider])에 따라 인증/비인증 경로를 자동 분기한다.
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// 앱 전역 라우터.
///
/// 인증 상태([currentAppUserProvider])에 따라 인증/비인증 경로를 자동 분기한다.
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// 앱 전역 라우터.
  ///
  /// 인증 상태([currentAppUserProvider])에 따라 인증/비인증 경로를 자동 분기한다.
  /// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'd16f01507e301a1abc7978eee0f018e83c85a4e9';
