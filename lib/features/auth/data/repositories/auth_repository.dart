import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// 인증 및 사용자 프로필을 다루는 Repository.
///
/// Firebase Auth (계정·세션) 와 Firestore `users/{uid}` (프로필) 두 소스를
/// 결합해 [AppUser] 단일 추상을 제공한다.
///
/// 본 Repository 는 Riverpod Provider 로 노출되며, 호출하는 쪽은 직접
/// FirebaseAuth/Firestore 인스턴스에 접근하지 않는다.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Firebase Auth 의 인증 상태 변화 스트림.
  ///
  /// 로그인 / 로그아웃 / 세션 만료 시점에 새 [User] (또는 null) 가 방출된다.
  /// 본 스트림은 STEP 5-B 의 authStateProvider 에서 사용한다.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 현재 로그인된 Firebase Auth 사용자. 미로그인 시 null.
  User? get currentAuthUser => _auth.currentUser;

  /// 이메일/비밀번호로 신규 가입.
  ///
  /// 1. Firebase Auth 계정 생성
  /// 2. Firestore `users/{uid}` 문서 생성 (nickname·publishDefault 등)
  /// 3. 인증 메일 발송
  ///
  /// 어느 단계에서든 실패 시 [FirebaseAuthException] 또는 [FirebaseException] 이
  /// 그대로 전파된다. 호출하는 쪽 (AuthNotifier) 에서 AsyncValue.guard 로 감싼다.
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    final newUser = AppUser(
      uid: user.uid,
      email: email,
      nickname: nickname,
      createdAt: DateTime.now(), // 실제 저장값은 serverTimestamp
      publishDefault: false,
      emailVerified: user.emailVerified,
    );
    await _usersRef.doc(user.uid).set(newUser.toFirestoreOnCreate());

    await user.sendEmailVerification();

    return newUser;
  }

  /// 이메일/비밀번호로 로그인.
  ///
  /// 인증 성공 후 Firestore 사용자 문서를 읽어 [AppUser] 로 반환한다.
  /// 사용자 문서가 없는 경우 (외부에서 직접 Auth 만 생성된 케이스) 는
  /// [StateError] 를 던진다.
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return _readUserProfile(user);
  }

  /// 비밀번호 재설정 메일 발송.
  ///
  /// 이메일 미존재 시에도 예외를 던지지 않게 처리하는 정책 (보안 권장 사항) 은
  /// 호출하는 쪽 (AuthNotifier) 에서 결정한다.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// 현재 사용자에게 인증 메일 재발송. 미로그인 시 [StateError].
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user to send verification email');
    }
    await user.sendEmailVerification();
  }

  Future<void> signOut() => _auth.signOut();

  /// 닉네임([AppUser.nickname]) 을 갱신한다. (MY-003 계정 관리)
  ///
  /// `users/{uid}` 문서의 nickname 필드를 merge 로 갱신한다. 미로그인 시 [StateError].
  /// 입력 검증(공백·길이)은 호출하는 쪽에서 수행한다.
  Future<void> updateNickname(String nickname) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    await _usersRef.doc(user.uid).set(
      {'nickname': nickname},
      SetOptions(merge: true),
    );
  }

  /// 공개 기본 설정([AppUser.publishDefault]) 을 갱신한다.
  ///
  /// publishDefault 는 `users/{uid}` 문서 필드이며 [AppUser] 가 직접 읽는 값이다.
  /// 문서/필드가 없을 수 있으므로 merge 로 생성·갱신한다. 미로그인 시 [StateError].
  Future<void> updatePublishDefault(bool value) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    await _usersRef.doc(user.uid).set(
      {'publishDefault': value},
      SetOptions(merge: true),
    );
  }

  /// 주어진 Firebase Auth user 의 Firestore 프로필을 읽어 [AppUser] 로 합성.
  ///
  /// 로그인 직후, 또는 authStateChanges 스트림에서 user 가 갱신될 때 호출된다.
  Future<AppUser> readCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }
    return _readUserProfile(user);
  }

  Future<AppUser> _readUserProfile(User user) async {
    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists) {
      throw StateError('User document ${user.uid} not found in Firestore');
    }
    return AppUser.fromFirestore(doc, emailVerified: user.emailVerified);
  }
}