import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'core/ai/ai_config.dart';
import 'core/ai/ai_firebase_options.dart';
import 'features/books/data/datasources/kakao_book_cache.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 환경 변수 로드 (.env)
  await dotenv.load(fileName: '.env');

  // 2. 기본 Firebase 앱 초기화 (데이터: Firestore/Storage/Auth 용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2-1. 보조 Firebase 앱 초기화 (Gemini 호출 전용, 무료 프로젝트)
  //      초기화에 실패해도 앱 전체가 죽지 않도록 감싼다.
  //      실패 시 AI 기능만 비활성되고 나머지는 정상 동작한다.
  try {
    await Firebase.initializeApp(
      name: AiConfig.aiAppName,
      options: aiFirebaseOptions,
    );
  } catch (e) {
    debugPrint('보조 AI Firebase 앱(aiApp) 초기화 실패 - AI 기능만 비활성: $e');
  }

  // 3. Hive 초기화 + 카카오 검색 캐시 Box 오픈
  await Hive.initFlutter();
  await Hive.openBox<String>(KakaoBookCache.boxName);

  // 4. Riverpod 루트 등록 후 앱 실행
  runApp(const ProviderScope(child: ReadAndKeepApp()));
}