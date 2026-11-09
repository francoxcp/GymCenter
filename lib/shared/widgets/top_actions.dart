import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../features/admin/screens/member_hub_screen.dart';
import '../../features/admin/services/member_status_service.dart';
import '../../features/admin/widgets/member_tools.dart' show showRoleChangeSheet;
import '../../features/auth/models/user.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notifications/notifications_service.dart';
import '../../features/profile/providers/user_provider.dart';
import '../../features/workouts/models/workout.dart';
import '../../features/workouts/providers/workout_provider.dart';

/// Búsqueda (solo personal) + campana de avisos, para la esquina superior
/// de las pantallas principales.
class TopActions extends StatefulWidget {
  const TopActions({super.key});

  @override
  State<TopActions> createState() => _TopActionsState();
}

class _TopActionsState extends State<TopActions> {
  @override
  void initState() {
    super.initState();
    NotificationsService.refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isStaff)
          IconButton(
            tooltip: 'Buscar socio o rutina',
            icon: Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () =>
                showSearch(context: context, delegate: AppSearchDelegate()),
          ),
        ValueListenableBuilder<int>(
          valueListenable: NotificationsService.unread,
          builder: (context, n, _) => IconButton(
            tooltip: n > 0 ? 'Avisos ($n sin leer)' : 'Avisos',
            onPressed: () async {
              await context.push('/notificaciones');
              NotificationsService.refreshUnread();
            },
            icon: Badge(
              isLabelVisible: n > 0,
              label: Text(n > 9 ? '9+' : '$n'),
              backgroundColor: AppColors.primary,
              textColor: AppColors.onPrimary,
              child: Icon(Icons.notifications_none,
                  color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Coincidencia sin tildes ni mayúsculas.
String foldText(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunAEIOUUN';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().toLowerCase().trim();
}

class AppSearchDelegate extends SearchDelegate<void> {
  AppSearchDelegate() : super(searchFieldLabel: 'Socio o rutina');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final t = Theme.of(context);
    return t.copyWith(
      appBarTheme: t.appBarTheme.copyWith(backgroundColor: AppColors.background),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
              tooltip: 'Borrar',
              icon: const Icon(Icons.close),
              onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      tooltip: 'Volver',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final q = foldText(query);
    final users = context.read<UserProvider>().users;
    final workouts = context.read<WorkoutProvider>().workouts;
    if (q.isEmpty) {
      return _hint('Escribe un nombre, correo o rutina.');
    }
    final people = users
        .where((u) =>
            foldText(u.name).contains(q) || foldText(u.email).contains(q))
        .take(12)
        .toList();
    final routines =
        workouts.where((w) => foldText(w.name).contains(q)).take(12).toList();
    if (people.isEmpty && routines.isEmpty) {
      return _hint('Nada con "$query".');
    }
    return ListView(
      children: [
        if (people.isNotEmpty) _header('PERSONAS'),
        for (final u in people) _personTile(context, u),
        if (routines.isNotEmpty) _header('RUTINAS'),
        for (final w in routines) _workoutTile(context, w),
      ],
    );
  }

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary)),
      );

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
      );

  Widget _personTile(BuildContext context, User u) {
    final role = switch (u.role) {
      'admin' => 'Dueño',
      'trainer' => 'Entrenador',
      _ => Membership.label(u.membershipEnd),
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.cardBackground,
        child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      title: Text(u.name, style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(role, style: TextStyle(color: AppColors.textSecondary)),
      onTap: u.role != 'user'
          ? (u.role == 'trainer' && context.read<AuthProvider>().isAdmin
              ? () => showRoleChangeSheet(context, u)
              : null)
          : () async {
              final nav = Navigator.of(context);
              final snap = await MemberStatusService.load([u]);
              nav.push(MaterialPageRoute(
                  builder: (_) =>
                      MemberHubScreen(member: u, status: snap.status[u.id]!)));
            },
    );
  }

  Widget _workoutTile(BuildContext context, Workout w) => ListTile(
        leading: Icon(Icons.fitness_center, color: AppColors.primaryText),
        title: Text(w.name, style: TextStyle(color: AppColors.textPrimary)),
        subtitle: Text('${w.exerciseCount} ejercicios${w.category == null ? '' : ' · ${w.category}'}',
            style: TextStyle(color: AppColors.textSecondary)),
        onTap: () {
          final router = GoRouter.of(context);
          close(context, null);
          router.push('/workout-detail/${w.id}');
        },
      );
}
