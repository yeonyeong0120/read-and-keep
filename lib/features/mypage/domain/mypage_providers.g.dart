// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mypage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [WithdrawalRepository] 인스턴스를 제공한다.

@ProviderFor(withdrawalRepository)
final withdrawalRepositoryProvider = WithdrawalRepositoryProvider._();

/// [WithdrawalRepository] 인스턴스를 제공한다.

final class WithdrawalRepositoryProvider
    extends
        $FunctionalProvider<
          WithdrawalRepository,
          WithdrawalRepository,
          WithdrawalRepository
        >
    with $Provider<WithdrawalRepository> {
  /// [WithdrawalRepository] 인스턴스를 제공한다.
  WithdrawalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalRepositoryHash();

  @$internal
  @override
  $ProviderElement<WithdrawalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawalRepository create(Ref ref) {
    return withdrawalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawalRepository>(value),
    );
  }
}

String _$withdrawalRepositoryHash() =>
    r'3827aee19786f6b3e9a79325780080ed30f5853f';

/// 현재 사용자가 공개한 구절 수 (MY-001 통계).
///
/// publicCaptures 컬렉션의 count() 집계 1회로 구한다. publicCaptures 는 구절
/// 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의 단일 진실이다.
/// 책별 captures 순회보다 가벼워 본 방식을 우선한다.

@ProviderFor(publicCaptureCount)
final publicCaptureCountProvider = PublicCaptureCountProvider._();

/// 현재 사용자가 공개한 구절 수 (MY-001 통계).
///
/// publicCaptures 컬렉션의 count() 집계 1회로 구한다. publicCaptures 는 구절
/// 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의 단일 진실이다.
/// 책별 captures 순회보다 가벼워 본 방식을 우선한다.

final class PublicCaptureCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// 현재 사용자가 공개한 구절 수 (MY-001 통계).
  ///
  /// publicCaptures 컬렉션의 count() 집계 1회로 구한다. publicCaptures 는 구절
  /// 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의 단일 진실이다.
  /// 책별 captures 순회보다 가벼워 본 방식을 우선한다.
  PublicCaptureCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'publicCaptureCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$publicCaptureCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return publicCaptureCount(ref);
  }
}

String _$publicCaptureCountHash() =>
    r'71071edd6ad80462c81dc2b6e6b1dc6a89c6a1e7';

/// 회원 탈퇴 요청 액션 Notifier (MY-008).
///
/// "진행 중/실패" 만 상태로 들고, 탈퇴 요청 기록만 수행한다. 기록 성공 후의
/// 로그아웃(signOut)·화면 전환은 호출하는 화면에서 순서를 제어한다.

@ProviderFor(WithdrawalNotifier)
final withdrawalProvider = WithdrawalNotifierProvider._();

/// 회원 탈퇴 요청 액션 Notifier (MY-008).
///
/// "진행 중/실패" 만 상태로 들고, 탈퇴 요청 기록만 수행한다. 기록 성공 후의
/// 로그아웃(signOut)·화면 전환은 호출하는 화면에서 순서를 제어한다.
final class WithdrawalNotifierProvider
    extends $AsyncNotifierProvider<WithdrawalNotifier, void> {
  /// 회원 탈퇴 요청 액션 Notifier (MY-008).
  ///
  /// "진행 중/실패" 만 상태로 들고, 탈퇴 요청 기록만 수행한다. 기록 성공 후의
  /// 로그아웃(signOut)·화면 전환은 호출하는 화면에서 순서를 제어한다.
  WithdrawalNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalNotifierHash();

  @$internal
  @override
  WithdrawalNotifier create() => WithdrawalNotifier();
}

String _$withdrawalNotifierHash() =>
    r'ece004ae3f444de0ff68c66befda8d7a669bdf37';

/// 회원 탈퇴 요청 액션 Notifier (MY-008).
///
/// "진행 중/실패" 만 상태로 들고, 탈퇴 요청 기록만 수행한다. 기록 성공 후의
/// 로그아웃(signOut)·화면 전환은 호출하는 화면에서 순서를 제어한다.

abstract class _$WithdrawalNotifier extends $AsyncNotifier<void> {
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
