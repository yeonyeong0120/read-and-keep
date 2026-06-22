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
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithEmailPassword(
            email: email,
            password: password,
            nickname: nickname,
          );
    });
    // 가입 성공 → 자동 로그인 → 화면 전환으로 본 Provider 가 dispose 될 수 있다.
    // dispose 된 뒤 state 할당은 크래시를 유발하므로 mounted 일 때만 할당한다.
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmailPassword(
            email: email,
            password: password,
          );
    });
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).signOut(),
    );
    if (!ref.mounted) return;
    state = result;
  }

  /// 공개 기본 설정(publishDefault) 토글. (MY-001 설정)
  ///
  /// 성공 시 [currentAppUserProvider] 를 무효화해 새 값을 다시 읽게 한다.
  /// currentAppUser 는 authState 변화에만 재조회하는 1회성 read 이므로,
  /// 설정 변경 후 UI 반영을 위해 명시적 invalidate 가 필요하다.
  Future<void> setPublishDefault(bool value) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).updatePublishDefault(value),
    );
    if (!ref.mounted) return;
    state = result;
    if (!result.hasError) {
      ref.invalidate(currentAppUserProvider);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: email,
          ),
    );
    if (!ref.mounted) return;
    state = result;
  }

  Future<void> resendEmailVerification() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async => ref.read(authRepositoryProvider).sendEmailVerification(),
    );
    if (!ref.mounted) return;
    state = result;
  }
}