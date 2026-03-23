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

  /// Rutas raíz donde se requiere doble atrás para salir.
  static const _rootPaths = {
    '/home',
    '/admin',
    '/workouts',
    '/meal-plans',
    '/profile'
  };

  @override
  void initState() {
    super.initState();
    // Registrar ANTES de que Router se registre (se crea en build),
    // así nuestro didPopRoute se ejecuta primero.
    WidgetsBinding.instance.addObserver(this);

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
    // Obtener la ruta actual del router
    final path = _router.routeInformationProvider.value.uri.path;

    if (!_rootPaths.contains(path)) {
      // Ruta no-raíz: dejar que go_router maneje el pop normalmente
      return super.didPopRoute();
    }

    // Ruta raíz: requiere doble atrás para salir
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
