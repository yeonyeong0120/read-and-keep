import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../captures/domain/capture_providers.dart';
import '../data/withdrawal_repository.dart';

part 'mypage_providers.g.dart';

/// [WithdrawalRepository] 인스턴스를 제공한다.
@Riverpod(keepAlive: true)
WithdrawalRepository withdrawalRepository(Ref ref) {
  return WithdrawalRepository();
}

/// 현재 사용자가 공개한 구절 수 (MY-001 통계).
///
/// publicCaptures 컬렉션의 count() 집계 1회로 구한다. publicCaptures 는 구절
/// 공개/비공개 전환 시 정확히 생성·삭제되므로 "공개한 구절 수"의 단일 진실이다.
/// 책별 captures 순회보다 가벼워 본 방식을 우선한다.
@riverpod
Future<int> publicCaptureCount(Ref ref) {
  return ref.watch(captureRepositoryProvider).countPublicCaptures();
}

/// 회원 탈퇴 요청 액션 Notifier (MY-008).
///
/// "진행 중/실패" 만 상태로 들고, 탈퇴 요청 기록만 수행한다. 기록 성공 후의
/// 로그아웃(signOut)·화면 전환은 호출하는 화면에서 순서를 제어한다.
@riverpod
class WithdrawalNotifier extends _$WithdrawalNotifier {
  @override
  Future<void> build() async {
    // 액션 전용 Notifier 이므로 초기 build 는 즉시 완료한다.
  }

  /// 탈퇴 요청 기록을 생성한다. [reason]·[message] 는 선택값.
  Future<void> submit({String? reason, String? message}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(withdrawalRepositoryProvider).requestWithdrawal(
            reason: reason,
            message: message,
          ),
    );
    if (!ref.mounted) return;
    state = result;
  }
}
