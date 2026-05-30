import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/seasonal_background.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/calendar/screens/calendar_screen.dart';
import 'features/calendar/screens/event_form_screen.dart';
import 'features/gaming/screens/gaming_screen.dart';
import 'features/goals/screens/goal_form_screen.dart';
import 'features/goals/screens/goals_screen.dart';
import 'features/goals/screens/task_form_screen.dart';
import 'features/lock/screens/lock_screen.dart';
import 'features/lock/screens/lock_setup_screen.dart';
import 'features/onboarding/screen/welcome_screen.dart';
import 'features/recommender/screens/recommender_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool(WelcomeScreen.seenWelcomeKey) ?? false;

    final path = state.uri.path;
    final isGoingToWelcome = path == '/welcome';
    final forceWelcome = state.uri.queryParameters['force'] == 'true';

    final isAuthRoute = path == '/login' || path == '/register';
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    if (!hasSeenWelcome && !isGoingToWelcome) {
      return '/welcome';
    }

    if (hasSeenWelcome && isGoingToWelcome && !forceWelcome) {
      return isLoggedIn ? '/home' : '/login';
    }

    if (!isLoggedIn && !isAuthRoute && !isGoingToWelcome) {
      return '/login';
    }

    if (isLoggedIn && isAuthRoute) {
      return '/home';
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
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecommenderScreen()),
        ),
        GoRoute(
          path: '/gaming',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GamingScreen()),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GoalsScreen()),
        ),
        GoRoute(
          path: '/lock/setup',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LockSetupScreen()),
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
      builder: (context, state) =>
          TaskFormScreen(taskId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/goals/goal/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalFormScreen(),
    ),
    GoRoute(
      path: '/goals/goal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          GoalFormScreen(goalId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/calendar/event/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final dateParam = state.uri.queryParameters['date'];
        final initialDate = dateParam == null
            ? null
            : DateTime.tryParse(dateParam);

        return EventFormScreen(
          key: ValueKey('new-event-${dateParam ?? 'today'}'),
          initialDate: initialDate,
        );
      },
    ),
    GoRoute(
      path: '/calendar/event/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          EventFormScreen(eventId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/lock',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LockScreen(),
    ),
  ],
);

class TaskSchedulerApp extends ConsumerWidget {
  const TaskSchedulerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);
    final theme = MoodThemes.themeFor(selectedTheme);

    return MaterialApp.router(
      title: 'Task Scheduler',
      theme: theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: selectedTheme == MoodTheme.night
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isGamingPage = location.startsWith('/gaming');

    Widget bottomNav = NavigationBar(
      selectedIndex: _calculateSelectedIndex(context),
      onDestinationSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.gamepad_outlined),
          selectedIcon: Icon(Icons.gamepad),
          label: 'My room',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag),
          label: 'My Goals',
        ),
        NavigationDestination(
          icon: Icon(Icons.lock_outline),
          selectedIcon: Icon(Icons.lock),
          label: 'Lock',
        ),
      ],
    );

    if (!isGamingPage) {
      bottomNav = SnowCapped(borderRadius: 0, snowHeight: 7, child: bottomNav);
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!isGamingPage) const SeasonalBackground(),
          child,
          if (!isGamingPage) const SeasonalForegroundSnow(),
        ],
      ),
      bottomNavigationBar: bottomNav,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/gaming')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/goals')) return 3;
    if (location.startsWith('/lock')) return 4;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/gaming');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/goals');
        break;
      case 4:
        context.go('/lock/setup');
        break;
    }
  }
}
