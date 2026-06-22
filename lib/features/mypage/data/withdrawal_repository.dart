import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 회원 탈퇴 요청 저장소 (MY-008).
///
/// 학부 과제 안전 방식: 계정/데이터를 즉시 완전 삭제하지 않고, `withdrawals`
/// 컬렉션에 탈퇴 요청만 기록한다. 실제 삭제는 운영자가 콘솔에서 수동 처리한다.
class WithdrawalRepository {
  WithdrawalRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    return user.uid;
  }

  /// 탈퇴 요청 기록을 생성한다.
  ///
  /// [reason](선택 사유)·[message](선택 소감)는 미입력 시 null 로 저장된다.
  /// 쓰기에는 `withdrawals` 컬렉션에 대한 Firestore 보안 규칙이 필요하다(콘솔 설정).
  /// 규칙이 없으면 PERMISSION_DENIED 가 전파되며, 호출하는 쪽에서 안내한다.
  Future<void> requestWithdrawal({
    String? reason,
    String? message,
  }) async {
    final userId = _uid;

    await _firestore.collection('withdrawals').add({
      'userId': userId,
      'reason': reason,
      'message': message,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'requested',
    });
  }
}
