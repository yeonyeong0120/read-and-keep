import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

/// [AuthRepository] 인스턴스를 제공한다.
///
/// keepAlive 로 앱 수명 동안 단일 인스턴스 유지.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

/// Firebase Auth 의 raw 인증 상태.
///
/// 로그인 / 로그아웃 / 토큰 만료 시점에 새 [User] (또는 null) 가 방출된다.
/// 일반 UI 는 [currentAppUserProvider] 를 사용한다. 본 Provider 는
/// 합성 Provider 와 Repository 디버깅용으로만 직접 사용한다.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

/// 현재 로그인된 사용자의 합성 정보 ([AppUser]) 를 제공한다.
///
/// [authStateProvider] 가 변할 때마다 Firestore 프로필을 다시 읽어 합성한다.
/// 미로그인 시 null 을 방출한다.
@Riverpod(keepAlive: true)
Stream<AppUser?> currentAppUser(Ref ref) async* {
  final authStateValue = ref.watch(authStateProvider);
  final user = authStateValue.whenOrNull(data: (u) => u);
  if (user == null) {
    yield null;
    return;
  }

  final repo = ref.read(authRepositoryProvider);
  yield await repo.readCurrentUserProfile();
}

/// 인증 관련 사용자 액션을 수행하는 AsyncNotifier.
///
/// 본 Notifier 는 "액션이 진행 중인가 / 실패했는가" 만 상태로 들고 있고,
/// 실제 사용자 정보는 [currentAppUserProvider] 에서 흐른다. 액션이 성공하면
/// authState 스트림이 자동 갱신되어 currentAppUser 가 새 값을 emit 한다.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<void> build() async {
    // 액션 전용 Notifier 이므로 초기 build 는 즉시 완료 (AsyncData(null)).
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithEmailPassword(
            email: email,
            password: password,
            nickname: nickname,
          );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmailPassword(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).signOut(),
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: email,
          ),
    );
  }

  Future<void> resendEmailVerification() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).sendEmailVerification(),
    );
  }
}