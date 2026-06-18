import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/capture.dart';
import '../data/repositories/capture_repository.dart';

part 'capture_providers.g.dart';

/// [CaptureRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
CaptureRepository captureRepository(Ref ref) {
  return CaptureRepository();
}

/// 특정 책의 구절 목록 스트림. family 형태로 bookId 를 받는다.
@riverpod
Stream<List<Capture>> captures(Ref ref, String bookId) {
  return ref.watch(captureRepositoryProvider).watchCaptures(bookId);
}

/// 구절 관련 사용자 액션(저장·삭제·수정)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 구절 데이터는
/// [capturesProvider] 스트림에서 흐른다.
@riverpod
class CaptureActionNotifier extends _$CaptureActionNotifier {
  @override
  Future<void> build() async {
    // 액션 전용 Notifier 이므로 초기 build 는 즉시 완료한다.
  }

  /// 구절을 저장한다. 성공 시 저장된 [Capture], 실패 시 null 을 반환한다.
  ///
  /// state 할당만 mounted 가드로 막고, 반환값은 항상 돌려준다(BK 단계에서
  /// dispose 로 저장 결과가 유실됐던 교훈 반영).
  Future<Capture?> save({
    required String bookId,
    required String text,
    int? page,
    String comment = '',
    required bool isPublic,
    required CaptureSource source,
    String? ocrRawText,
  }) async {
    state = const AsyncLoading();
    Capture? saved;
    final result = await AsyncValue.guard(() async {
      saved = await ref.read(captureRepositoryProvider).addCapture(
            bookId: bookId,
            text: text,
            page: page,
            comment: comment,
            isPublic: isPublic,
            source: source,
            ocrRawText: ocrRawText,
          );
    });
    if (ref.mounted) state = result;
    return result.hasError ? null : saved;
  }

  /// 구절을 삭제한다.
  Future<void> delete(String bookId, String captureId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () =>
          ref.read(captureRepositoryProvider).deleteCapture(bookId, captureId),
    );
    if (ref.mounted) state = result;
  }

  /// 구절을 수정한다. captureType 은 Repository 에서 재산정된다.
  ///
  /// 메서드명을 `edit` 로 둔다. AsyncNotifier 기반 클래스에는 프레임워크가
  /// 제공하는 `update` 가 이미 있어 `update` 로 두면 시그니처 충돌이 난다.
  Future<void> edit({
    required String bookId,
    required String captureId,
    required String text,
    int? page,
    String comment = '',
    required bool isPublic,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(captureRepositoryProvider).updateCapture(
            bookId: bookId,
            captureId: captureId,
            text: text,
            page: page,
            comment: comment,
            isPublic: isPublic,
          ),
    );
    if (ref.mounted) state = result;
  }
}
