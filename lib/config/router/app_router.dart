import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/workouts/screens/workout_list_screen.dart';
import '../../features/workouts/screens/today_workout_screen.dart';
import '../../features/workouts/screens/workout_detail_readonly_screen.dart';
import '../../features/workouts/screens/workout_history_screen.dart';
import '../../features/workouts/screens/workout_calendar_screen.dart';
import '../../features/meal_plans/screens/meal_plan_list_screen.dart';
import '../../features/meal_plans/screens/meal_plan_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/personal_records_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/progress/screens/body_measurements_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/legal/screens/terms_and_conditions_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/privacy_settings_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/services/unsaved_changes_guard.dart';

int _locationToIndex(String location) {
  if (location.startsWith('/workouts') ||
      location.startsWith('/workout-detail') ||
      location.startsWith('/today-workout') ||
      location.startsWith('/workout-history') ||
      location.startsWith('/workout-calendar')) {
    return 1;
  }

  if (location.startsWith('/meal-plans') ||
      location.startsWith('/meal-plan-detail')) {
    return 2;
  }

  if (location.startsWith('/progress') ||
      location.startsWith('/body-measurements') ||
      location.startsWith('/settings') ||
      location.startsWith('/profile') ||
      location.startsWith('/edit-profile') ||
      location.startsWith('/personal-records')) {
    return 3;
  }

  return 0;
}

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final path = state.uri.path;
      const publicRoutes = {
        '/login',
        '/register',
        '/forgot-password',
        '/onboarding',
      };

      if (!isAuth && !publicRoutes.contains(path)) return '/login';
      if (isAuth && path == '/login') return authProvider.initialRoute;
      // Admin siempre va al panel de administración
      if (isAuth && authProvider.isAdmin && path == '/home') return '/admin';
      // Primer login: redirigir a onboarding si faltan datos de fitness
      if (isAuth && authProvider.needsOnboarding && path != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          final isAdmin = authProvider.isAdmin;
          final location = state.uri.path;

          // Rutas raíz donde el gesto atrás saldría de la app
          const rootPaths = {
            '/home',
            '/admin',
            '/workouts',
            '/meal-plans',
            '/profile'
          };
          final isRootRoute = rootPaths.contains(location);

          return _DoubleBackToExit(
            enabled: isRootRoute,
            child: Scaffold(
              body: child,
              bottomNavigationBar: BottomNavBar(
                currentIndex: _locationToIndex(location),
                onTap: (index) async {
                  if (!await UnsavedChangesGuard.canNavigate()) return;
                  switch (index) {
                    case 0:
                      context.go(isAdmin ? '/admin' : '/home');
                      break;
                    case 1:
                      context.go('/workouts');
                      break;
                    case 2:
                      context.go('/meal-plans');
                      break;
                    case 3:
                      context.go('/profile');
                      break;
                  }
                },
              ),
            ),
          );
        },
        routes: [
          // Main routes
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Workout routes
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutListScreen(),
          ),
          GoRoute(
            path: '/workout-detail/:id',
            builder: (context, state) {
              final workoutId = state.pathParameters['id']!;
              return WorkoutDetailReadonlyScreen(workoutId: workoutId);
            },
          ),
          GoRoute(
            path: '/today-workout',
            builder: (context, state) {
              final extraId = state.uri.queryParameters['workoutId'];
              return TodayWorkoutScreen(extraWorkoutId: extraId);
            },
          ),
          GoRoute(
            path: '/workout-history',
            builder: (context, state) => const WorkoutHistoryScreen(),
          ),
          GoRoute(
            path: '/workout-calendar',
            builder: (context, state) => const WorkoutCalendarScreen(),
          ),

          // Meal plan routes
          GoRoute(
            path: '/meal-plans',
            builder: (context, state) => const MealPlanListScreen(),
          ),
          GoRoute(
            path: '/meal-plan-detail/:id',
            builder: (context, state) {
              final mealPlanId = state.pathParameters['id']!;
              return MealPlanDetailScreen(mealPlanId: mealPlanId);
            },
          ),

          // Profile routes
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/personal-records',
            builder: (context, state) => const PersonalRecordsScreen(),
          ),

          // Progress routes
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/body-measurements',
            builder: (context, state) => const BodyMeasurementsScreen(),
          ),

          // Settings routes
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: '/privacy-settings',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),

          // Legal routes
          GoRoute(
            path: '/terms-and-conditions',
            builder: (context, state) => const TermsAndConditionsScreen(),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),

          // Admin routes
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ],
      ),
    ],
  );
}

class _DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _DoubleBackToExit({required this.child, required this.enabled});

  @override
  State<_DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<_DoubleBackToExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final now = DateTime.now();
        final twoSeconds = const Duration(seconds: 2);
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > twoSeconds) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presiona atrás de nuevo para salir'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: widget.child,
    );
  }
}
