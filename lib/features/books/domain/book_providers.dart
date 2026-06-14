import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/book.dart';
import '../data/models/kakao_book.dart';
import '../data/repositories/book_repository.dart';

part 'book_providers.g.dart';

/// [BookRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
BookRepository bookRepository(Ref ref) {
  return BookRepository();
}

/// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
///
/// 기본값은 최근 기록순([BookSort.recentRecord]).
@riverpod
Stream<List<Book>> books(Ref ref, {BookSort sort = BookSort.recentRecord}) {
  return ref.watch(bookRepositoryProvider).watchBooks(sort: sort);
}

/// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.
@riverpod
Stream<Book> book(Ref ref, String bookId) {
  return ref.watch(bookRepositoryProvider).watchBook(bookId);
}

/// 카카오 책 검색 상태를 관리하는 Notifier.
///
/// 검색 결과 리스트를 AsyncValue 로 들고 있으며, 검색어 입력에 따라
/// [search] 로 갱신하고 입력이 비면 [clear] 로 초기화한다.
@riverpod
class BookSearchNotifier extends _$BookSearchNotifier {
  @override
  Future<List<KakaoBook>> build() async {
    // 초기 상태는 빈 결과.
    return const <KakaoBook>[];
  }

  /// 검색 실행.
  Future<void> search(String query) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(bookRepositoryProvider).searchBooks(query),
    );
    // dispose 후 state 할당 방지.
    if (!ref.mounted) return;
    state = result;
  }

  /// 검색어가 비워졌을 때 결과를 비운다.
  void clear() {
    state = const AsyncData(<KakaoBook>[]);
  }
}

/// 책 관련 사용자 액션(등록·선택)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 책 데이터는
/// [booksProvider]/[bookProvider] 스트림에서 흐른다.
@riverpod
class BookActionNotifier extends _$BookActionNotifier {
  @override
  Future<void> build() async {
    // 액션 전용 Notifier 이므로 초기 build 는 즉시 완료한다.
  }

  /// 카카오 검색 결과를 책장에 등록한다. 성공 시 등록된 [Book], 실패 시 null.
  Future<Book?> addFromKakao(KakaoBook kakaoBook) async {
    state = const AsyncLoading();
    Book? added;
    final result = await AsyncValue.guard(() async {
      added = await ref.read(bookRepositoryProvider).addBookFromKakao(kakaoBook);
    });
    if (!ref.mounted) return null;
    state = result;
    return result.hasError ? null : added;
  }

  /// 기존 책 선택 시 마지막 선택 시각을 갱신한다.
  Future<void> selectExisting(String bookId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(bookRepositoryProvider).touchLastSelected(bookId),
    );
    if (!ref.mounted) return;
    state = result;
  }
}
