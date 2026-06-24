import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../data/models/capture.dart';

class GalleryOcrScreen extends StatefulWidget {
  const GalleryOcrScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    this.bookCoverUrl,
  });

  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String? bookCoverUrl;

  @override
  State<GalleryOcrScreen> createState() => _GalleryOcrScreenState();
}

class _GalleryOcrScreenState extends State<GalleryOcrScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;
  String? _errorMessage;

  String _ocrRawText = '';
  final List<String> _candidates = [];
  final Set<int> _selectedIndexes = {};

  Future<void> _pickImageAndRecognize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedImage = null;
      _ocrRawText = '';
      _candidates.clear();
      _selectedIndexes.clear();
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final imageFile = File(pickedFile.path);

      setState(() {
        _selectedImage = imageFile;
      });

      final inputImage = InputImage.fromFile(imageFile);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.korean,
      );

      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final candidates = _extractCandidates(recognizedText);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _ocrRawText = recognizedText.text;
        _candidates
          ..clear()
          ..addAll(candidates);
      });

      if (candidates.isEmpty) {
        setState(() {
          _errorMessage = '문장을 인식하지 못했어요. 더 선명한 사진을 선택해주세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'OCR 처리 중 오류가 발생했어요: $e';
      });
    }
  }


  List<String> _extractCandidates(RecognizedText recognizedText) {
    final orderedLines = <String>[];

    final blocks = recognizedText.blocks.toList()
      ..sort((a, b) {
        final topCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
        if (topCompare != 0) return topCompare;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });

    for (final block in blocks) {
      final lines = block.lines.toList()
        ..sort((a, b) {
          final topCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
          if (topCompare != 0) return topCompare;
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        });

      for (final line in lines) {
        final text = _cleanText(line.text);

        if (_isNoiseText(text)) {
          continue;
        }

        orderedLines.add(text);
      }
    }

    if (orderedLines.isEmpty) {
      return const [];
    }

    final mergedText = _mergeLinesToText(orderedLines);
    final sentences = _splitIntoSentences(mergedText);

    final result = <String>[];

    for (final sentence in sentences) {
      final cleaned = _cleanText(sentence);

      if (_isValidCandidate(cleaned)) {
        _addUnique(result, cleaned);
      }
    }

    return result.take(15).toList();
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('|', '')
        .replaceAll('ㆍ', ' ')
        .replaceAll('·', ' ')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('「', '')
        .replaceAll('」', '')
        .replaceAll('『', '')
        .replaceAll('』', '')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .trim();
  }

  bool _isNoiseText(String text) {
    final cleaned = text.trim();

    if (cleaned.isEmpty) return true;
    if (cleaned.length <= 1) return true;

    final lowerText = cleaned.toLowerCase();

    if (lowerText.contains('isbn')) return true;
    if (lowerText.contains('http')) return true;
    if (lowerText.contains('www.')) return true;
    if (lowerText.contains('copyright')) return true;
    if (cleaned.contains('출판')) return true;
    if (cleaned.contains('펴낸')) return true;
    if (cleaned.contains('지은이')) return true;
    if (cleaned.contains('옮긴이')) return true;
    if (cleaned.contains('차례')) return true;
    if (cleaned.contains('목차')) return true;

    if (RegExp(r'^\d{1,4}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^-?\s*\d{1,4}\s*-?$').hasMatch(cleaned)) return true;

    final digitCount = RegExp(r'[0-9]').allMatches(cleaned).length;
    if (digitCount >= cleaned.length * 0.35) return true;

    final symbolCount =
        RegExp(r'[^가-힣a-zA-Z0-9\s.,!?…()\-]').allMatches(cleaned).length;
    if (symbolCount >= cleaned.length * 0.45) return true;

    return false;
  }

  bool _isValidCandidate(String text) {
    if (text.isEmpty) return false;
    if (text.length < 8) return false;

    final koreanCount = RegExp(r'[가-힣]').allMatches(text).length;
    final englishCount = RegExp(r'[a-zA-Z]').allMatches(text).length;
    final digitCount = RegExp(r'[0-9]').allMatches(text).length;
    final symbolCount =
        RegExp(r'[^가-힣a-zA-Z0-9\s.,!?…()\-]').allMatches(text).length;

    if (koreanCount + englishCount < 6) return false;
    if (digitCount >= text.length * 0.30) return false;
    if (symbolCount >= text.length * 0.45) return false;

    final lowerText = text.toLowerCase();

    if (lowerText.contains('isbn')) return false;
    if (lowerText.contains('http')) return false;
    if (lowerText.contains('www.')) return false;
    if (lowerText.contains('copyright')) return false;
    if (lowerText.contains('출판')) return false;
    if (lowerText.contains('펴낸')) return false;
    if (lowerText.contains('지은이')) return false;
    if (lowerText.contains('옮긴이')) return false;

    if (RegExp(r'^\d{1,4}$').hasMatch(text)) return false;
    if (RegExp(r'^-?\s*\d{1,4}\s*-?$').hasMatch(text)) return false;

    if (!text.contains(' ') && text.length < 12) return false;

    return true;
  }

  String _mergeLinesToText(List<String> lines) {
    final buffer = StringBuffer();

    for (final line in lines) {
      final text = line.trim();
      if (text.isEmpty) continue;

      if (buffer.isEmpty) {
        buffer.write(text);
        continue;
      }

      final previous = buffer.toString().trimRight();

      if (_looksLikeSentenceEnd(previous)) {
        buffer.write('\n$text');
      } else {
        buffer.write(' $text');
      }
    }

    return buffer.toString();
  }

  bool _looksLikeSentenceEnd(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    if (RegExp(r'[.!?。！？…]$').hasMatch(trimmed)) {
      return true;
    }

    final koreanEndings = [
      '습니다',
      '입니다',
      '였다',
      '이었다',
      '했다',
      '하였다',
      '된다',
      '한다',
      '있다',
      '없다',
      '였다',
      '었다',
      '다',
      '요',
      '죠',
      '까',
      '네',
      '군요',
      '구나',
    ];

    for (final ending in koreanEndings) {
      if (trimmed.endsWith(ending)) {
        return true;
      }
    }

    return false;
  }

  bool _isSentenceBoundary(String text, int index, String current) {
    final char = text[index];

    if (RegExp(r'[.!?。！？…]').hasMatch(char)) {
      return true;
    }

    final nextChar = index + 1 < text.length ? text[index + 1] : '';

    // 한국어 종결어미는 단어/문장 끝에서만 자른다.
    // 다음 글자가 바로 이어지는 한글이면 중간 단어일 가능성이 있어서 자르지 않는다.
    if (nextChar.isNotEmpty && nextChar != ' ') {
      return false;
    }

    return _looksLikeSentenceEnd(current);
  }

  List<String> _splitIntoSentences(String text) {
    final normalized = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' .', '.')
        .replaceAll(' ?', '?')
        .replaceAll(' !', '!')
        .trim();

    if (normalized.isEmpty) {
      return const [];
    }

    final result = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      buffer.write(char);

      final current = buffer.toString().trim();

      if (current.length >= 12 && _isSentenceBoundary(normalized, i, current)) {
        result.add(current);
        buffer.clear();

        // 문장 뒤 공백은 다음 문장 시작 전 제거
        while (i + 1 < normalized.length && normalized[i + 1] == ' ') {
          i++;
        }
      }
    }

    final remain = buffer.toString().trim();

    if (remain.isNotEmpty) {
      if (result.isNotEmpty &&
          remain.length < 8 &&
          !_looksLikeSentenceEnd(remain)) {
        final last = result.removeLast();
        result.add('$last $remain'.trim());
      } else {
        result.add(remain);
      }
    }

    return result;
  }

  void _addUnique(List<String> result, String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), '');

    final exists = result.any((old) {
      final oldNormalized = old.replaceAll(RegExp(r'\s+'), '');

      if (oldNormalized == normalized) return true;

      if (oldNormalized.contains(normalized) && normalized.length > 10) {
        return true;
      }

      if (normalized.contains(oldNormalized) && oldNormalized.length > 10) {
        return true;
      }

      return false;
    });

    if (!exists) {
      result.add(text);
    }
  }

  void _toggleCandidate(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndexes
        ..clear()
        ..addAll(List.generate(_candidates.length, (index) => index));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });
  }

  void _goToConfirm() {
    if (_selectedIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 문장을 먼저 선택해주세요.')),
      );
      return;
    }

    final sortedIndexes = _selectedIndexes.toList()..sort();

    final selectedText = sortedIndexes.map((index) => _candidates[index]).join('\n');

    context.push(
      AppRoutes.captureConfirm,
      extra: (
        bookId: widget.bookId,
        bookTitle: widget.bookTitle,
        bookAuthor: widget.bookAuthor,
        bookPublisher: widget.bookPublisher,
        bookCoverUrl: widget.bookCoverUrl,
        initialQuote: selectedText,
        initialPageNumber: null,
        initialComment: '',
        source: CaptureSource.gallery,
        ocrRawText: _ocrRawText,
      ),
    );
  }

  void _goToConfirmWithRawText() {
    if (_ocrRawText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인식된 전체 텍스트가 없어요.')),
      );
      return;
    }

    context.push(
      AppRoutes.captureConfirm,
      extra: (
        bookId: widget.bookId,
        bookTitle: widget.bookTitle,
        bookAuthor: widget.bookAuthor,
        bookPublisher: widget.bookPublisher,
        bookCoverUrl: widget.bookCoverUrl,
        initialQuote: _ocrRawText.trim(),
        initialPageNumber: null,
        initialComment: '',
        source: CaptureSource.gallery,
        ocrRawText: _ocrRawText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIndexes.length;
    final hasCandidates = _candidates.isNotEmpty;
    final hasRawText = _ocrRawText.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      appBar: AppBar(
        title: const Text('갤러리 문장 선택'),
        backgroundColor: const Color(0xFFF9F7F2),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  const Text(
                    '사진을 선택하고 문장을 인식해보세요.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '짧은 글과 숫자 위주의 잡텍스트는 최대한 제외해요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B625B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _BookCard(
                    title: widget.bookTitle,
                    author: widget.bookAuthor,
                    publisher: widget.bookPublisher,
                    coverUrl: widget.bookCoverUrl,
                  ),
                  const SizedBox(height: 20),
                  _ImagePickCard(
                    imageFile: _selectedImage,
                    isLoading: _isLoading,
                    candidateCount: _candidates.length,
                    onPressed: _isLoading ? null : _pickImageAndRecognize,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (hasCandidates) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '인식된 문장',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '선택 $selectedCount개 / 전체 ${_candidates.length}개',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B625B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectAll,
                            child: const Text('전체 선택'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearSelection,
                            child: const Text('선택 해제'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_candidates.length, (index) {
                      final text = _candidates[index];
                      final isSelected = _selectedIndexes.contains(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CandidateCard(
                          text: text,
                          isSelected: isSelected,
                          onTap: () => _toggleCandidate(index),
                        ),
                      );
                    }),
                  ],
                  if (!hasCandidates && hasRawText && !_isLoading) ...[
                    const SizedBox(height: 20),
                    _RawTextFallbackCard(
                      onPressed: _goToConfirmWithRawText,
                    ),
                  ],
                ],
              ),
            ),
            if (hasCandidates)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: selectedCount == 0 ? null : _goToConfirm,
                      icon: const Icon(Icons.check_rounded),
                      label: Text('선택한 문장으로 수정하기 ($selectedCount개)'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.title,
    required this.author,
    required this.publisher,
    this.coverUrl,
  });

  final String title;
  final String author;
  final String publisher;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final meta = publisher.trim().isEmpty ? author : '$author · $publisher';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDD5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 58,
              height: 82,
              color: const Color(0xFFEDE7DF),
              child: coverUrl == null || coverUrl!.isEmpty
                  ? const Icon(Icons.menu_book_rounded)
                  : Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(Icons.menu_book_rounded);
                      },
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B625B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePickCard extends StatelessWidget {
  const _ImagePickCard({
    required this.imageFile,
    required this.isLoading,
    required this.candidateCount,
    required this.onPressed,
  });

  final File? imageFile;
  final bool isLoading;
  final int candidateCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDD5)),
      ),
      child: Column(
        children: [
          if (imageFile == null)
            const Icon(
              Icons.image_outlined,
              size: 54,
              color: Color(0xFF6B625B),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                imageFile!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            imageFile == null ? '사진을 선택해주세요' : '사진 선택 완료',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading
                ? '문장을 인식하는 중이에요.'
                : imageFile == null
                    ? '책 페이지가 선명하게 나온 사진을 선택해주세요.'
                    : '인식된 후보 $candidateCount개',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B625B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.image_rounded),
              label: Text(
                isLoading
                    ? '문장 인식 중...'
                    : imageFile == null
                        ? '사진 선택하기'
                        : '다른 사진 선택하기',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFFFF1D9) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD9912B)
                  : const Color(0xFFE4DDD5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? const Color(0xFFD9912B)
                    : const Color(0xFF8A8178),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RawTextFallbackCard extends StatelessWidget {
  const _RawTextFallbackCard({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDD5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD9912B),
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            '문장 후보가 적게 나왔어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '전체 인식 텍스트를 수정 화면으로 보내서 직접 다듬을 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B625B),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onPressed,
            child: const Text('전체 인식 텍스트로 수정하기'),
          ),
        ],
      ),
    );
  }
}