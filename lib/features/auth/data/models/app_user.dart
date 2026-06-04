import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}` 문서와 매핑되는 사용자 모델.
///
/// Firebase Auth 의 [User] 와 Firestore 사용자 문서를 합쳐 표현한다.
/// [emailVerified] 는 Firebase Auth 측 정보, 나머지는 Firestore 측 정보다.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.publishDefault,
    required this.emailVerified,
    this.notificationSettings = const {},
  });

  final String uid;
  final String email;
  final String nickname;
  final DateTime createdAt;

  /// 구절 저장 시 공개 토글의 기본값. Privacy by Default 원칙으로 false 시작.
  final bool publishDefault;

  /// Firebase Auth 측 이메일 인증 완료 여부.
  /// Firestore 에는 저장하지 않고, 매번 Auth user 에서 읽는다.
  final bool emailVerified;

  /// 알림 설정값. 본 STEP 에서는 빈 map 으로 시작하고, 알림 feature 작업 시 채운다.
  final Map<String, dynamic> notificationSettings;

  /// Firestore 문서에서 모델로 변환.
  ///
  /// [emailVerified] 는 Firestore 에 없으므로 Auth user 에서 받아 주입한다.
  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool emailVerified,
  }) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User document ${doc.id} has no data');
    }
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishDefault: data['publishDefault'] as bool? ?? false,
      emailVerified: emailVerified,
      notificationSettings:
          data['notificationSettings'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// 신규 가입 시 Firestore 에 쓸 데이터.
  ///
  /// [createdAt] 은 클라이언트 시간이 아닌 서버 타임스탬프를 권장하므로,
  /// 실제 쓰기는 Repository 에서 `FieldValue.serverTimestamp()` 로 처리한다.
  Map<String, dynamic> toFirestoreOnCreate() {
    return {
      'email': email,
      'nickname': nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'publishDefault': false,
      'notificationSettings': <String, dynamic>{},
    };
  }
}