import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 메인 탭 셸.
///
/// [StatefulNavigationShell] 을 감싸 하단 3탭(홈/추천/트렌드) 네비게이션을 제공한다.
/// 탭 전환은 IndexedStack 기반이라 각 탭의 상태가 유지된다.
/// 탭바 스타일은 AppTheme.light 의 bottomNavigationBarTheme 를 따른다.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // 이미 선택된 탭을 다시 누르면 해당 브랜치의 최초 경로로 되돌린다.
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: '추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: '트렌드',
          ),
        ],
      ),
    );
  }
}
