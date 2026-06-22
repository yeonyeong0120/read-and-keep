import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/env/env_config.dart';
import '../../../captures/data/models/capture.dart';

class GeminiRecommendationService {
  GeminiRecommendationService({
    String modelName = 'gemini-2.5-flash',
  }) : _modelName = modelName;

  final String _modelName;

  Future<List<GeminiRecommendationCandidate>> recommendBooks({
    required List<Capture> captures,
  }) async {
    final apiKey = EnvConfig.geminiApiKey.trim();

    if (apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY가 비어 있습니다. .env 파일과 EnvConfig.geminiApiKey를 확인하세요.',
      );
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
    );

    final prompt = _buildPrompt(captures);

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini 응답이 비어 있습니다.');
    }

    final candidates = _parseCandidates(text);

    if (candidates.isEmpty) {
      throw StateError('Gemini 추천 결과가 비어 있습니다.');
    }

    return candidates;
  }

  String _buildPrompt(List<Capture> captures) {
    final recentCaptures = captures.take(10).toList();

    final buffer = StringBuffer();

    buffer.writeln('너는 한국 독자를 위한 책 추천 전문가야.');
    buffer.writeln('사용자가 저장한 책 구절과 감상문을 보고 사용자의 독서 취향에 맞는 책 3권을 추천해.');
    buffer.writeln('');
    buffer.writeln('중요 조건:');
    buffer.writeln('- 반드시 실제 존재할 가능성이 높은 한국어 도서 또는 국내에서 검색 가능한 도서를 추천해.');
    buffer.writeln('- 사용자가 이미 저장한 책과 너무 비슷한 책만 추천하지 말고, 취향이 이어지는 책을 추천해.');
    buffer.writeln('- 너무 유명한 책만 반복하지 말고, 구절의 감정과 분위기를 분석해서 추천해.');
    buffer.writeln('- 응답은 JSON 배열만 출력해.');
    buffer.writeln('- 마크다운, 코드블록, 설명 문장 없이 JSON만 출력해.');
    buffer.writeln('- 반드시 3개를 추천해.');
    buffer.writeln('- 각 항목은 title, author, keyword, reason 필드를 가져야 해.');
    buffer.writeln('- keyword는 2~6글자 정도의 짧은 한국어 키워드로 작성해.');
    buffer.writeln('- reason은 한국어로 1~2문장, 앱 화면에 들어갈 정도로 짧게 작성해.');
    buffer.writeln('');
    buffer.writeln('응답 형식:');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "title": "책 제목",');
    buffer.writeln('    "author": "작가명",');
    buffer.writeln('    "keyword": "추천 키워드",');
    buffer.writeln('    "reason": "추천 이유"');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln('');
    buffer.writeln('사용자가 저장한 구절 목록:');

    for (var i = 0; i < recentCaptures.length; i++) {
      final capture = recentCaptures[i];

      buffer.writeln('');
      buffer.writeln('${i + 1}. 책 제목: ${capture.bookTitle}');
      buffer.writeln('구절: ${capture.quote}');

      if (capture.comment.trim().isNotEmpty) {
        buffer.writeln('감상: ${capture.comment}');
      }
    }

    return buffer.toString();
  }

  List<GeminiRecommendationCandidate> _parseCandidates(String rawText) {
    final cleaned = _cleanJsonText(rawText);
    final decoded = jsonDecode(cleaned);

    if (decoded is! List) {
      throw FormatException('Gemini 응답이 JSON 배열이 아닙니다: $rawText');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((map) {
          return GeminiRecommendationCandidate(
            title: map['title'] as String? ?? '',
            author: map['author'] as String? ?? '',
            keyword: map['keyword'] as String? ?? '',
            reason: map['reason'] as String? ?? '',
          );
        })
        .where((candidate) => candidate.title.trim().isNotEmpty)
        .take(3)
        .toList();
  }

  String _cleanJsonText(String rawText) {
    var text = rawText.trim();

    if (text.startsWith('```json')) {
      text = text.substring(7).trim();
    }

    if (text.startsWith('```')) {
      text = text.substring(3).trim();
    }

    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3).trim();
    }

    final startIndex = text.indexOf('[');
    final endIndex = text.lastIndexOf(']');

    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      throw FormatException('Gemini 응답에서 JSON 배열을 찾지 못했습니다: $rawText');
    }

    return text.substring(startIndex, endIndex + 1);
  }
}

class GeminiRecommendationCandidate {
  const GeminiRecommendationCandidate({
    required this.title,
    required this.author,
    required this.keyword,
    required this.reason,
  });

  final String title;
  final String author;
  final String keyword;
  final String reason;
}