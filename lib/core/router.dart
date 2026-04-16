import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/intro_screen.dart';
import '../features/performances/performance_list_screen.dart';
import '../features/performances/performance_detail_screen.dart';
import '../features/alarms/alarm_list_screen.dart';
import '../features/settings/settings_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/intro', builder: (_, __) => const IntroScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/performances', builder: (_, __) => const PerformanceListScreen()),
          GoRoute(path: '/alarms', builder: (_, __) => const AlarmListScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/performances/:id',
        builder: (_, state) {
          final perf = state.extra as dynamic;
          return PerformanceDetailScreen(perf: perf);
        },
      ),
    ],
  );
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = ['/performances', '/alarms', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          context.go(_tabs[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: '공연'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: '알림'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
