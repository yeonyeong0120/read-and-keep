import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/ai/ai_config.dart';
import '../../../core/ai/gemini_client.dart';
import '../../books/domain/book_providers.dart';
import '../../captures/data/models/capture.dart';
import '../../captures/domain/capture_providers.dart';
import '../data/models/recommendation_cache.dart';
import '../data/recommendation_ai_service.dart';
import '../data/repositories/recommendation_repository.dart';
import 'drift_status.dart';

part 'recommendation_providers.g.dart';

/// [RecommendationRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
RecommendationRepository recommendationRepository(Ref ref) {
  return RecommendationRepository();
}

/// 추천 캐시 스트림. 캐시가 없으면 null 을 방출한다.
@riverpod
Stream<RecommendationCache?> recommendationCache(Ref ref) {
  return ref.watch(recommendationRepositoryProvider).watchCache();
}

/// 현재 추천 신선도([DriftStatus]).
///
/// 책 수(booksProvider)·누적 구절 수(countTotalCaptures)·추천 캐시
/// (recommendationCacheProvider)를 조합해 [computeDriftStatus] 로 판정한다.
///
/// books/cache 는 Stream 이므로 `.future` 로 await 하면 로딩/에러가 본 Provider
/// 로 자연스럽게 전파된다(수동 플래그 불필요). 누적 구절 수는 1회성 집계라
/// 직접 호출하며, 책이 변동되면 위 watch 로 본 Provider 가 재평가되어 갱신된다.
@riverpod
Future<DriftStatus> driftStatus(Ref ref) async {
  final books = await ref.watch(booksProvider().future);
  final cache = await ref.watch(recommendationCacheProvider.future);

  final captureCount =
      await ref.watch(recommendationRepositoryProvider).countTotalCaptures();

  return computeDriftStatus(
    bookCount: books.length,
    captureCount: captureCount,
    cache: cache,
  );
}

/// Gemini 호출 클라이언트. keepAlive 로 앱 수명 동안 단일 인스턴스를 유지한다.
@Riverpod(keepAlive: true)
GeminiClient geminiClient(Ref ref) {
  return GeminiClient();
}

/// 추천 LLM 서비스(1차 구절 분석 + 2차 도서 랭킹). keepAlive 로 단일 유지.
///
/// 2차 랭킹의 후보 수집에 카카오 검색이 필요해 [bookRepositoryProvider] 를
/// 함께 주입한다.
@Riverpod(keepAlive: true)
RecommendationAiService recommendationAiService(Ref ref) {
  return RecommendationAiService(
    ref.watch(geminiClientProvider),
    ref.watch(bookRepositoryProvider),
  );
}

/// 전체 추천 생성 Notifier(1차 분석 → 후보 수집 → 2차 랭킹 → 캐시 저장).
///
/// build 는 즉시 완료(idle)하며, 진입만으로는 생성이 일어나지 않는다. UI 의
/// 명시적 액션(첫 진입/갱신 버튼)에서 [generate] 를 호출해야 파이프라인이 돈다.
/// 에러는 state 로 전파하고(UI 가 AsyncValue.when 처리), state 할당만
/// ref.mounted 로 가드한다.
@riverpod
class RecommendationGenerator extends _$RecommendationGenerator {
  /// 최근 구절이 이 수보다 적으면 전체 구절로 폴백한다.
  static const int _minRecentCaptures = 5;

  /// 1차 분석에 넘기는 구절 수 상한(프롬프트 과대 방지).
  static const int _maxCaptures = 80;

  @override
  Future<void> build() async {
    // 생성 트리거 전에는 idle. 진입만으로는 호출되지 않는다.
  }

  /// 1→2차 전체 추천 파이프라인을 실행하고 캐시에 저장한다.
  Future<void> generate() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(recommendationRepositoryProvider);
      final aiService = ref.read(recommendationAiServiceProvider);
      final captureRepo = ref.read(captureRepositoryProvider);

      // 1) 사용자 데이터 수집: 책 + 구절 + dismissed.
      final books = await ref.read(booksProvider().future);

      final captureLists = await Future.wait(
        books.map((b) => captureRepo.watchCapturesByBook(b.bookId).first),
      );
      final allCaptures = captureLists.expand((list) => list).toList();
      final captures = _selectCaptures(allCaptures);

      final dismissedIds = await repo.getDismissedBookIds();
      final dismissedTitles = books
          .where((b) => dismissedIds.contains(b.bookId))
          .map((b) => b.title)
          .toList();

      // 2) 1차 분석.
      final analysis = await aiService.analyzeCaptures(
        captures: captures,
        books: books,
        dismissedBookTitles: dismissedTitles,
      );

      // 3) 후보 도서 수집(카카오 검색).
      final candidates = await aiService.collectCandidates(
        analysis: analysis,
        readBooks: books,
        dismissedTitles: dismissedTitles,
      );

      // 4) 2차 랭킹(+환각 차단). 후보가 0개면 빈 랭킹이 돌아온다.
      final ranking = await aiService.rankBooks(
        analysis: analysis,
        readBooks: books,
        dismissedTitles: dismissedTitles,
        candidates: candidates,
      );

      // 5) 캐시 조립: 1차 결과 + 2차 검증본 + 스냅샷 메타.
      final captureCount = await repo.countTotalCaptures();
      final cache = RecommendationCache(
        themes: analysis.themes,
        keywords: analysis.keywords,
        summary: analysis.summary,
        todaysPick: ranking.todaysPick,
        alsoRecommended: ranking.alsoRecommended,
        generatedAt: DateTime.now(),
        snapshotCaptureCount: captureCount,
        snapshotBookCount: books.length,
      );

      // 6) 저장.
      await repo.saveCache(cache);
    });

    if (ref.mounted) state = result;
  }

  /// 최근 [AiConfig.recommendationAnalysisDays] 일 구절을 우선 사용하되, 그
  /// 수가 너무 적으면 전체 구절로 폴백한다. 많으면 최신순 상한으로 컷한다.
  List<Capture> _selectCaptures(List<Capture> all) {
    final cutoff = DateTime.now().subtract(
      const Duration(days: AiConfig.recommendationAnalysisDays),
    );
    final recent = all.where((c) => c.createdAt.isAfter(cutoff)).toList();
    final selected = recent.length >= _minRecentCaptures ? recent : all;

    if (selected.length <= _maxCaptures) return selected;

    final sorted = [...selected]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(_maxCaptures).toList();
  }
}
