import 'package:firebase_core/firebase_core.dart';

/// AI(Gemini) 호출 전용 보조 Firebase 프로젝트(read-and-keep-ai, Spark 무료) 옵션.
///
/// 데이터(Firestore/Storage/Auth)는 기본 앱([DefaultFirebaseOptions])을 그대로
/// 사용하고, Gemini 호출만 본 보조 앱으로 분리해 기본 프로젝트의 결제 선불 차단을
/// 우회한다. 값은 docs/google-services.json(보조 프로젝트, android)에서 추출했다.
///
/// 기본 앱의 firebase_options.dart 와 동일하게 빌드에 필요하므로 커밋한다.
const FirebaseOptions aiFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBIEac6_aIE1gi2hpfG4UEVYJUaboUDjCg',
  appId: '1:311449760375:android:27076a5f5304c246d64c72',
  messagingSenderId: '311449760375',
  projectId: 'read-and-keep-ai',
  storageBucket: 'read-and-keep-ai.firebasestorage.app',
);
