import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/reports/report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/language_screen.dart';
import '../../features/tasks/create_task_screen.dart';
import '../layout/shell_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(bool onboarded) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: onboarded ? '/timer' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (ctx, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/timer', builder: (ctx, state) => const TimerScreen()),
          GoRoute(path: '/tasks', builder: (ctx, state) => const TasksScreen()),
          GoRoute(
            path: '/reports',
            builder: (ctx, state) => const ReportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/language',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/create-task',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const CreateTaskScreen(),
      ),
    ],
  );
}
