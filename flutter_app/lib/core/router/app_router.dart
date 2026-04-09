import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/bottom_nav_shell.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/plans/presentation/plan_days_screen.dart';
import '../../features/progress/presentation/personal_records_screen.dart';
import '../../features/session/presentation/workout_screen.dart';
import '../../features/session/presentation/workout_summary_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/records', builder: (_, __) => const PersonalRecordsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/plans/:planId/days',
        builder: (_, state) => PlanDaysScreen(planId: state.pathParameters['planId']!),
      ),
      GoRoute(
        path: '/workout',
        builder: (_, state) => WorkoutScreen(
          sessionId: state.uri.queryParameters['sessionId']!,
          dayId: state.uri.queryParameters['dayId']!,
          title: state.uri.queryParameters['title'] ?? 'Workout',
        ),
      ),
      GoRoute(
        path: '/workout/summary',
        builder: (_, state) => WorkoutSummaryScreen(
          totalDurationMinutes: double.tryParse(state.uri.queryParameters['duration'] ?? '0') ?? 0,
          totalSets: int.tryParse(state.uri.queryParameters['sets'] ?? '0') ?? 0,
        ),
      ),
    ],
  );
});
