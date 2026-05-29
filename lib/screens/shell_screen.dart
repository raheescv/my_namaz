import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/prayer_times_provider.dart';
import '../theme/colors.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _NavItem('/home', Icons.mosque_outlined, Icons.mosque, 'Today'),
    _NavItem('/calendar', Icons.calendar_month_outlined,
        Icons.calendar_month, 'Calendar'),
    _NavItem('/reports', Icons.insights_outlined, Icons.insights, 'Reports'),
    _NavItem('/qibla', Icons.explore_outlined, Icons.explore, 'Qibla'),
    _NavItem('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _askedForLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskLocation());
  }

  void _maybeAskLocation() {
    if (_askedForLocation || !mounted) return;
    _askedForLocation = true;
    final s = ref.read(locationProvider);
    s.whenOrNull(data: (loc) {
      if (loc == null && mounted) {
        // ignore: unawaited_futures
        ref.read(locationProvider.notifier).refresh();
      }
    });
  }

  int _indexFor(String loc) {
    final i = AppShell._tabs.indexWhere((t) => loc.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(locationProvider, (_, __) => _maybeAskLocation());

    final loc = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(loc);
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < AppShell._tabs.length; i++)
                    Expanded(
                      child: _PillTab(
                        item: AppShell._tabs[i],
                        active: i == index,
                        onTap: () => context.go(AppShell._tabs[i].path),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _PillTab(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? AppColors.primaryGreen
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? item.activeIcon : item.icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
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
