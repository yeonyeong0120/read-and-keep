import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../books/data/models/kakao_book.dart';
import '../../books/data/repositories/book_repository.dart';
import '../../captures/data/models/capture.dart';
import '../data/services/gemini_recommendation_service.dart';

enum _RecommendState {
  ready,
  loading,
  insufficient,
  success,
  error,
}

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final BookRepository _bookRepository = BookRepository();
  final GeminiRecommendationService _geminiService =
      GeminiRecommendationService();

  _RecommendState _state = _RecommendState.ready;

  String? _errorMessage;
  int _captureCount = 0;
  bool _isCachedResult = false;
  bool _usedGeminiResult = false;

  List<Capture> _captures = const [];
  List<_RecommendedBook> _recommendations = const [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedRecommendations();
    });
  }

  Future<void> _loadCachedRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser ??
          await FirebaseAuth.instance.authStateChanges().first;

      if (user == null) {
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recommendations')
          .doc('latest')
          .get();

      if (!doc.exists) {
        return;
      }

      final data = doc.data();
      if (data == null) {
        return;
      }

      final rawBooks = data['books'] as List<dynamic>? ?? const [];
      final books = rawBooks
          .whereType<Map<String, dynamic>>()
          .map((bookMap) {
            return _RecommendedBook.fromFirestoreMap(bookMap);
          })
          .where((book) => book.title.trim().isNotEmpty)
          .toList();

      if (books.isEmpty) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _recommendations = books;
        _captureCount = data['captureCount'] as int? ?? 0;
        _usedGeminiResult = data['usedGeminiResult'] as bool? ?? false;
        _isCachedResult = true;
        _state = _RecommendState.success;
      });
    } catch (e) {
      debugPrint('추천 결과 캐시 로드 실패: $e');
    }
  }

  Future<void> _generateRecommendations() async {
    if (_state == _RecommendState.loading) return;

    setState(() {
      _state = _RecommendState.loading;
      _errorMessage = null;
      _recommendations = const [];
      _isCachedResult = false;
      _usedGeminiResult = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _state = _RecommendState.error;
          _errorMessage = '로그인이 필요합니다.';
        });
        return;
      }

      final captures = await _fetchMyCaptures(user.uid);

      _captureCount = captures.length;
      _captures = captures;

      if (captures.length < 3) {
        if (!mounted) return;

        setState(() {
          _state = _RecommendState.insufficient;
        });
        return;
      }

      final recommendationBuildResult =
          await _buildRecommendationsFromCaptures(captures);

      final enrichedRecommendations = await _enrichRecommendationsWithKakao(
        recommendationBuildResult.books,
      );

      await _saveRecommendationCache(
        uid: user.uid,
        captures: captures,
        recommendations: enrichedRecommendations,
        usedGeminiResult: recommendationBuildResult.usedGeminiResult,
      );

      if (!mounted) return;

      setState(() {
        _recommendations = enrichedRecommendations;
        _usedGeminiResult = recommendationBuildResult.usedGeminiResult;
        _isCachedResult = false;
        _state = _RecommendState.success;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _state = _RecommendState.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<List<Capture>> _fetchMyCaptures(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final booksSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('books')
        .limit(50)
        .get();

    final captures = <Capture>[];

    for (final bookDoc in booksSnapshot.docs) {
      final capturesSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('books')
          .doc(bookDoc.id)
          .collection('captures')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      for (final captureDoc in capturesSnapshot.docs) {
        captures.add(Capture.fromFirestore(captureDoc));
      }
    }

    captures.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (captures.length <= 50) {
      return captures;
    }

    return captures.take(50).toList();
  }

  Future<void> _saveRecommendationCache({
    required String uid,
    required List<Capture> captures,
    required List<_RecommendedBook> recommendations,
    required bool usedGeminiResult,
  }) async {
    try {
      final previewCaptures = captures.take(3).map((capture) {
        return {
          'captureId': capture.id,
          'bookId': capture.bookId,
          'bookTitle': capture.bookTitle,
          'quote': capture.quote,
          'comment': capture.comment,
          'createdAt': Timestamp.fromDate(capture.createdAt),
        };
      }).toList();

      final books = recommendations.map((book) {
        return book.toFirestoreMap();
      }).toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('recommendations')
          .doc('latest')
          .set(
        {
          'captureCount': captures.length,
          'previewCaptures': previewCaptures,
          'books': books,
          'usedGeminiResult': usedGeminiResult,
          'generatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('추천 결과 캐시 저장 실패: $e');
    }
  }

  Future<_RecommendationBuildResult> _buildRecommendationsFromCaptures(
    List<Capture> captures,
  ) async {
    try {
      final candidates = await _geminiService.recommendBooks(
        captures: captures,
      );

      if (candidates.isEmpty) {
        return _RecommendationBuildResult(
          books: _buildMockRecommendationsFromCaptures(captures),
          usedGeminiResult: false,
        );
      }

      final geminiBooks = candidates.map((candidate) {
        return _RecommendedBook(
          title: candidate.title,
          author: candidate.author,
          publisher: '',
          thumbnail: '',
          keyword: candidate.keyword.trim().isEmpty
              ? '개인화 추천'
              : candidate.keyword,
          reason: candidate.reason.trim().isEmpty
              ? '저장한 구절의 분위기와 독서 취향을 바탕으로 추천한 책입니다.'
              : candidate.reason,
        );
      }).toList();

      final completedBooks = _completeRecommendationsIfNeeded(
        geminiBooks,
        captures,
      );

      return _RecommendationBuildResult(
        books: completedBooks,
        usedGeminiResult: true,
      );
    } catch (e) {
      debugPrint('Gemini 추천 생성 실패: $e');

      return _RecommendationBuildResult(
        books: _buildMockRecommendationsFromCaptures(captures),
        usedGeminiResult: false,
      );
    }
  }

  List<_RecommendedBook> _completeRecommendationsIfNeeded(
    List<_RecommendedBook> geminiBooks,
    List<Capture> captures,
  ) {
    if (geminiBooks.length >= 3) {
      return geminiBooks.take(3).toList();
    }

    final fallbackBooks = _buildMockRecommendationsFromCaptures(captures);
    final merged = <_RecommendedBook>[...geminiBooks];

    for (final fallback in fallbackBooks) {
      final alreadyExists = merged.any(
        (book) => _normalizeText(book.title) == _normalizeText(fallback.title),
      );

      if (!alreadyExists) {
        merged.add(fallback);
      }

      if (merged.length >= 3) {
        break;
      }
    }

    return merged.take(3).toList();
  }

  List<_RecommendedBook> _buildMockRecommendationsFromCaptures(
    List<Capture> captures,
  ) {
    final combinedText = captures
        .take(10)
        .map((capture) => '${capture.quote} ${capture.comment}')
        .join(' ')
        .toLowerCase();

    final keywords = <String>[];

    void addKeywordIfContains(String keyword, List<String> words) {
      final matched = words.any((word) => combinedText.contains(word));
      if (matched && !keywords.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    addKeywordIfContains('위로', ['위로', '괜찮', '버티', '힘들', '따뜻']);
    addKeywordIfContains('성장', ['성장', '변화', '배움', '꿈', '시작']);
    addKeywordIfContains('관계', ['사람', '관계', '사랑', '친구', '마음']);
    addKeywordIfContains('사유', ['생각', '이유', '삶', '시간', '기억']);
    addKeywordIfContains('감정', ['감정', '슬픔', '기쁨', '외로움', '불안']);

    if (keywords.isEmpty) {
      keywords.addAll(['문장', '기록', '독서']);
    }

    final firstKeyword = keywords[0];
    final secondKeyword = keywords.length > 1 ? keywords[1] : '성장';
    final thirdKeyword = keywords.length > 2 ? keywords[2] : '사유';

    return [
      _RecommendedBook(
        title: '불편한 편의점',
        author: '김호연',
        publisher: '',
        thumbnail: '',
        keyword: firstKeyword,
        reason:
            '저장한 구절에서 따뜻한 시선과 사람 사이의 이야기를 중요하게 보는 경향이 보여요. 편안하게 읽으면서도 여운이 남는 책으로 추천합니다.',
      ),
      _RecommendedBook(
        title: '아몬드',
        author: '손원평',
        publisher: '',
        thumbnail: '',
        keyword: secondKeyword,
        reason:
            '감정, 성장, 타인에 대한 이해와 연결되는 문장을 기록한 흐름이 있어요. 인물의 변화를 따라가며 읽기 좋은 책입니다.',
      ),
      _RecommendedBook(
        title: '여행의 이유',
        author: '김영하',
        publisher: '',
        thumbnail: '',
        keyword: thirdKeyword,
        reason:
            '삶을 돌아보거나 생각을 정리하는 구절을 좋아하는 독자에게 잘 맞아요. 짧은 문장 안에서 사유를 이어가기 좋은 책입니다.',
      ),
    ];
  }

  Future<List<_RecommendedBook>> _enrichRecommendationsWithKakao(
    List<_RecommendedBook> books,
  ) async {
    final enrichedBooks = <_RecommendedBook>[];

    for (final book in books) {
      final query = '${book.title} ${book.author}'.trim();

      try {
        final results = await _bookRepository.searchBooks(query);
        final matched = _findBestKakaoBookMatch(
          results: results,
          title: book.title,
          author: book.author,
        );

        if (matched == null) {
          enrichedBooks.add(book);
          continue;
        }

        enrichedBooks.add(
          book.copyWith(
            title: matched.title.isNotEmpty ? matched.title : book.title,
            author:
                matched.authorText.isNotEmpty ? matched.authorText : book.author,
            publisher: matched.publisher,
            thumbnail: matched.thumbnail,
          ),
        );
      } catch (e) {
        debugPrint('카카오 책 검색 보정 실패: $e');
        enrichedBooks.add(book);
      }
    }

    return enrichedBooks;
  }

  KakaoBook? _findBestKakaoBookMatch({
    required List<KakaoBook> results,
    required String title,
    required String author,
  }) {
    if (results.isEmpty) return null;

    final normalizedTitle = _normalizeText(title);
    final normalizedAuthor = _normalizeText(author);

    for (final book in results) {
      final resultTitle = _normalizeText(book.title);
      final resultAuthor = _normalizeText(book.authorText);

      final titleMatched = resultTitle.contains(normalizedTitle) ||
          normalizedTitle.contains(resultTitle);

      final authorMatched = normalizedAuthor.isEmpty ||
          resultAuthor.contains(normalizedAuthor) ||
          normalizedAuthor.contains(resultAuthor);

      if (titleMatched && authorMatched) {
        return book;
      }
    }

    for (final book in results) {
      final resultTitle = _normalizeText(book.title);
      final titleMatched = resultTitle.contains(normalizedTitle) ||
          normalizedTitle.contains(resultTitle);

      if (titleMatched) {
        return book;
      }
    }

    return results.first;
  }

  String _normalizeText(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('&lt;', '')
        .replaceAll('&gt;', '')
        .replaceAll('&amp;', '')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state == _RecommendState.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('추천'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding.copyWith(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxl,
          ),
          children: [
            const _RecommendHeader(),
            const SizedBox(height: AppSpacing.lg),
            _RecommendActionCard(
              isLoading: isLoading,
              captureCount: _captureCount,
              isCachedResult: _isCachedResult,
              usedGeminiResult: _usedGeminiResult,
              onGenerate: _generateRecommendations,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildBodyByState(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyByState() {
    switch (_state) {
      case _RecommendState.ready:
        return const _RecommendReadyView();

      case _RecommendState.loading:
        return const _RecommendLoadingView();

      case _RecommendState.insufficient:
        return _RecommendInsufficientView(
          captureCount: _captureCount,
        );

      case _RecommendState.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_captures.isNotEmpty) ...[
              _AnalyzedQuoteSummary(captures: _captures),
              const SizedBox(height: AppSpacing.xl),
            ],
            _RecommendResultList(
              books: _recommendations,
              isCachedResult: _isCachedResult,
              usedGeminiResult: _usedGeminiResult,
            ),
          ],
        );

      case _RecommendState.error:
        return _RecommendErrorView(
          message: _errorMessage ?? '알 수 없는 오류가 발생했어요.',
        );
    }
  }
}

class _RecommendHeader extends StatelessWidget {
  const _RecommendHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 문장 기반 책 추천',
                  style: AppTextStyles.title,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '저장한 구절과 감상 기록을 바탕으로 나에게 어울리는 책을 추천받을 수 있어요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendActionCard extends StatelessWidget {
  const _RecommendActionCard({
    required this.isLoading,
    required this.captureCount,
    required this.isCachedResult,
    required this.usedGeminiResult,
    required this.onGenerate,
  });

  final bool isLoading;
  final int captureCount;
  final bool isCachedResult;
  final bool usedGeminiResult;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final countText = captureCount == 0 ? '아직 확인 전' : '$captureCount개 확인됨';
    final cacheText = isCachedResult ? '\n이전 추천 결과를 불러왔어요.' : '';
    final aiText =
        usedGeminiResult ? '\nGemini 분석 결과를 사용했어요.' : '\n기본 추천 로직을 사용했어요.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '추천 생성',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 구절을 분석해 추천 후보를 만들고, 카카오 책 검색 결과와 연결합니다.\n저장 구절: $countText$cacheText$aiText',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(isLoading ? '추천 생성 중...' : '추천 다시 생성하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendReadyView extends StatelessWidget {
  const _RecommendReadyView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '아직 추천을 생성하지 않았어요',
            style: AppTextStyles.bodyStrong,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 구절이 3개 이상이면 추천 결과를 확인할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RecommendLoadingView extends StatelessWidget {
  const _RecommendLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text(
            '추천 도서를 확인하는 중이에요',
            style: AppTextStyles.bodyStrong,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '저장한 문장을 분석하고 카카오 책 검색으로 도서 정보를 확인하고 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RecommendInsufficientView extends StatelessWidget {
  const _RecommendInsufficientView({
    required this.captureCount,
  });

  final int captureCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '추천을 위한 구절이 부족해요',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '현재 저장된 구절은 $captureCount개예요.\n최소 3개 이상 저장하면 추천을 생성할 수 있어요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RecommendErrorView extends StatelessWidget {
  const _RecommendErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '추천을 생성하지 못했어요',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _AnalyzedQuoteSummary extends StatelessWidget {
  const _AnalyzedQuoteSummary({
    required this.captures,
  });

  final List<Capture> captures;

  @override
  Widget build(BuildContext context) {
    final previewCaptures = captures.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '분석에 사용한 최근 구절',
            style: AppTextStyles.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.md),
          ...previewCaptures.map(
            (capture) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '“${capture.quote}”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendResultList extends StatelessWidget {
  const _RecommendResultList({
    required this.books,
    required this.isCachedResult,
    required this.usedGeminiResult,
  });

  final List<_RecommendedBook> books;
  final bool isCachedResult;
  final bool usedGeminiResult;

  @override
  Widget build(BuildContext context) {
    final sourceText = usedGeminiResult ? 'Gemini 분석 기반' : '기본 추천 로직 기반';
    final cacheText = isCachedResult ? '이전에 생성한 추천 결과' : '새로 생성한 추천 결과';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 결과',
          style: AppTextStyles.title,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$cacheText · $sourceText',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        ...books.map(
          (book) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RecommendedBookCard(book: book),
          ),
        ),
      ],
    );
  }
}

class _RecommendedBookCard extends StatelessWidget {
  const _RecommendedBookCard({
    required this.book,
  });

  final _RecommendedBook book;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (book.publisher.trim().isNotEmpty) book.publisher,
      '카카오 책 검색 확인',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecommendBookCover(url: book.thumbnail),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  book.author,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meta,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    book.keyword,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  book.reason,
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendBookCover extends StatelessWidget {
  const _RecommendBookCover({
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const _EmptyBookCover();
    }

    return ClipRRect(
      borderRadius: AppRadius.mdRadius,
      child: Image.network(
        url,
        width: 58,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _EmptyBookCover();
        },
      ),
    );
  }
}

class _EmptyBookCover extends StatelessWidget {
  const _EmptyBookCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary,
      ),
    );
  }
}

class _RecommendationBuildResult {
  const _RecommendationBuildResult({
    required this.books,
    required this.usedGeminiResult,
  });

  final List<_RecommendedBook> books;
  final bool usedGeminiResult;
}

class _RecommendedBook {
  const _RecommendedBook({
    required this.title,
    required this.author,
    required this.publisher,
    required this.thumbnail,
    required this.reason,
    required this.keyword,
  });

  final String title;
  final String author;
  final String publisher;
  final String thumbnail;
  final String reason;
  final String keyword;

  factory _RecommendedBook.fromFirestoreMap(Map<String, dynamic> map) {
    return _RecommendedBook(
      title: map['title'] as String? ?? '',
      author: map['author'] as String? ?? '',
      publisher: map['publisher'] as String? ?? '',
      thumbnail: map['thumbnail'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      keyword: map['keyword'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'author': author,
      'publisher': publisher,
      'thumbnail': thumbnail,
      'reason': reason,
      'keyword': keyword,
    };
  }

  _RecommendedBook copyWith({
    String? title,
    String? author,
    String? publisher,
    String? thumbnail,
    String? reason,
    String? keyword,
  }) {
    return _RecommendedBook(
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      thumbnail: thumbnail ?? this.thumbnail,
      reason: reason ?? this.reason,
      keyword: keyword ?? this.keyword,
    );
  }
}