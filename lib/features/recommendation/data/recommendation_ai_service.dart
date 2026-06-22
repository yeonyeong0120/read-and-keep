import 'dart:convert';

import '../../../core/ai/ai_config.dart';
import '../../../core/ai/gemini_client.dart';
import '../../books/data/models/book.dart';
import '../../books/data/models/kakao_book.dart';
import '../../books/data/repositories/book_repository.dart';
import '../../captures/data/models/capture.dart';
import 'keyword_icons.dart';
import 'mock_recommendation.dart';
import 'models/recommendation_analysis.dart';
import 'models/recommendation_cache.dart';

/// 2차 랭킹 LLM 에 넘기는 후보 도서 1건.
///
/// [bookId] 는 후보를 식별하는 안정 키(카카오 isbn13)이며, LLM 에 그대로
/// 노출해 이 값으로만 선택하게 한다. [title]/[author] 는 검증 단계에서 추천
/// 결과를 조립할 때 실제 데이터로 채우는 원천이다(LLM 출력은 신뢰하지 않음).
class KakaoBookCandidate {
  const KakaoBookCandidate({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
  });

  final String bookId;
  final String title;
  final String author;

  /// 카카오 후보의 표지(thumbnail). 추천 조립 시 [RecommendedBook.coverUrl] 로
  /// 그대로 옮겨 화면이 표지를 표시하게 한다.
  final String coverUrl;
  final String description;
}

/// 2차 랭킹 결과. 검증을 거쳐 후보 도서로만 조립된 추천 묶음이다.
class RecommendationRanking {
  const RecommendationRanking({
    required this.todaysPick,
    required this.alsoRecommended,
  });

  /// 오늘의 추천 1권. 유효 후보가 없으면 null.
  final RecommendedBook? todaysPick;

  /// 함께 보면 좋은 책 목록.
  final List<RecommendedBook> alsoRecommended;

  /// 후보를 찾지 못했거나 모두 무효일 때의 빈 결과.
  static const RecommendationRanking empty = RecommendationRanking(
    todaysPick: null,
    alsoRecommended: <RecommendedBook>[],
  );
}

/// 추천 LLM 서비스(1차 구절 분석 + 2차 도서 랭킹).
///
/// 1차([analyzeCaptures])는 수집 구절·책 목록을 Gemini 로 분석해
/// themes/keywords/summary 를 받고, 2차([rankBooks])는 1차 결과로 모은 카카오
/// 후보 도서 중에서만 오늘의 추천/함께 추천을 고르게 한다. LLM 출력의 도서
/// 정보는 신뢰하지 않으며, bookId 를 후보 집합과 대조해 환각을 차단하고
/// title/author 는 카카오 실제 데이터로 채운다.
///
/// 본 서비스는 예외를 전파하되 JSON 파싱 단계만 방어적으로 처리한다.
class RecommendationAiService {
  RecommendationAiService(this._geminiClient, this._bookRepository);

  final GeminiClient _geminiClient;
  final BookRepository _bookRepository;

  /// 수집할 후보 도서 상한.
  static const int _candidateMax = 20;

  /// 후보 설명을 프롬프트에 넣을 때의 최대 길이.
  static const int _candidateDescMaxLen = 80;

  /// 수집 구절을 분석해 1차 결과를 반환한다.
  ///
  /// [captures] 는 분석 대상 구절(최근 30일 우선 필터는 호출자 책임),
  /// [books] 는 책장 목록, [dismissedBookTitles] 는 사용자가 관심 없어한 책이다.
  Future<RecommendationAnalysis> analyzeCaptures({
    required List<Capture> captures,
    required List<Book> books,
    required List<String> dismissedBookTitles,
  }) async {
    // 1) 데모 폴백: LLM 호출 없이 mock 반환.
    if (AiConfig.useMockRecommendation) {
      return kMockRecommendationAnalysis;
    }

    // 2) 프롬프트 구성.
    final prompt = _buildPrompt(
      captures: captures,
      books: books,
      dismissedBookTitles: dismissedBookTitles,
    );

    // 3) LLM 호출(JSON 모드).
    final raw = await _geminiClient.generateJson(prompt);

    // 4) 방어적 파싱(실패 시 mock 폴백).
    final analysis = _parseAnalysis(raw);

    // 5) 키워드 후처리(최대 5개 + 아이콘 정제).
    return _postProcess(analysis);
  }

