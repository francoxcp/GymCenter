import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/dark_theme.dart';
import 'config/router/app_router.dart';
import 'config/supabase_config.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/biometric_lock_screen.dart';
import 'features/workouts/providers/workout_provider.dart';
import 'features/profile/providers/user_provider.dart';
import 'features/progress/providers/body_measurement_provider.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'features/progress/providers/achievements_provider.dart';
import 'features/workouts/providers/workout_session_provider.dart';
import 'features/workouts/providers/workout_progress_provider.dart';
import 'shared/services/biometric_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/offline_sync_queue.dart';
import 'shared/web/web_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Silenciar debugPrint en builds de producción
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Web: URLs limpias (/workouts en lugar de /#/workouts). Necesario para
  // que los enlaces de correo de Supabase y las notificaciones funcionen.
  if (kIsWeb) usePathUrlStrategy();

  // Inicializar Supabase (credenciales compiladas con --dart-define)
  await SupabaseConfig.initialize();

  // Bloquear orientación a portrait (en web lo decide el manifest de la PWA)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  Future<void> bootstrap() async {
    // Cola de cambios hechos sin conexión (series, sesiones, progreso)
    await OfflineSyncQueue.instance.init();
    runApp(const MyApp());
    // Inicializar notificaciones DESPUÉS de runApp — no bloquea el arranque
    NotificationService().initialize();
  }

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        // Solo capturar errores en producción
        options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
        options.environment = kReleaseMode ? 'production' : 'development';
        // No enviar PII del usuario por defecto
        options.sendDefaultPii = false;
        // Filtrar datos personales antes de enviar cualquier evento
        options.beforeSend = (event, hint) {
          return event.copyWith(
            user: null,
            request: event.request?.copyWith(
              data: null,
              queryString: null,
              cookies: null,
            ),
          );
        };
      },
      appRunner: bootstrap,
    );
  } else {
    await bootstrap();
  }
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
  late final WorkoutProvider _workoutProvider;
  late final GoRouter _router;
  _DoubleBackButtonDispatcher? _backButtonDispatcher;
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isLocked = false;
  bool _wasAuthenticated = false;
  // Web: momento en que la pestaña/PWA pasó a segundo plano.
  DateTime? _backgroundedAt;
  // Web: ruta pendiente si la app se abrió desde una notificación.
  String? _pendingLaunchPath;
  static const _webLockGrace = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authProvider = AuthProvider();
    _userProvider = UserProvider()..setAuthProvider(_authProvider);
    _preferencesProvider = PreferencesProvider();
    _workoutProvider = WorkoutProvider();
    _router = createAppRouter(_authProvider);
    // En web el botón atrás lo gestiona el navegador.
    if (!kIsWeb) {
      _backButtonDispatcher = _DoubleBackButtonDispatcher(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        preferencesProvider: _preferencesProvider,
      );
    }
    // Registrar el router en NotificationService para manejar deep links
    NotificationService.setRouter(_router);

    if (kIsWeb) {
      // Notificación tocada con la app abierta → navegar dentro de la app.
      WebBridge.setNavigateHandler((path) {
        if (_authProvider.isAuthenticated) {
          _router.go(path);
        } else {
          _pendingLaunchPath = path;
        }
      });
      final launchPath = WebBridge.consumeLaunchPath();
      if (launchPath.startsWith('/')) _pendingLaunchPath = launchPath;
    }

    // Sesión restaurada al abrir la app: pedir biometría si está activada.
    // (Tras un login con contraseña no se pide, porque no hay sesión previa.)
    if (SupabaseConfig.hasActiveSession) {
      BiometricService().isEnabled().then((enabled) {
        if (enabled && mounted) setState(() => _isLocked = true);
      });
    }

    // Propagar cambios de auth a los providers dependientes fuera del build
    _authProvider.addListener(_onAuthChanged);
    // Trigger inicial para que PreferencesProvider cargue si ya hay sesión
    _preferencesProvider.onAuthChanged(_authProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) {
      // En web cambiar de pestaña es muy frecuente: solo se bloquea si la app
      // estuvo en segundo plano más de [_webLockGrace].
      if (state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused) {
        _backgroundedAt ??= DateTime.now();
      } else if (state == AppLifecycleState.resumed) {
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (since != null &&
            DateTime.now().difference(since) >= _webLockGrace) {
          _checkAndLock();
        }
      }
      return;
    }
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
    // Al cerrar sesión, limpiar datos en memoria para evitar filtración
    // de datos de un usuario a otro en el mismo dispositivo.
    if (_wasAuthenticated && !_authProvider.isAuthenticated) {
      _workoutProvider.clearData();
    }
    // Al quedar autenticado, ir a la ruta pendiente de una notificación.
    if (!_wasAuthenticated && _authProvider.isAuthenticated) {
      final pending = _pendingLaunchPath;
      if (pending != null) {
        _pendingLaunchPath = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _router.go(pending));
      }
    }
    _wasAuthenticated = _authProvider.isAuthenticated;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    _workoutProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: OfflineSyncQueue.instance),
        ChangeNotifierProvider.value(value: _workoutProvider),
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
            // Web en pantallas anchas (tablet/PC): la app está diseñada para
            // el móvil, así que se centra en una columna de ancho de teléfono.
            builder: kIsWeb ? (context, child) => _PhoneFrame(child: child) : null,
            // Siempre indicarle al sistema que nosotros manejamos el botón atrás.
            // Sin esto, Flutter envía canHandlePop=false en pantallas raíz y
            // Android cierra la app directamente sin pasar por nuestro dispatcher.
            onNavigationNotification: kIsWeb
                ? null
                : (notification) {
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

/// Centra la app en una columna de ancho de teléfono cuando la ventana del
/// navegador es más ancha (tablet, PC). En el móvil no cambia nada.
class _PhoneFrame extends StatelessWidget {
  final Widget? child;
  const _PhoneFrame({required this.child});

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= _maxWidth || child == null) {
      return child ?? const SizedBox.shrink();
    }
    return ColoredBox(
      color: const Color(0xFF050505),
      child: Center(
        child: SizedBox(
          width: _maxWidth,
          child: MediaQuery(
            data: mq.copyWith(size: Size(_maxWidth, mq.size.height)),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
