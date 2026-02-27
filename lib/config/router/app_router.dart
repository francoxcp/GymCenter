import 'package:flutter/material.dart';
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
import '../../features/progress/screens/progress_screen.dart';
import '../../features/progress/screens/body_measurements_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/legal/screens/terms_and_conditions_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

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
      location.startsWith('/edit-profile')) {
    return 3;
  }

  return 0;
}

final appRouter = GoRouter(
  initialLocation: '/login',
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

        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavBar(
            currentIndex: _locationToIndex(location),
            onTap: (index) {
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
                  context.go('/progress');
                  break;
              }
            },
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
