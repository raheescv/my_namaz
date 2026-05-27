import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _NavItem('/home', Icons.mosque_outlined, Icons.mosque, 'Today'),
    _NavItem(
        '/calendar', Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
    _NavItem('/reports', Icons.insights_outlined, Icons.insights, 'Reports'),
    _NavItem('/qibla', Icons.explore_outlined, Icons.explore, 'Qibla'),
    _NavItem('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  int _indexFor(String loc) {
    final i = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.path, this.icon, this.activeIcon, this.label);
}
