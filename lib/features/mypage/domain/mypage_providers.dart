import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../captures/domain/capture_providers.dart';

part 'mypage_providers.g.dart';

/// 현재 사용자가 공개한 구절 수 (MY-001 통계).
///
/// publicCaptures 컬렉션의 count() 집계 1회로 구한다. publicCaptures 는 구절
/// 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의 단일 진실이다.
/// 책별 captures 순회보다 가벼워 본 방식을 우선한다.
@riverpod
Future<int> publicCaptureCount(Ref ref) {
  return ref.watch(captureRepositoryProvider).countPublicCaptures();
}
