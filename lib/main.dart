import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  // Silenciar debugPrint en builds de producción
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthProvider _authProvider;
  late final UserProvider _userProvider;
  late final PreferencesProvider _preferencesProvider;
  late final GoRouter _router;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();
    _userProvider = UserProvider()..setAuthProvider(_authProvider);
    _preferencesProvider = PreferencesProvider();
    _router = createAppRouter(_authProvider);
    // Registrar el router en NotificationService para manejar deep links
    NotificationService.setRouter(_router);

    // Propagar cambios de auth a los providers dependientes fuera del build
    _authProvider.addListener(_onAuthChanged);
    // Trigger inicial para que PreferencesProvider cargue si ya hay sesión
    _preferencesProvider.onAuthChanged(_authProvider);

    // Registrar observer DESPUÉS del primer frame para que Router (go_router)
    // se registre primero. Así go_router maneja pops normales y nuestro
    // observer solo se invoca cuando go_router ya no puede hacer pop (raíz).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(this);
    });
  }

  void _onAuthChanged() {
    _preferencesProvider.onAuthChanged(_authProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // Este método solo se invoca cuando go_router ya no puede hacer pop
    // (estamos en una ruta raíz sin historial de navegación).
    // Requiere doble atrás para salir de la app.
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      final locale = _preferencesProvider.appLocale.languageCode;
      final message = locale == 'en'
          ? 'Press back again to exit'
          : 'Presiona atrás de nuevo para salir';
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return true; // Interceptamos — no salir
    }

    // Segunda pulsación dentro de 2 s — salir de la app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider(create: (_) => BodyMeasurementProvider()),
        ChangeNotifierProvider.value(value: _preferencesProvider),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutSessionProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProgressProvider()),
      ],
      child: Consumer<PreferencesProvider>(
        builder: (context, prefsProvider, _) => MaterialApp.router(
          scaffoldMessengerKey: _scaffoldMessengerKey,
          title: 'Chamos Fitness Center',
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          locale: prefsProvider.appLocale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