  /// 역할 지시 + 입력 데이터 + 출력 형식 명세로 한국어 프롬프트를 만든다.
  String _buildPrompt({
    required List<Capture> captures,
    required List<Book> books,
    required List<String> dismissedBookTitles,
  }) {
    final buffer = StringBuffer();

    // 역할 지시.
    buffer.writeln(
      '너는 사용자의 독서 취향을 분석하는 도우미야. '
      '아래 수집 문장과 책 목록을 보고 테마, 키워드 5개, 한 줄 요약을 '
      'JSON 으로만 응답해.',
    );
    buffer.writeln();

    // 입력 데이터: 수집 문장.
    buffer.writeln('## 수집 문장');
    if (captures.isEmpty) {
      buffer.writeln('(수집된 문장 없음)');
    } else {
      for (final capture in captures) {
        final lengthTag = capture.quote.trim().length >= 40 ? 'long' : 'short';
        final comment = capture.comment.trim().isEmpty
            ? ''
            : ' (코멘트: ${capture.comment.trim()})';
        buffer.writeln(
          '- [$lengthTag] ${capture.bookTitle} — ${capture.quote.trim()}$comment',
        );
      }
    }
    buffer.writeln();

    // 입력 데이터: 책 목록.
    buffer.writeln('## 책 목록');
    if (books.isEmpty) {
      buffer.writeln('(없음)');
    } else {
      for (final book in books) {
        buffer.writeln('- ${book.title} / ${book.author}');
      }
    }
    buffer.writeln();

    // 입력 데이터: 관심 없어한 책.
    if (dismissedBookTitles.isNotEmpty) {
      buffer.writeln('## 사용자가 관심 없어한 책');
      for (final title in dismissedBookTitles) {
        buffer.writeln('- $title');
      }
      buffer.writeln();
    }

    // 출력 형식 명세.
    buffer.writeln('## 출력 형식 (반드시 이 JSON 구조로만 응답)');
    buffer.writeln('{');
    buffer.writeln('  "themes": ["...", "..."],');
    buffer.writeln('  "keywords": [ {"label": "...", "icon": "..."} ],');
    buffer.writeln('  "summary": "한 문장 요약"');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('- themes 는 2~4개의 한국어 테마.');
    buffer.writeln('- keywords 는 정확히 5개. label 은 짧은 한국어 단어.');
    buffer.writeln('- icon 은 다음 중에서만 선택: ${kAllowedKeywordIcons.join(', ')}.');
    buffer.writeln('- summary 는 한국어 한 문장.');
    buffer.writeln('- JSON 외 다른 텍스트, 마크다운, 코드블록 금지.');

    return buffer.toString();
  }

  /// LLM 응답 문자열을 방어적으로 파싱한다.
  ///
  /// 1차로 그대로 시도하고, 실패하면 코드펜스/잡텍스트를 제거해 재시도한다.
  /// 그래도 실패하면 앱이 죽지 않도록 mock 으로 폴백한다.
  RecommendationAnalysis _parseAnalysis(String raw) {
    final first = _tryParse(raw);
    if (first != null) return first;

    final cleaned = _stripToJson(raw);
    final second = _tryParse(cleaned);
    if (second != null) return second;

    return kMockRecommendationAnalysis;
  }

  RecommendationAnalysis? _tryParse(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return RecommendationAnalysis.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 앞뒤 코드펜스/잡텍스트를 제거해 첫 '{' ~ 마지막 '}' 구간만 남긴다.
  String _stripToJson(String raw) {
    final withoutFence =
        raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = withoutFence.indexOf('{');
    final end = withoutFence.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return withoutFence;
    }
    return withoutFence.substring(start, end + 1);
  }

  /// 키워드를 최대 5개로 자르고, 각 아이콘을 허용 집합으로 정제한다.
  RecommendationAnalysis _postProcess(RecommendationAnalysis analysis) {
    final keywords = analysis.keywords
        .take(5)
        .map(
          (keyword) => RecommendationKeyword(
            label: keyword.label,
            icon: sanitizeKeywordIcon(keyword.icon),
          ),
        )
        .toList();

    return RecommendationAnalysis(
      themes: analysis.themes,
      keywords: keywords,
      summary: analysis.summary,
    );
  }

