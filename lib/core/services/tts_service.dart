import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> _init() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return;
    }

    await stop();
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}