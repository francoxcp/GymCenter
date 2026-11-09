import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/social/activity_feed_screen.dart';
import '../../features/organization/screens/invitation_screen.dart';
import '../../shared/widgets/splash_screen.dart';
import '../../features/organization/screens/join_organization_screen.dart';
import '../../features/organization/screens/my_organization_screen.dart';
import '../../features/organization/screens/platform_screen.dart';
import '../../features/admin/screens/memberships_screen.dart';
import 'package:provider/provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_link_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/workouts/screens/workout_list_screen.dart';
import '../../features/workouts/screens/today_workout_screen.dart';
import '../../features/workouts/screens/workout_detail_readonly_screen.dart';
import '../../features/workouts/screens/workout_history_screen.dart';
import '../../features/workouts/screens/workout_calendar_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/personal_records_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/progress/screens/body_measurements_screen.dart';
import '../../features/progress/screens/achievements_screen.dart';
import '../../features/progress/screens/training_control_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/user_assignments_list_screen.dart';
import '../../features/workouts/screens/create_workout_screen.dart';
import '../../features/legal/screens/terms_and_conditions_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/privacy_settings_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/navigation/role_tabs.dart';
import '../../shared/widgets/role_guide.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/chat/chat_screens.dart';
import '../../features/chat/chat_service.dart';
import '../../features/admin/screens/members_screen.dart';
import '../../features/admin/screens/trainer_today_screen.dart';
import '../../shared/services/unsaved_changes_guard.dart';

NavRole navRoleOf(AuthProvider auth) => auth.isAdmin
    ? NavRole.owner
    : auth.isTrainer
        ? NavRole.trainer
        : NavRole.member;

