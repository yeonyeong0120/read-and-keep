import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/env/env_config.dart';
import '../datasources/kakao_book_cache.dart';
import '../models/book.dart';
import '../models/kakao_book.dart';

/// 책장 정렬 기준.
enum BookSort {
  /// 최근 기록순(마지막 구절 저장 또는 마지막 선택 기준).
  recentRecord,

  /// 누적 구절 저장 수 많은 순.
  captureCount,

  /// 제목 가나다순.
  title,
}

/// 책 CRUD(Firestore) 와 카카오 책 검색을 담당하는 Repository.
///
/// 본 Repository 는 예외를 그대로 던진다. 로딩/에러 상태 관리는 호출하는
/// 쪽(Notifier)이 AsyncValue.guard 등으로 처리한다.
class BookRepository {
  BookRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Dio? dio,
    KakaoBookCache? cache,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _dio = dio ?? Dio(),
        _cache = cache ?? KakaoBookCache();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Dio _dio;
  final KakaoBookCache _cache;

  static const String _kakaoSearchUrl = 'https://dapi.kakao.com/v3/search/book';

  /// `users/{uid}/books` 컬렉션. 미로그인 시 [StateError].
  CollectionReference<Map<String, dynamic>> get _booksRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    return _firestore.collection('users').doc(user.uid).collection('books');
  }

  /// 책장 목록 스트림.
  ///
  /// recentRecord 는 모든 문서에 존재하는 lastSelectedAt 로 1차 정렬한 뒤,
  /// "최근 기록 시각"(updatedAt ?? lastCapturedAt ?? lastSelectedAt = lastRecordAt)
  /// 기준으로 클라이언트에서 재정렬한다. 구절을 저장/수정/삭제하면 updatedAt 이
  /// 갱신되어 그 책이 맨 위로 온다.
  Stream<List<Book>> watchBooks({BookSort sort = BookSort.recentRecord}) {
    final Query<Map<String, dynamic>> query = switch (sort) {
      BookSort.captureCount =>
        _booksRef.orderBy('savedQuoteCount', descending: true),
      BookSort.title => _booksRef.orderBy('title'),
      BookSort.recentRecord =>
        _booksRef.orderBy('lastSelectedAt', descending: true),
    };

    return query.snapshots().map((snapshot) {
      final books = snapshot.docs.map(Book.fromFirestore).toList();
      if (sort == BookSort.recentRecord) {
        books.sort((a, b) => b.lastRecordAt.compareTo(a.lastRecordAt));
      }
      return books;
    });
  }

  /// 단일 책 조회. 문서가 없으면 [StateError].
  Future<Book> getBook(String bookId) async {
    final doc = await _booksRef.doc(bookId).get();
    if (!doc.exists) {
      throw StateError('Book $bookId not found');
    }
    return Book.fromFirestore(doc);
  }

  /// 단일 책 스트림(BK-004 책 상세용). 문서가 사라지면 [StateError] 를 방출한다.
  Stream<Book> watchBook(String bookId) {
    return _booksRef.doc(bookId).snapshots().map((doc) {
      if (!doc.exists) {
        throw StateError('Book $bookId not found');
      }
      return Book.fromFirestore(doc);
    });
  }

  /// 카카오 검색 결과를 책장에 등록한다.
  ///
  /// isbn13 으로 동일 책이 이미 있으면 중복 등록하지 않고, 그 책의
  /// lastSelectedAt 만 갱신해 반환한다(명세상 중복 방지).
  Future<Book> addBookFromKakao(KakaoBook kakaoBook) async {
    final isbn13 = kakaoBook.isbn13;

    if (isbn13.isNotEmpty) {
      final existing =
          await _booksRef.where('isbn13', isEqualTo: isbn13).limit(1).get();
      if (existing.docs.isNotEmpty) {
        final ref = existing.docs.first.reference;
        await ref.update({'lastSelectedAt': FieldValue.serverTimestamp()});
        return Book.fromFirestore(await ref.get());
      }
    }

    // 신규 등록: 문서 ID 를 먼저 확보해 반환 객체의 bookId 를 보장한다.
    // (서버 타임스탬프가 아직 미반영된 즉시 재조회에 의존하지 않는다.)
    final docRef = _booksRef.doc();
    final newBook = kakaoBook.toBook();
    await docRef.set(newBook.toFirestoreOnCreate());
    return newBook.copyWith(bookId: docRef.id);
  }

  /// 마지막 선택 시각을 서버 타임스탬프로 갱신한다.
  Future<void> touchLastSelected(String bookId) async {
    await _booksRef
        .doc(bookId)
        .update({'lastSelectedAt': FieldValue.serverTimestamp()});
  }

  /// 카카오 책 검색.
  ///
  /// 개선 사항:
  /// 1) 기본 검색으로 제목/출판사/키워드 검색을 처리한다.
  /// 2) target=person 검색을 추가로 호출해 작가명 검색을 보강한다.
  /// 3) 두 결과를 합치고 ISBN/제목/저자 기준으로 중복 제거한다.
  Future<List<KakaoBook>> searchBooks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    // 기존 캐시와 충돌하지 않도록 v2 키를 사용한다.
    final cacheKey = 'book_search_v2::$trimmed';

    final cached = _cache.read(cacheKey);
    if (cached != null) {
      return cached.map(KakaoBook.fromJson).toList();
    }

    final apiKey = EnvConfig.kakaoRestApiKey;
    if (apiKey.isEmpty) {
      throw StateError('카카오 API 키가 설정되지 않았습니다');
    }

    // 1차: 기본 검색
    final generalDocuments = await _fetchKakaoBookDocuments(
      query: trimmed,
      apiKey: apiKey,
    );

    // 2차: 저자명 검색
    final authorDocuments = await _fetchKakaoBookDocuments(
      query: trimmed,
      apiKey: apiKey,
      target: 'person',
    );

    final mergedDocuments = _mergeAndDedupeDocuments([
      ...authorDocuments,
      ...generalDocuments,
    ]);

    await _cache.write(cacheKey, mergedDocuments);

    return mergedDocuments.map(KakaoBook.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchKakaoBookDocuments({
    required String query,
    required String apiKey,
    String? target,
  }) async {
    final queryParameters = <String, dynamic>{
      'query': query,
      'sort': 'accuracy',
      'size': 20,
    };

    if (target != null && target.trim().isNotEmpty) {
      queryParameters['target'] = target;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      _kakaoSearchUrl,
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'Authorization': 'KakaoAK $apiKey',
        },
      ),
    );

    return (response.data?['documents'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<Map<String, dynamic>> _mergeAndDedupeDocuments(
    List<Map<String, dynamic>> documents,
  ) {
    final result = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    for (final document in documents) {
      final key = _documentUniqueKey(document);

      if (seenKeys.contains(key)) {
        continue;
      }

      seenKeys.add(key);
      result.add(document);
    }

    return result;
  }

  String _documentUniqueKey(Map<String, dynamic> document) {
    final rawIsbn = (document['isbn'] as String? ?? '').trim();
    final isbnParts = rawIsbn
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // 카카오 isbn 값은 "ISBN10 ISBN13" 형태로 오는 경우가 있어 ISBN13을 우선 사용한다.
    final isbn13 = isbnParts.where((e) => e.length == 13).firstOrNull;
    if (isbn13 != null && isbn13.isNotEmpty) {
      return 'isbn13::$isbn13';
    }

    if (rawIsbn.isNotEmpty) {
      return 'isbn::$rawIsbn';
    }

    final title = (document['title'] as String? ?? '').trim().toLowerCase();
    final authors = (document['authors'] as List<dynamic>? ?? const [])
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .join(',');

    final publisher =
        (document['publisher'] as String? ?? '').trim().toLowerCase();

    return 'fallback::$title::$authors::$publisher';
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}