# mypage feature

마이페이지/설정 영역(MY-001~008). 프로필/설정/계정/로그아웃/탈퇴를 담당한다.

## 화면

- MY-001 마이페이지 허브 — `presentation/mypage_screen.dart` (구현)
  - 프로필 카드(닉네임 + 통계 3종: 저장한 책/저장한 구절/공개한 구절)
  - 설정: 공개 기본 설정 토글(publishDefault, 실제 동작) / 알림 설정(MY-002, 준비 중) / 계정 관리(MY-003, 준비 중)
  - 기타: 공지사항(MY-004, 준비 중) / 문의하기(MY-005, 준비 중) / 로그아웃(MY-007 연결)
  - 회원 탈퇴(MY-008, 준비 중, 파괴적 시각화 유지)
- MY-007 로그아웃 확인 — `presentation/logout_confirm_screen.dart` (구현)

## domain

- `domain/mypage_providers.dart` — `publicCaptureCount`(공개한 구절 수 집계).

## 진입

- 홈 우측 상단 프로필 아이콘 → MY-001.
- MY-001 "로그아웃" → MY-007 → signOut → router redirect 가 /login 으로 복귀.

## 미구현(이번 범위 외)

MY-002 알림, MY-003 계정 관리, MY-004 공지, MY-005 문의, MY-008 탈퇴.
메뉴 항목은 노출하되 탭 시 "준비 중입니다" 스낵바로 처리한다.