/// Enlace profundo pendiente: en web se puede abrir directamente /workouts,
/// /admin/organization, /platform (también desde una notificación). Mientras
/// se restaura la sesión o se inicia sesión se muestra /login y después se
/// vuelve a la ruta pedida.
class DeepLinkMemory {
  DeepLinkMemory._();
  static String? _pending;
  static void remember(String location) => _pending = location;
  static String? take() {
    final p = _pending;
    _pending = null;
    return p;
  }
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
        '/reset-password',
        '/onboarding',
      };

      // Raíz del sitio (web) o enlaces de correo de Supabase (/?code=...)
      if (path == '/' || path.isEmpty) {
        return isAuth ? authProvider.initialRoute : '/login';
      }

      // Enlaces de invitación: públicos (con o sin sesión)
      if (path.startsWith('/invitacion/')) return null;

      // Mientras se restaura la sesión guardada: pantalla de carga con la
      // marca (antes se veía el formulario de inicio de sesión unos segundos)
      if (path == '/cargando') {
        if (isAuth) return DeepLinkMemory.take() ?? authProvider.initialRoute;
        return authProvider.isInitializing ? null : '/login';
      }
      if (!isAuth && authProvider.isInitializing && !publicRoutes.contains(path)) {
        DeepLinkMemory.remember(state.uri.toString());
        return '/cargando';
      }

      if (!isAuth && !publicRoutes.contains(path)) {
        // Se recuerda siempre (no solo al restaurar): la sesión guardada en
        // web puede llegar después de la primera redirección.
        DeepLinkMemory.remember(state.uri.toString());
        return '/login';
      }
      if (isAuth && path == '/login') {
        return DeepLinkMemory.take() ?? authProvider.initialRoute;
      }
      // Password recovery: redirigir a change-password hasta que el usuario
      // complete el cambio de contraseña o cierre sesión
      if (isAuth && authProvider.isPasswordRecovery && path != '/change-password') {
        return '/change-password';
      }
      // Multi-cliente: cuenta sin gimnasio → pantalla para unirse
      if (isAuth && authProvider.needsOrganization) {
        return path == '/unirme' ? null : '/unirme';
      }
      if (isAuth && path == '/unirme') return authProvider.initialRoute;
      // Cliente suspendido por la plataforma (el dueño puede ir a pagar)
      if (isAuth && authProvider.isOrgSuspended && !authProvider.isPlatformAdmin) {
        const allowed = {'/suspendido', '/admin/organization'};
        if (!allowed.contains(path) ||
            (path == '/admin/organization' && !authProvider.isAdmin)) {
          return '/suspendido';
        }
        return null;
      }
      if (isAuth && path == '/suspendido') return authProvider.initialRoute;
      if (isAuth && path.startsWith('/platform') && !authProvider.isPlatformAdmin) {
        return authProvider.initialRoute;
      }
      if (isAuth && path == '/admin/organization' && !authProvider.isAdmin) {
        return authProvider.initialRoute;
      }
      // Admin siempre va al panel de administración
      if (isAuth && authProvider.isStaff && path == '/home') return '/admin';
      // Bloquear acceso a TODAS las rutas admin para usuarios no-admin
      // (en web cualquiera puede escribir la URL a mano).
      if (isAuth && !authProvider.isStaff && path.startsWith('/admin')) {
        return '/home';
      }
      // La lista de chats es del entrenador; el socio tiene uno solo
      if (isAuth && !authProvider.isStaff && path.startsWith('/chats')) {
        return '/chat';
      }
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
        path: '/cargando',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/invitacion/:token',
        builder: (context, state) =>
            InvitationScreen(token: state.pathParameters['token'] ?? ''),
      ),
      GoRoute(
        path: '/unirme',
        builder: (context, state) => const JoinOrganizationScreen(),
      ),
      GoRoute(
        path: '/suspendido',
        builder: (context, state) => const SuspendedOrganizationScreen(),
      ),
      GoRoute(
        path: '/chats/:memberId',
        builder: (context, state) =>
            TrainerChatScreen(memberId: state.pathParameters['memberId']!),
      ),
      GoRoute(
        path: '/platform',
        builder: (context, state) =>
            PlatformScreen(openOrgId: state.uri.queryParameters['org']),
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
        path: '/reset-password',
        builder: (context, state) => ResetPasswordLinkScreen(
          tokenHash: state.uri.queryParameters['token_hash'],
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Fuera del ShellRoute: sin bottom nav, pantalla completa.
      // Se usa tanto desde Configuración como desde el flujo de
      // recuperación de contraseña vía deep link de email.
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(location: state.uri.path, child: child);
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
          GoRoute(
            path: '/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
          GoRoute(
            path: '/training-control',
            builder: (context, state) => const TrainingControlScreen(),
          ),

          // Settings routes
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
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

          GoRoute(
            path: '/notificaciones',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const MemberChatScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const TrainerChatsScreen(),
          ),

          // Admin routes
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/organization',
            builder: (context, state) => const MyOrganizationScreen(),
          ),
          GoRoute(
            path: '/admin/members',
            builder: (context, state) => MembersScreen(
              initialFilter: state.uri.queryParameters['f'],
            ),
          ),
          GoRoute(
            path: '/admin/today',
            builder: (context, state) => const TrainerTodayScreen(),
          ),
          GoRoute(
            path: '/admin/memberships',
            builder: (context, state) => const MembershipsScreen(),
          ),
          GoRoute(
            path: '/admin/activity',
            builder: (context, state) => const ActivityFeedScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/assignments',
            builder: (context, state) => const UserAssignmentsListScreen(),
          ),
          GoRoute(
            path: '/admin/user-progress/:id',
            builder: (context, state) => TrainingControlScreen(
              userId: state.pathParameters['id'],
              userName: state.uri.queryParameters['name'],
            ),
          ),
          GoRoute(
            path: '/admin/create-workout',
            builder: (context, state) => const CreateWorkoutScreen(),
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatefulWidget {
  final Widget child;
  final String location;

  const _AppShell({required this.child, required this.location});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _previousIndex = 0;
  int _currentIndex = 0;
  bool _guideChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_guideChecked) return;
    _guideChecked = true;
    final role = navRoleOf(Provider.of<AuthProvider>(context, listen: false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) RoleGuide.maybeShow(context, role);
    });
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final isForward = _currentIndex >= _previousIndex;
    final isIncoming = child.key == ValueKey(_currentIndex);
    final Offset beginOffset;
    if (isIncoming) {
      beginOffset =
          isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
    } else {
      beginOffset =
          isForward ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
    }
    return SlideTransition(
      position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.currentUser;
    final role = navRoleOf(auth);
    final hasTrainer = me?.trainerId != null;
    if (me != null && (role != NavRole.member || hasTrainer)) {
      // Mantiene el contador de mensajes sin leer (idempotente)
      ChatService.startListening(
          userId: me.id, asTrainer: role != NavRole.member);
    }
    final tabs = tabsFor(role, hasTrainer: hasTrainer);
    final index = tabIndexFor(tabs, widget.location);
    if (index != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    }
    // Cliente suspendido: solo puede ver la pantalla de pago, sin pestañas.
    final hideNav = auth.isOrgSuspended && !auth.isPlatformAdmin;
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: _buildTransition,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: hideNav
          ? null
          : BottomNavBar(
              tabs: tabs,
              currentIndex: _currentIndex,
              onTap: (i) async {
                if (!await UnsavedChangesGuard.canNavigate()) return;
                if (!context.mounted) return;
                context.go(tabs[i].path);
              },
            ),
    );
  }
}
