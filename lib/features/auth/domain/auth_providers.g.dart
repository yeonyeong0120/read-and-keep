// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [AuthRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스 유지.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// [AuthRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스 유지.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// [AuthRepository] 인스턴스를 제공한다.
  ///
  /// keepAlive 로 앱 수명 동안 단일 인스턴스 유지.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'0eb4d0d9fa8c4a1b64438f6e0f88b1208eded646';

/// Firebase Auth 의 raw 인증 상태.
///
/// 로그인 / 로그아웃 / 토큰 만료 시점에 새 [User] (또는 null) 가 방출된다.
/// 일반 UI 는 [currentAppUserProvider] 를 사용한다. 본 Provider 는
/// 합성 Provider 와 Repository 디버깅용으로만 직접 사용한다.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Firebase Auth 의 raw 인증 상태.
///
/// 로그인 / 로그아웃 / 토큰 만료 시점에 새 [User] (또는 null) 가 방출된다.
/// 일반 UI 는 [currentAppUserProvider] 를 사용한다. 본 Provider 는
/// 합성 Provider 와 Repository 디버깅용으로만 직접 사용한다.

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Firebase Auth 의 raw 인증 상태.
  ///
  /// 로그인 / 로그아웃 / 토큰 만료 시점에 새 [User] (또는 null) 가 방출된다.
  /// 일반 UI 는 [currentAppUserProvider] 를 사용한다. 본 Provider 는
  /// 합성 Provider 와 Repository 디버깅용으로만 직접 사용한다.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'abe931a6d8380e57959015e347e0e6ede49e8ddf';

/// 현재 로그인된 사용자의 합성 정보 ([AppUser]) 를 제공한다.
///
/// [authStateProvider] 가 변할 때마다 Firestore 프로필을 다시 읽어 합성한다.
/// 미로그인 시 null 을 방출한다.

@ProviderFor(currentAppUser)
final currentAppUserProvider = CurrentAppUserProvider._();

/// 현재 로그인된 사용자의 합성 정보 ([AppUser]) 를 제공한다.
///
/// [authStateProvider] 가 변할 때마다 Firestore 프로필을 다시 읽어 합성한다.
/// 미로그인 시 null 을 방출한다.

final class CurrentAppUserProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  /// 현재 로그인된 사용자의 합성 정보 ([AppUser]) 를 제공한다.
  ///
  /// [authStateProvider] 가 변할 때마다 Firestore 프로필을 다시 읽어 합성한다.
  /// 미로그인 시 null 을 방출한다.
  CurrentAppUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAppUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAppUserHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return currentAppUser(ref);
  }
}

String _$currentAppUserHash() => r'406a77b6931b79d6490231eca9676fcf66256c2f';

/// 인증 관련 사용자 액션을 수행하는 AsyncNotifier.
///
/// 본 Notifier 는 "액션이 진행 중인가 / 실패했는가" 만 상태로 들고 있고,
/// 실제 사용자 정보는 [currentAppUserProvider] 에서 흐른다. 액션이 성공하면
/// authState 스트림이 자동 갱신되어 currentAppUser 가 새 값을 emit 한다.

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// 인증 관련 사용자 액션을 수행하는 AsyncNotifier.
///
/// 본 Notifier 는 "액션이 진행 중인가 / 실패했는가" 만 상태로 들고 있고,
/// 실제 사용자 정보는 [currentAppUserProvider] 에서 흐른다. 액션이 성공하면
/// authState 스트림이 자동 갱신되어 currentAppUser 가 새 값을 emit 한다.
final class AuthNotifierProvider
    extends $AsyncNotifierProvider<AuthNotifier, void> {
  /// 인증 관련 사용자 액션을 수행하는 AsyncNotifier.
  ///
  /// 본 Notifier 는 "액션이 진행 중인가 / 실패했는가" 만 상태로 들고 있고,
  /// 실제 사용자 정보는 [currentAppUserProvider] 에서 흐른다. 액션이 성공하면
  /// authState 스트림이 자동 갱신되어 currentAppUser 가 새 값을 emit 한다.
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'5c616a7256322f57c472d3e863aa58f0f95fcf94';

/// 인증 관련 사용자 액션을 수행하는 AsyncNotifier.
///
/// 본 Notifier 는 "액션이 진행 중인가 / 실패했는가" 만 상태로 들고 있고,
/// 실제 사용자 정보는 [currentAppUserProvider] 에서 흐른다. 액션이 성공하면
/// authState 스트림이 자동 갱신되어 currentAppUser 가 새 값을 emit 한다.

abstract class _$AuthNotifier extends $AsyncNotifier<void> {
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
