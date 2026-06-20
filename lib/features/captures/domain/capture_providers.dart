import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/capture.dart';
import '../data/repositories/capture_repository.dart';

part 'capture_providers.g.dart';

/// CaptureRepository Provider
@Riverpod(keepAlive: true)
CaptureRepository captureRepository(Ref ref) {
  return CaptureRepository();
}

/// 특정 책에 저장된 구절 목록 Provider
@riverpod
Stream<List<Capture>> bookCaptures(
  Ref ref, {
  required String bookId,
}) {
  return ref.watch(captureRepositoryProvider).watchCapturesByBook(bookId);
}

/// 문장 저장/삭제 같은 액션을 담당하는 Provider
@riverpod
class CaptureActionNotifier extends _$CaptureActionNotifier {
  @override
  Future<void> build() async {
    // 액션 전용 Notifier라서 초기 상태는 비워둔다.
  }

  Future<void> addCapture({
    required String bookId,
    required String bookTitle,
    required String quote,
    required String comment,
    required int? pageNumber,
    required bool isPublic,
    required CaptureSource source,
    String? ocrRawText,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(captureRepositoryProvider).addCapture(
            bookId: bookId,
            bookTitle: bookTitle,
            quote: quote,
            comment: comment,
            pageNumber: pageNumber,
            isPublic: isPublic,
            source: source,
            ocrRawText: ocrRawText,
          );
    });
  }

  Future<void> deleteCapture({
    required String bookId,
    required String captureId,
    bool hadComment = false,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(captureRepositoryProvider).deleteCapture(
            bookId: bookId,
            captureId: captureId,
            hadComment: hadComment,
          );
    });
  }
}