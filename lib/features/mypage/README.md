# mypage feature

마이페이지/설정 영역(MY-001~008). 프로필/설정/계정/로그아웃/탈퇴를 담당한다.

## 화면

- MY-001 마이페이지 허브 — `presentation/mypage_screen.dart` (구현)
  - 프로필 카드(닉네임 + 통계 3종: 저장한 책/저장한 구절/공개한 구절)
  - 설정: 공개 기본 설정 토글(publishDefault, 실제 동작) / 알림 설정(MY-002, 준비 중) / 계정 관리(MY-003, 준비 중)
  - 기타: 공지사항(MY-004, 준비 중) / 문의하기(MY-005, 준비 중) / 로그아웃(MY-007 연결)
  - 회원 탈퇴(MY-008, 준비 중, 파괴적 시각화 유지)
- MY-007 로그아웃 확인 — `presentation/logout_confirm_screen.dart` (구현)
- MY-003 계정 관리 — `presentation/account_screen.dart` (구현)
  - 닉네임 변경(다이얼로그) / 이메일 표시(변경 불가) / 비밀번호 변경(현재 이메일로 재설정 링크 발송)
  - 계정 연동(소셜)은 보류 → "연동하기" 비활성 + "준비 중" 스낵바
- MY-008 회원 탈퇴 — `presentation/withdrawal_screen.dart` (구현)
  - 안전 방식: `withdrawals` 컬렉션에 요청 기록 → signOut → /login. 즉시 완전 삭제 안 함.
  - 동의 체크박스 게이트, 사유(선택) 드롭다운, 남기는 말(선택, 0/300)

## data / domain

- `data/withdrawal_repository.dart` — `withdrawals` 컬렉션에 탈퇴 요청 기록.
- `domain/mypage_providers.dart` — `publicCaptureCount`(공개 구절 수 집계),
  `withdrawalRepository`, `WithdrawalNotifier`(탈퇴 요청 액션).

## 진입

- 홈 우측 상단 프로필 아이콘 → MY-001.
- MY-001 "로그아웃" → MY-007 → signOut → router redirect 가 /login 으로 복귀.
- MY-001 "계정 관리" → MY-003 / "회원 탈퇴" → MY-008.

## ⚠️ 운영 설정 필요

회원 탈퇴는 `withdrawals` 컬렉션 쓰기 권한을 요구한다. Firestore 보안 규칙을
콘솔에 추가해야 한다(미설정 시 PERMISSION_DENIED). 실제 삭제는 운영자 수동 처리.

## 미구현(이번 범위 외)

MY-002 알림, MY-004 공지, MY-005 문의. 메뉴는 노출하되 "준비 중" 스낵바로 처리.
