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
import 'features/auth/screens/biometric_lock_screen.dart';
import 'features/workouts/providers/workout_provider.dart';
import 'features/meal_plans/providers/meal_plan_provider.dart';
import 'features/profile/providers/user_provider.dart';
import 'features/progress/providers/body_measurement_provider.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'features/progress/providers/achievements_provider.dart';
import 'features/workouts/providers/workout_session_provider.dart';
import 'features/workouts/providers/workout_progress_provider.dart';
import 'shared/services/biometric_service.dart';
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
  late final _DoubleBackButtonDispatcher _backButtonDispatcher;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authProvider = AuthProvider();
    _userProvider = UserProvider()..setAuthProvider(_authProvider);
    _preferencesProvider = PreferencesProvider();
    _router = createAppRouter(_authProvider);
    _backButtonDispatcher = _DoubleBackButtonDispatcher(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      preferencesProvider: _preferencesProvider,
    );
    // Registrar el router en NotificationService para manejar deep links
    NotificationService.setRouter(_router);

    // Propagar cambios de auth a los providers dependientes fuera del build
    _authProvider.addListener(_onAuthChanged);
    // Trigger inicial para que PreferencesProvider cargue si ya hay sesión
    _preferencesProvider.onAuthChanged(_authProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Al salir de la app, marcar como bloqueada si biometría está activa
      _checkAndLock();
    }
  }

  Future<void> _checkAndLock() async {
    if (!_authProvider.isAuthenticated) return;
    final enabled = await BiometricService().isEnabled();
    if (enabled && mounted) {
      setState(() => _isLocked = true);
    }
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
        builder: (context, prefsProvider, _) {
          final app = MaterialApp.router(
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
            routeInformationParser: _router.routeInformationParser,
            routeInformationProvider: _router.routeInformationProvider,
            routerDelegate: _router.routerDelegate,
            backButtonDispatcher: _backButtonDispatcher,
            // Siempre indicarle al sistema que nosotros manejamos el botón atrás.
            // Sin esto, Flutter envía canHandlePop=false en pantallas raíz y
            // Android cierra la app directamente sin pasar por nuestro dispatcher.
            onNavigationNotification: (notification) {
              SystemNavigator.setFrameworkHandlesBack(true);
              return true;
            },
          );

          if (_isLocked) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: darkTheme,
              home: BiometricLockScreen(
                onUnlocked: () => setState(() => _isLocked = false),
              ),
            );
          }

          return app;
        },
      ),
    );
  }
}

/// Dispatcher personalizado que intercepta el botón atrás del sistema.
/// Primero deja que go_router intente hacer pop normalmente (vía invokeCallback).
/// Solo si go_router no puede hacer pop (pantalla raíz), aplica doble-atrás.
class _DoubleBackButtonDispatcher extends RootBackButtonDispatcher {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final PreferencesProvider preferencesProvider;
  DateTime? _lastBackPress;

  _DoubleBackButtonDispatcher({
    required this.scaffoldMessengerKey,
    required this.preferencesProvider,
  });

  @override
  Future<bool> didPopRoute() async {
    // invokeCallback ejecuta el callback registrado por el widget Router,
    // que a su vez llama a routerDelegate.popRoute().
    // Si go_router puede hacer pop (pantalla interna) → retorna true.
    // Si no puede (pantalla raíz) → retorna false.
    final handled = await invokeCallback(Future<bool>.value(false));
    if (handled) {
      return true; // go_router hizo pop normalmente
    }

    // Estamos en una pantalla raíz — requiere doble atrás para salir.
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      final locale = preferencesProvider.appLocale.languageCode;
      final message = locale == 'en'
          ? 'Press back again to exit the app'
          : 'Presiona atrás de nuevo para salir de la aplicación';
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return true; // Interceptado — no salir
    }

    // Segunda pulsación dentro de 2 s — salir de la app
    SystemNavigator.pop();
    return true;
  }
}
