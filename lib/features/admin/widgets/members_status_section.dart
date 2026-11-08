import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/supabase_config.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../models/member_status.dart';
import '../screens/member_hub_screen.dart';

/// "Mis socios" con semáforo de constancia (panel del entrenador/dueño).
/// La base de datos ya filtra: el entrenador solo recibe a SUS socios.
class MembersStatusSection extends StatefulWidget {
  const MembersStatusSection({super.key});

  @override
  State<MembersStatusSection> createState() => MembersStatusSectionState();
}

class MembersStatusSectionState extends State<MembersStatusSection> {
  Map<String, MemberStatus> _status = {};
  bool _loading = true;
  bool _error = false;
  MemberLight? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final users = Provider.of<UserProvider>(context, listen: false)
          .users
          .where((u) => u.role == 'user')
          .toList();
      final since = DateTime.now().subtract(const Duration(days: 35));
      final results = await Future.wait([
        SupabaseConfig.client
            .from('workout_sessions')
            .select('user_id, completed_at')
            .gte('completed_at', since.toUtc().toIso8601String()),
        SupabaseConfig.client.from('user_workout_schedule').select('user_id'),
      ]);
      final sessionsByUser = <String, List<DateTime>>{};
      for (final r in results[0] as List) {
        final d = DateTime.tryParse(r['completed_at'] as String? ?? '');
        if (d == null) continue;
        sessionsByUser.putIfAbsent(r['user_id'] as String, () => []).add(d);
      }
      final plannedByUser = <String, int>{};
      for (final r in results[1] as List) {
        final id = r['user_id'] as String;
        plannedByUser[id] = (plannedByUser[id] ?? 0) + 1;
      }
      final now = DateTime.now();
      final map = {
        for (final u in users)
          u.id: MemberStatus.compute(
            userId: u.id,
            plannedPerWeek: plannedByUser[u.id] ?? 0,
            sessions: sessionsByUser[u.id] ?? const [],
            now: now,
          ),
      };
      if (!mounted) return;
      setState(() {
        _status = map;
        _loading = false;
      });
    } catch (e) {
      debugPrint('MembersStatusSection error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  static Color colorOf(MemberLight l) => switch (l) {
        MemberLight.red => AppColors.error,
        MemberLight.yellow => Colors.orangeAccent,
        MemberLight.green => AppColors.success,
      };

  String _subtitle(MemberStatus s, bool isEn) {
    final days = s.daysSinceLast(DateTime.now());
    final last = days == null
        ? (isEn ? 'Never trained' : 'Nunca ha entrenado')
        : days == 0
            ? (isEn ? 'Trained today' : 'Entrenó hoy')
            : (isEn ? '$days days ago' : 'Hace $days días');
    final week = s.plannedPerWeek > 0
        ? '${s.sessionsThisWeek}/${s.plannedPerWeek}'
        : '${s.sessionsThisWeek}';
    return isEn ? '$last · This week: $week' : '$last · Semana: $week';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppL10n.of(context).isEn;
    final isOwner = Provider.of<AuthProvider>(context).isAdmin;
    final userProvider = Provider.of<UserProvider>(context);
    final members = userProvider.users.where((u) => u.role == 'user').toList();

    final counts = {
      for (final l in MemberLight.values)
        l: _status.values.where((s) => s.light == l).length,
    };
    var list = members.where((u) => _status.containsKey(u.id)).toList();
    if (_filter != null) {
      list = list.where((u) => _status[u.id]!.light == _filter).toList();
    }
    list.sort((a, b) {
      final la = _status[a.id]!.light.index, lb = _status[b.id]!.light.index;
      if (la != lb) return la.compareTo(lb); // rojos primero
      return a.name.compareTo(b.name);
    });

    Widget chip(MemberLight? l, String label) {
      final selected = _filter == l;
      final color = l == null ? AppColors.primary : colorOf(l);
      return GestureDetector(
        onTap: () => setState(() => _filter = selected ? null : l),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : Colors.transparent, width: 1.2),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? color : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isOwner
                    ? (isEn ? 'Members' : 'Socios')
                    : (isEn ? 'My members' : 'Mis socios'),
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: isEn ? 'Refresh' : 'Actualizar',
              onPressed: _loading ? null : reload,
              icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(MemberLight.red,
                  '🔴 ${isEn ? 'Absent' : 'Sin venir'} ${counts[MemberLight.red]}'),
              const SizedBox(width: 8),
              chip(MemberLight.yellow,
                  '🟡 ${isEn ? 'Behind' : 'Atrasados'} ${counts[MemberLight.yellow]}'),
              const SizedBox(width: 8),
              chip(MemberLight.green,
                  '🟢 ${isEn ? 'On track' : 'Al día'} ${counts[MemberLight.green]}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          )
        else if (_error)
          TextButton.icon(
            onPressed: reload,
            icon: const Icon(Icons.refresh),
            label: Text(isEn
                ? 'Could not load. Retry'
                : 'No se pudo cargar. Reintentar'),
          )
        else if (members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isEn
                  ? 'You have no members yet. Share your trainer code or use "New member" in User management.'
                  : 'Aún no tienes socios. Comparte tu código de entrenador o usa "Nuevo socio" en Gestión de usuarios.',
              style:
                  TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          )
        else
          ...list.map((u) => _memberTile(u, _status[u.id]!, isEn)),
      ],
    );
  }

  Widget _memberTile(User u, MemberStatus s, bool isEn) {
    final color = colorOf(s.light);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MemberHubScreen(member: u, status: s)));
          reload();
        },
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          backgroundImage:
              u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
          child: u.photoUrl == null
              ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(u.name,
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(_subtitle(s, isEn),
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}
