import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/bestseller_book.dart';
import '../data/repositories/bestseller_repository.dart';

part 'bestseller_providers.g.dart';

/// [BestsellerRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
BestsellerRepository bestsellerRepository(Ref ref) {
  return BestsellerRepository();
}

/// 알라딘 베스트셀러 목록(일회성 조회).
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 자주 바뀌지
/// 않지만 우선 단순 FutureProvider 로 두고, 캐싱 정책은 TR-B 에서 조정한다.
@riverpod
Future<List<BestsellerBook>> bestsellers(Ref ref, {int maxResults = 10}) {
  return ref
      .watch(bestsellerRepositoryProvider)
      .fetchBestsellers(maxResults: maxResults);
}
