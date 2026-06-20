import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';
import 'features/books/data/datasources/kakao_book_cache.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 환경 변수 로드 (.env)
  await dotenv.load(fileName: '.env');

  // 2. Firebase 초기화 (flutterfire configure 로 생성된 옵션 사용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Hive 초기화 + 카카오 검색 캐시 Box 오픈
  await Hive.initFlutter();
  await Hive.openBox<String>(KakaoBookCache.boxName);

  // 4. Riverpod 루트 등록 후 앱 실행
  runApp(const ProviderScope(child: ReadAndKeepApp()));
}