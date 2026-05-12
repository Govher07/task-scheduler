import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/calendar/screens/event_form_screen.dart';
import 'features/goals/screens/goal_form_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/goals/screens/task_form_screen.dart';
import 'features/onboarding/screen/welcome_screen.dart';
import 'features/recommender/screens/recommender_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/goals',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome =
        prefs.getBool(WelcomeScreen.seenWelcomeKey) ?? false;

    final isGoingToWelcome = state.uri.path == '/welcome';
    final forceWelcome = state.uri.queryParameters['force'] == 'true';

    if (!hasSeenWelcome && !isGoingToWelcome) {
      return '/welcome';
    }

    if (hasSeenWelcome && isGoingToWelcome && !forceWelcome) {
      return '/goals';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => WelcomeScreen(
        forceShow: state.uri.queryParameters['force'] == 'true',
      ),
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GoalsScreen(),
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/recommend',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Theme(
              data: AppTheme.lightTheme,
              child: const RecommenderScreen(),
            ),
          ),
        ),
      ],
    ),

    GoRoute(
      path: '/goals/task/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaskFormScreen(),
    ),
    GoRoute(
      path: '/goals/task/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => TaskFormScreen(
        taskId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/goals/goal/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalFormScreen(),
    ),
    GoRoute(
      path: '/goals/goal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => GoalFormScreen(
        goalId: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/calendar/event/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dateParam = state.uri.queryParameters['date'];
        final initialDate =
            dateParam == null ? null : DateTime.tryParse(dateParam);

        return EventFormScreen(
          key: ValueKey('new-event-${dateParam ?? 'today'}'),
          initialDate: initialDate,
        );
      },
    ),
    GoRoute(
      path: '/calendar/event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => EventFormScreen(
        eventId: state.pathParameters['id'],
      ),
    ),
  ],
);

class TaskSchedulerApp extends ConsumerWidget {
  const TaskSchedulerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);

    return MaterialApp.router(
      title: 'Task Scheduler',
      theme: MoodThemes.themeFor(selectedTheme),
      darkTheme: AppTheme.darkTheme,
      themeMode:
          selectedTheme == MoodTheme.night ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'My Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'My Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outlined),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Recommend',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/goals')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/recommend')) return 2;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/goals');
      case 1:
        context.go('/calendar');
      case 2:
        context.go('/recommend');
    }
  }
}