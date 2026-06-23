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

/// 알라딘 베스트셀러 목록.
///
/// [maxResults] 로 가져올 개수를 받는다(기본 10). 베스트셀러는 정렬칩 변경과
/// 무관하므로 keepAlive 로 결과를 유지한다. 정렬칩 변경 시 피드 StreamBuilder
/// 가 재구독되며 섹션이 잠시 언마운트돼도 autoDispose 가 아니어서 재호출되지
/// 않는다. 갱신은 (1)최초 진입, (2)당겨서 새로고침(invalidate) 시에만 일어난다.
@Riverpod(keepAlive: true)
Future<List<BestsellerBook>> bestsellers(Ref ref, {int maxResults = 10}) {
  return ref
      .watch(bestsellerRepositoryProvider)
      .fetchBestsellers(maxResults: maxResults);
}
