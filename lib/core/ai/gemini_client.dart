import 'package:firebase_ai/firebase_ai.dart';

import 'ai_config.dart';

/// Firebase AI Logic(Gemini Developer API) 호출 래퍼.
///
/// 모델명은 [AiConfig.geminiModel] 단일 상수를 따른다. main.dart 에서
/// Firebase.initializeApp 이 이미 호출되므로 AI 호출에 별도 인증은 필요 없다.
///
/// 본 클래스는 예외를 그대로 전파한다. 로딩/에러 상태 관리는 호출하는
/// 쪽(Notifier)이 AsyncValue 로 처리한다.
class GeminiClient {
  /// 일반 텍스트 응답을 받는다.
  ///
  /// 응답 본문([GenerateContentResponse.text])이 null 이면 [StateError].
  Future<String> generateText(String prompt) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.geminiModel,
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null) {
      throw StateError('Gemini 응답이 비어 있습니다.');
    }

    return text;
  }

  /// JSON 형식 응답을 받는다(파싱은 호출자 책임 — 다음 단계).
  ///
  /// responseMimeType 을 application/json 으로 설정한 모델로 호출한다.
  /// 응답 본문이 null 이면 [StateError].
  Future<String> generateJson(String prompt) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: AiConfig.geminiModel,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;

    if (text == null) {
      throw StateError('Gemini 응답이 비어 있습니다.');
    }

    return text;
  }
}
