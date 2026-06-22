// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mypage_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
