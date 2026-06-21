import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/domain/book_providers.dart';
import '../../captures/domain/capture_providers.dart';
import '../domain/recommendation_providers.dart';

/// 추천 화면 (RC) 임시 자리표시. 본 콘텐츠는 추후 구현한다.
///
/// 현재는 Gemini 호출이 실제로 동작하는지 폰에서 확인하기 위한 임시 테스트
/// 버튼만 둔다.
class RecommendScreen extends ConsumerStatefulWidget {
  const RecommendScreen({super.key});

  @override
  ConsumerState<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends ConsumerState<RecommendScreen> {
  // TODO: RC-C 에서 제거 — 아래 테스트 상태/버튼/표시 영역은 임시 연결 확인용.
  bool _isTesting = false;
  String? _resultText;
  String? _errorText;

  bool _isAnalyzing = false;
  String? _analysisText;
  String? _analysisError;

  Future<void> _runGeminiTest() async {
    setState(() {
      _isTesting = true;
      _resultText = null;
      _errorText = null;
    });

    try {
      final text = await ref.read(geminiClientProvider).generateText(
            '한 문장으로 책을 추천하는 인사를 해줘',
          );
      debugPrint('Gemini 응답: $text');
      if (!mounted) return;
      setState(() => _resultText = text);
    } catch (e) {
      debugPrint('Gemini 오류: $e');
      if (!mounted) return;
      setState(() => _errorText = '$e');
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _runAnalysisTest() async {
    setState(() {
      _isAnalyzing = true;
      _analysisText = null;
      _analysisError = null;
    });

    try {
      // 책장과 각 책의 구절을 모아 1차 분석에 넘긴다(테스트용 간단 수집).
      final books = await ref.read(booksProvider().future);
      final captureRepository = ref.read(captureRepositoryProvider);
      final captureLists = await Future.wait(
        books.map((book) => captureRepository.watchCapturesByBook(book.bookId).first),
      );
      final captures = captureLists.expand((list) => list).toList();

      final analysis = await ref.read(recommendationAiServiceProvider).analyzeCaptures(
            captures: captures,
            books: books,
            dismissedBookTitles: const [],
          );

      final text = '테마: ${analysis.themes.join(', ')}\n'
          '키워드: ${analysis.keywords.map((k) => '${k.label}(${k.icon})').join(', ')}\n'
          '요약: ${analysis.summary}';
      debugPrint('1차 분석 결과: $text');
      if (!mounted) return;
      setState(() => _analysisText = text);
    } catch (e) {
      debugPrint('1차 분석 오류: $e');
      if (!mounted) return;
      setState(() => _analysisError = '$e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천')),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding.add(
          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('추천 화면은 추후 구현', style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xl),

              // TODO: RC-C 에서 제거 — Gemini 연결 테스트 임시 UI.
              FilledButton.icon(
                onPressed: _isTesting ? null : _runGeminiTest,
                icon: _isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(_isTesting ? '응답 기다리는 중...' : 'Gemini 연결 테스트'),
              ),
              if (_resultText != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResultBox(
                  label: 'Gemini 응답',
                  message: _resultText!,
                  color: AppColors.surfaceVariant,
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResultBox(
                  label: '오류',
                  message: _errorText!,
                  color: AppColors.surfaceVariant,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // TODO: RC-C 에서 제거 — 1차 분석(구절 분석) 테스트 임시 UI.
              FilledButton.icon(
                onPressed: _isAnalyzing ? null : _runAnalysisTest,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.insights_rounded),
                label: Text(_isAnalyzing ? '분석 중...' : '1차 분석 테스트'),
              ),
              if (_analysisText != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResultBox(
                  label: '1차 분석 결과',
                  message: _analysisText!,
                  color: AppColors.surfaceVariant,
                ),
              ],
              if (_analysisError != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ResultBox(
                  label: '분석 오류',
                  message: _analysisError!,
                  color: AppColors.surfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 테스트 결과/오류 표시 박스. RC-C 에서 제거 대상.
class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.label,
    required this.message,
    required this.color,
  });

  final String label;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