  // ===========================================================================
  // 2차 LLM: 도서 랭킹
  // ===========================================================================

  /// 1차 분석 결과를 검색어로 삼아 카카오 후보 도서를 모은다.
  ///
  /// 키워드 label 상위 3개를 우선 검색어로, 부족하면 테마 상위 2개로 보충한다.
  /// 각 검색 결과를 isbn13 기준으로 dedup 하고, 사용자가 이미 읽은 책(isbn13/
  /// 제목)과 관심 없어한 책(제목)은 제외한다. 최대 [_candidateMax] 권으로 컷한다.
  /// 식별자(isbn13)가 없는 책은 후보에서 뺀다(랭킹 검증에 bookId 가 필요).
  Future<List<KakaoBookCandidate>> collectCandidates({
    required RecommendationAnalysis analysis,
    required List<Book> readBooks,
    required List<String> dismissedTitles,
  }) async {
    final queries = _buildSearchQueries(analysis);
    if (queries.isEmpty) return const <KakaoBookCandidate>[];

    final readIsbns = readBooks
        .map((b) => b.isbn13)
        .where((s) => s.isNotEmpty)
        .toSet();
    final readTitles = readBooks.map((b) => b.title.trim()).toSet();
    final dismissed = dismissedTitles.map((t) => t.trim()).toSet();

    final byId = <String, KakaoBookCandidate>{};
    for (final query in queries) {
      if (byId.length >= _candidateMax) break;

      List<KakaoBook> results;
      try {
        results = await _bookRepository.searchBooks(query);
      } catch (_) {
        // 검색 한 건 실패는 건너뛰고 다음 검색어로 진행한다.
        continue;
      }

      for (final book in results) {
        if (byId.length >= _candidateMax) break;

        final id = book.isbn13;
        if (id.isEmpty) continue; // 식별자 없으면 제외.
        if (byId.containsKey(id)) continue; // isbn13 dedup.
        if (readIsbns.contains(id)) continue; // 읽은 책 제외(isbn).
        if (readTitles.contains(book.title.trim())) continue; // 읽은 책 제외(제목).
        if (dismissed.contains(book.title.trim())) continue; // 관심 없어한 책 제외.

        byId[id] = KakaoBookCandidate(
          bookId: id,
          title: book.title,
          author: book.authorText,
          coverUrl: book.thumbnail,
          description: book.contents,
        );
      }
    }

    return byId.values.toList();
  }

  /// 후보 도서 중에서만 오늘의 추천 1권 + 함께 추천 여러 권을 고른다.
  ///
  /// 후보가 비면 즉시 빈 결과(추천 불가)를 반환한다. mock 스위치가 켜져 있으면
  /// 후보 상위로 mock 랭킹을 만든다. LLM 호출 후에는 [_validateAndBuild] 로
  /// bookId 를 후보 집합과 대조해 환각을 차단한다.
  Future<RecommendationRanking> rankBooks({
    required RecommendationAnalysis analysis,
    required List<Book> readBooks,
    required List<String> dismissedTitles,
    required List<KakaoBookCandidate> candidates,
  }) async {
    // 후보가 없으면 추천을 만들 수 없다(UI 가 빈 상태 처리).
    if (candidates.isEmpty) return RecommendationRanking.empty;

    // 데모 폴백: LLM 호출 없이 후보 상위로 랭킹을 구성한다.
    if (AiConfig.useMockRecommendation) {
      return _mockRanking(candidates);
    }

    final prompt = _buildRankingPrompt(
      analysis: analysis,
      readBooks: readBooks,
      dismissedTitles: dismissedTitles,
      candidates: candidates,
    );

    final raw = await _geminiClient.generateJson(prompt);
    final parsed = _parseRanking(raw);

    // 환각 차단: 후보 bookId 로만 검증·조립.
    return _validateAndBuild(parsed, candidates);
  }

  /// 키워드 label(상위 3) → 테마(상위 2) 순으로 중복 없는 검색어를 만든다.
  List<String> _buildSearchQueries(RecommendationAnalysis analysis) {
    final queries = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final q = raw.trim();
      if (q.isEmpty) return;
      if (!seen.add(q)) return;
      queries.add(q);
    }

