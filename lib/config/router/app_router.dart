import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/workouts/workout_list_screen.dart';
import '../../screens/workouts/today_workout_screen.dart';
import '../../screens/workouts/workout_detail_screen.dart';
import '../../screens/workouts/workout_history_screen.dart';
import '../../screens/workouts/workout_calendar_screen.dart';
import '../../screens/meal_plans/meal_plan_list_screen.dart';
import '../../screens/meal_plans/meal_plan_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/progress/body_measurements_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';

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
        return WorkoutDetailScreen(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/today-workout',
      builder: (context, state) => const TodayWorkoutScreen(),
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

    // Admin routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
