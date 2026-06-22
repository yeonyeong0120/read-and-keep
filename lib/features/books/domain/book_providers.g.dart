// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [BookRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

@ProviderFor(bookRepository)
final bookRepositoryProvider = BookRepositoryProvider._();

/// [BookRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.

final class BookRepositoryProvider
    extends $FunctionalProvider<BookRepository, BookRepository, BookRepository>
    with $Provider<BookRepository> {
  /// [BookRepository] 인스턴스를 제공한다.
  ///
  /// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
  BookRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BookRepository create(Ref ref) {
    return bookRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookRepository>(value),
    );
  }
}

String _$bookRepositoryHash() => r'132abdc4cd66b9de7ecd2d0442af279ccc530ab1';

/// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
///
/// 기본값은 최근 기록순([BookSort.recentRecord]).

@ProviderFor(books)
final booksProvider = BooksFamily._();

/// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
///
/// 기본값은 최근 기록순([BookSort.recentRecord]).

final class BooksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Book>>,
          List<Book>,
          Stream<List<Book>>
        >
    with $FutureModifier<List<Book>>, $StreamProvider<List<Book>> {
  /// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
  ///
  /// 기본값은 최근 기록순([BookSort.recentRecord]).
  BooksProvider._({
    required BooksFamily super.from,
    required BookSort super.argument,
  }) : super(
         retry: null,
         name: r'booksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$booksHash();

  @override
  String toString() {
    return r'booksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Book>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Book>> create(Ref ref) {
    final argument = this.argument as BookSort;
    return books(ref, sort: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BooksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$booksHash() => r'a139761143df9665d6f764457af8da35019b219a';

/// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
///
/// 기본값은 최근 기록순([BookSort.recentRecord]).

final class BooksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Book>>, BookSort> {
  BooksFamily._()
    : super(
        retry: null,
        name: r'booksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 책장 목록 스트림. 정렬 기준은 [BookSort] 를 재사용한다.
  ///
  /// 기본값은 최근 기록순([BookSort.recentRecord]).

  BooksProvider call({BookSort sort = BookSort.recentRecord}) =>
      BooksProvider._(argument: sort, from: this);

  @override
  String toString() => r'booksProvider';
}

/// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.

@ProviderFor(book)
final bookProvider = BookFamily._();

/// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.

final class BookProvider
    extends $FunctionalProvider<AsyncValue<Book>, Book, Stream<Book>>
    with $FutureModifier<Book>, $StreamProvider<Book> {
  /// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.
  BookProvider._({
    required BookFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookHash();

  @override
  String toString() {
    return r'bookProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Book> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Book> create(Ref ref) {
    final argument = this.argument as String;
    return book(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookHash() => r'78bbeea438f91c8e05bc902c0e178a0d9c1b1334';

/// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.

final class BookFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Book>, String> {
  BookFamily._()
    : super(
        retry: null,
        name: r'bookProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 단일 책 스트림(BK-004 책 상세용). family 형태로 bookId 를 받는다.

  BookProvider call(String bookId) =>
      BookProvider._(argument: bookId, from: this);

  @override
  String toString() => r'bookProvider';
}

/// 카카오 책 검색 상태를 관리하는 Notifier.
///
/// 검색 결과 리스트를 AsyncValue 로 들고 있으며, 검색어 입력에 따라
/// [search] 로 갱신하고 입력이 비면 [clear] 로 초기화한다.

@ProviderFor(BookSearchNotifier)
final bookSearchProvider = BookSearchNotifierProvider._();

/// 카카오 책 검색 상태를 관리하는 Notifier.
///
/// 검색 결과 리스트를 AsyncValue 로 들고 있으며, 검색어 입력에 따라
/// [search] 로 갱신하고 입력이 비면 [clear] 로 초기화한다.
final class BookSearchNotifierProvider
    extends $AsyncNotifierProvider<BookSearchNotifier, List<KakaoBook>> {
  /// 카카오 책 검색 상태를 관리하는 Notifier.
  ///
  /// 검색 결과 리스트를 AsyncValue 로 들고 있으며, 검색어 입력에 따라
  /// [search] 로 갱신하고 입력이 비면 [clear] 로 초기화한다.
  BookSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookSearchNotifierHash();

  @$internal
  @override
  BookSearchNotifier create() => BookSearchNotifier();
}

String _$bookSearchNotifierHash() =>
    r'a3d688374e7e1a672972f34d207125165c1c7ca7';

/// 카카오 책 검색 상태를 관리하는 Notifier.
///
/// 검색 결과 리스트를 AsyncValue 로 들고 있으며, 검색어 입력에 따라
/// [search] 로 갱신하고 입력이 비면 [clear] 로 초기화한다.

abstract class _$BookSearchNotifier extends $AsyncNotifier<List<KakaoBook>> {
  FutureOr<List<KakaoBook>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<KakaoBook>>, List<KakaoBook>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<KakaoBook>>, List<KakaoBook>>,
              AsyncValue<List<KakaoBook>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 책 관련 사용자 액션(등록·선택)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 책 데이터는
/// [booksProvider]/[bookProvider] 스트림에서 흐른다.

@ProviderFor(BookActionNotifier)
final bookActionProvider = BookActionNotifierProvider._();

/// 책 관련 사용자 액션(등록·선택)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 책 데이터는
/// [booksProvider]/[bookProvider] 스트림에서 흐른다.
final class BookActionNotifierProvider
    extends $AsyncNotifierProvider<BookActionNotifier, void> {
  /// 책 관련 사용자 액션(등록·선택)을 수행하는 Notifier.
  ///
  /// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 책 데이터는
  /// [booksProvider]/[bookProvider] 스트림에서 흐른다.
  BookActionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookActionNotifierHash();

  @$internal
  @override
  BookActionNotifier create() => BookActionNotifier();
}

String _$bookActionNotifierHash() =>
    r'dc1f00cd400927e6cd3673f5b315630dd940dcdc';

/// 책 관련 사용자 액션(등록·선택)을 수행하는 Notifier.
///
/// 본 Notifier 는 "액션 진행/실패" 만 상태로 들고, 실제 책 데이터는
/// [booksProvider]/[bookProvider] 스트림에서 흐른다.

abstract class _$BookActionNotifier extends $AsyncNotifier<void> {
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