    for (final keyword in analysis.keywords.take(3)) {
      add(keyword.label);
    }
    for (final theme in analysis.themes.take(2)) {
      add(theme);
    }

    return queries;
  }

  /// 2차 랭킹 프롬프트. "후보 중에서만 선택" 규칙과 출력 형식을 강제한다.
  String _buildRankingPrompt({
    required RecommendationAnalysis analysis,
    required List<Book> readBooks,
    required List<String> dismissedTitles,
    required List<KakaoBookCandidate> candidates,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      '너는 사용자의 독서 취향 분석 결과와 후보 도서 목록을 보고, 가장 잘 맞는 '
      "'오늘의 추천' 1권과 '함께 보면 좋은 책' 여러 권을 후보 중에서만 골라 "
      'JSON 으로만 응답하는 도우미야.',
    );
    buffer.writeln();

    // 1차 분석 결과.
    buffer.writeln('## 취향 분석');
    buffer.writeln('- 테마: ${analysis.themes.join(', ')}');
    buffer.writeln('- 키워드: ${analysis.keywords.map((k) => k.label).join(', ')}');
    buffer.writeln('- 요약: ${analysis.summary}');
    buffer.writeln();

    // 제외 대상: 이미 읽은 책.
    buffer.writeln('## 이미 읽은 책 (추천 금지)');
    if (readBooks.isEmpty) {
      buffer.writeln('(없음)');
    } else {
      for (final book in readBooks) {
        buffer.writeln('- ${book.title} / ${book.author}');
      }
    }
    buffer.writeln();

    // 제외 대상: 관심 없어한 책.
    if (dismissedTitles.isNotEmpty) {
      buffer.writeln('## 관심 없어한 책 (추천 금지)');
      for (final title in dismissedTitles) {
        buffer.writeln('- $title');
      }
      buffer.writeln();
    }

    // 후보 목록.
    buffer.writeln('## 후보 도서 (이 안에서만 선택)');
    for (final candidate in candidates) {
      final desc = candidate.description.trim();
      final summary = desc.length > _candidateDescMaxLen
          ? '${desc.substring(0, _candidateDescMaxLen)}...'
          : desc;
      buffer.writeln(
        '- [${candidate.bookId}] ${candidate.title} / ${candidate.author} — $summary',
      );
    }
    buffer.writeln();

    // 엄격 규칙.
    buffer.writeln('## 규칙');
    buffer.writeln('- 반드시 위 후보 목록의 bookId 중에서만 선택한다.');
    buffer.writeln('- 목록에 없는 책을 새로 만들지 않는다.');
    buffer.writeln('- bookId 는 대괄호 안에 제시된 값을 그대로 사용한다.');
    buffer.writeln('- 이미 읽은 책과 관심 없어한 책은 고르지 않는다.');
    buffer.writeln();

    // 출력 형식.
    buffer.writeln('## 출력 형식 (반드시 이 JSON 구조로만 응답)');
    buffer.writeln('{');
    buffer.writeln('  "todaysPick": {');
    buffer.writeln('    "bookId": "...",');
    buffer.writeln('    "reason": "오늘의 추천으로 고른 이유(한국어 1~2문장)",');
    buffer.writeln('    "themeMatch": "어떤 테마와 맞는지",');
    buffer.writeln('    "relatedKeywords": ["..."],');
    buffer.writeln('    "linkedCaptureIds": []');
    buffer.writeln('  },');
    buffer.writeln('  "alsoRecommended": [');
    buffer.writeln(
      '    { "bookId": "...", "reason": "...", "themeMatch": "...", "relatedKeywords": ["..."] }',
    );
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('- title, author 는 응답에 넣지 않는다(우리가 후보에서 채운다).');
    buffer.writeln('- alsoRecommended 는 2~4권.');
    buffer.writeln('- JSON 외 다른 텍스트, 마크다운, 코드블록 금지.');

    return buffer.toString();
  }

  /// 랭킹 응답을 방어적으로 파싱한다(1차와 동일 전략: 그대로 → 코드펜스 제거).
  /// 끝내 실패하면 빈 결과를 반환하고, 검증 단계가 이를 그대로 폐기한다.
  RecommendationRanking _parseRanking(String raw) {
    final first = _tryParseRanking(raw);
    if (first != null) return first;

    final second = _tryParseRanking(_stripToJson(raw));
    if (second != null) return second;

    return RecommendationRanking.empty;
  }

  RecommendationRanking? _tryParseRanking(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;

      final pickRaw = decoded['todaysPick'];
      final alsoRaw = decoded['alsoRecommended'];

      final pick = pickRaw is Map
          ? RecommendedBook.fromJson(Map<String, dynamic>.from(pickRaw))
          : null;
      final also = alsoRaw is List
          ? alsoRaw
              .whereType<Map<Object?, Object?>>()
              .map(
                (e) => RecommendedBook.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : <RecommendedBook>[];

      return RecommendationRanking(todaysPick: pick, alsoRecommended: also);
    } catch (_) {
      return null;
    }
  }

  /// 환각 차단의 핵심. LLM 이 고른 bookId 를 후보 집합과 대조해 검증한다.
  ///
  /// - 후보에 없는 bookId 는 폐기(해당 추천 항목 제거).
  /// - 유효한 bookId 만 남기고 title/author 는 후보(카카오 실제 데이터)로 채운다.
  /// - 오늘의 추천이 무효면 함께 추천의 첫 유효 항목을 승격하고, 둘 다 없으면
  ///   todaysPick 을 null 로 둔다(UI 가 빈 상태 처리).
  /// - 함께 추천은 bookId 중복과 오늘의 추천과의 중복을 제거한다.
  RecommendationRanking _validateAndBuild(
    RecommendationRanking parsed,
    List<KakaoBookCandidate> candidates,
  ) {
    final byId = {for (final c in candidates) c.bookId: c};

    RecommendedBook? build(RecommendedBook? raw) {
      if (raw == null) return null;
      final candidate = byId[raw.bookId];
      if (candidate == null) return null; // 후보에 없는 bookId → 환각, 폐기.

      return RecommendedBook(
        bookId: candidate.bookId,
        title: candidate.title, // LLM 출력이 아닌 카카오 실제 데이터로 채움.
        author: candidate.author,
        coverUrl: candidate.coverUrl, // 표지도 카카오 후보에서 채움.
        reason: raw.reason,
        linkedCaptureIds: raw.linkedCaptureIds,
        themeMatch: raw.themeMatch,
        relatedKeywords: raw.relatedKeywords,
      );
    }

    // 함께 추천: 유효한 항목만, bookId 중복 제거.
    final seen = <String>{};
    final validAlso = <RecommendedBook>[];
    for (final raw in parsed.alsoRecommended) {
      final built = build(raw);
      if (built == null) continue;
      if (!seen.add(built.bookId)) continue;
      validAlso.add(built);
    }

    // 오늘의 추천: 유효하면 사용, 무효면 함께 추천 첫 항목 승격.
    var pick = build(parsed.todaysPick);
    if (pick != null) {
      final pickId = pick.bookId;
      validAlso.removeWhere((b) => b.bookId == pickId);
    } else if (validAlso.isNotEmpty) {
      pick = validAlso.removeAt(0);
    }

    return RecommendationRanking(todaysPick: pick, alsoRecommended: validAlso);
  }

  /// 데모 폴백 랭킹. 후보 상위 1권을 오늘의 추천으로, 나머지를 함께 추천으로.
  RecommendationRanking _mockRanking(List<KakaoBookCandidate> candidates) {
    final picks = candidates.take(4).toList();
    if (picks.isEmpty) return RecommendationRanking.empty;

    RecommendedBook toRec(KakaoBookCandidate c, String reason) {
      return RecommendedBook(
        bookId: c.bookId,
        title: c.title,
        author: c.author,
        coverUrl: c.coverUrl,
        reason: reason,
        linkedCaptureIds: const <String>[],
        themeMatch: '취향과 잘 맞는 책',
        relatedKeywords: const <String>[],
      );
    }

    return RecommendationRanking(
      todaysPick: toRec(picks.first, '취향 분석과 가장 잘 맞는 오늘의 추천이에요.'),
      alsoRecommended:
          picks.skip(1).map((c) => toRec(c, '함께 보면 좋은 책이에요.')).toList(),
    );
  }
}
