import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/dark_theme.dart';
import 'config/router/app_router.dart';
import 'config/supabase_config.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/workouts/providers/workout_provider.dart';
import 'features/meal_plans/providers/meal_plan_provider.dart';
import 'features/profile/providers/user_provider.dart';
import 'features/progress/providers/body_measurement_provider.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'features/progress/providers/achievements_provider.dart';
import 'features/workouts/providers/workout_session_provider.dart';
import 'features/workouts/providers/workout_progress_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase (credenciales compiladas con --dart-define)
  await SupabaseConfig.initialize();

  // Bloquear orientación a portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());

  // Inicializar notificaciones DESPUÉS de runApp — no bloquea el arranque
  NotificationService().initialize();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createAppRouter(_authProvider);
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            userProvider!.setAuthProvider(authProvider);
            return userProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => BodyMeasurementProvider()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutSessionProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProgressProvider()),
      ],
      child: MaterialApp.router(
        title: 'Chamos Fitness Center',
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
