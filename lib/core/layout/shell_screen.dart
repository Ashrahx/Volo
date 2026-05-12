import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/timer', '/tasks', '/reports'];

  int _indexFromLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_tabs[i]),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer_outlined),
              activeIcon: const Icon(Icons.timer),
              label: 'nav.timer'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.checklist_outlined),
              activeIcon: const Icon(Icons.checklist),
              label: 'nav.tasks'.tr(),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart),
              label: 'nav.reports'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
