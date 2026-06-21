import 'dart:convert';

import '../../../core/ai/ai_config.dart';
import '../../../core/ai/gemini_client.dart';
import '../../books/data/models/book.dart';
import '../../captures/data/models/capture.dart';
import 'keyword_icons.dart';
import 'mock_recommendation.dart';
import 'models/recommendation_analysis.dart';
import 'models/recommendation_cache.dart';

/// 추천 1차 LLM(구절 분석) 서비스.
///
/// 수집 구절·책 목록을 Gemini 로 분석해 themes/keywords/summary 를 받는다.
/// 2차 랭킹은 RC-B-2b 에서 별도로 구현한다. 본 서비스는 예외를 전파하되
/// JSON 파싱 단계만 방어적으로 처리한다(LLM 출력은 불완전할 수 있음).
class RecommendationAiService {
  RecommendationAiService(this._geminiClient);

  final GeminiClient _geminiClient;

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
}
