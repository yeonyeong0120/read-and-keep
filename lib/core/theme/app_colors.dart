import 'package:flutter/material.dart';

/// 읽다남김 컬러 토큰
///
/// 화면설계서 3.3.1 컬러 시스템의 역할 정의를 정본으로 하며,
/// 대표 화면 PNG 5장에서 추출한 값을 역할당 단일값으로 수렴시킨 결과다.
///
/// 명명은 색상명(brown 등)이 아닌 역할(primary 등) 기준으로 한다.
/// 본 파일은 의미 토큰만 노출하는 단일 계층 구조다. 다크 모드 도입 시
/// 참조 토큰 계층과 on-color 대비쌍을 분리 도입한다.
///
/// 색상 투명도 조정 시 withOpacity 대신 Color.withValues(alpha: value)를 사용한다.
abstract final class AppColors {
  AppColors._();

  // --- 브랜드 / 강조 ---

  /// 딥 브라운. Primary 버튼, 활성 탭 라벨, 제목 강조에 사용한다.
  static const Color primary = Color(0xFF6B4A2E);

  /// Primary 위에 올라가는 전경색(버튼 라벨 등).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 라이트 브라운. Secondary 버튼 테두리, 보조 텍스트 강조에 사용한다.
  static const Color primaryLight = Color(0xFF9C8466);

  // --- 배경 / 표면 ---

  /// 앱 전체 기본 배경(베이지/크림). 전 화면 공통으로 통일한다.
  static const Color background = Color(0xFFFAF6F0);

  /// 카드 기본 배경(흰색). 책 카드, 구절 카드, 설정 메뉴 카드에 사용한다.
  static const Color surface = Color(0xFFFFFFFF);

  /// 라이트 베이지. 강조 섹션 카드, 경고 안내 박스, 키워드 칩 배경에 사용한다.
  static const Color surfaceVariant = Color(0xFFF6EFE6);

  // --- 텍스트 ---

  /// 본문 텍스트. 진한 회색에 가까운 따뜻한 무채색.
  static const Color textPrimary = Color(0xFF2A241F);

  /// 부연 설명, 캡션, 메타데이터에 사용하는 중간 회색.
  static const Color textSecondary = Color(0xFF8C857C);

  /// 입력 필드 플레이스홀더 등 약한 안내 텍스트.
  static const Color textHint = Color(0xFFADA59D);

  // --- 선 / 구분 ---

  /// 입력 필드 테두리, 구분선(divider)에 사용하는 연한 따뜻한 회색.
  static const Color outline = Color(0xFFE2D9CD);

  // --- 상태색 ---

  /// 파괴적 액션(회원 탈퇴 등) 전용. 일반 액션에는 사용하지 않는다.
  static const Color destructive = Color(0xFFDC6359);

  /// Destructive 위에 올라가는 전경색.
  static const Color onDestructive = Color(0xFFFFFFFF);

  /// 인기 배지("이번 주 N위"), 주의 안내 등에 사용하는 골드/황색.
  static const Color warning = Color(0xFFC99A4E);

  /// 체크 표시, 인증 완료, 완료 토스트에 사용하는 초록.
  /// 대표 화면 PNG에 미노출되어 팔레트 톤에 맞춰 신규 정의한 값이다.
  static const Color success = Color(0xFF4E8C6A);

  // --- 비활성 ---

  /// 비활성 버튼 배경(회색). 조건 미충족 시 사용한다.
  static const Color disabledBackground = Color(0xFFE8E2DA);

  /// 비활성 버튼/요소의 텍스트 색.
  static const Color disabledText = Color(0xFFADA59D);
}
