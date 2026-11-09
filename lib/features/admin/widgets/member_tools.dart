import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/notifications_screen.dart' show timeAgo;
import '../../profile/providers/user_provider.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/providers/workout_provider.dart';

const dayShort = ['L', 'K', 'M', 'J', 'V', 'S'];
const dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext) b) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: b(ctx),
        ),
      ),
    );

Widget _title(String t) => Text(t,
    style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w900));

// ─────────────────────────────────────────────────────────────────────────────
// Asignación rápida: un día + una rutina, filtrando por objetivo (categoría)
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showQuickAssignSheet(BuildContext context, User member) async {
  final workouts = context.read<WorkoutProvider>().workouts;
  final userProvider = context.read<UserProvider>();
  final now = DateTime.now().weekday;
  var day = now >= 1 && now <= 6 ? now : 1;
  String? goal;
  final goals = {
    for (final w in workouts)
      if ((w.category ?? '').isNotEmpty) w.category!
  }.toList()
    ..sort();

  final picked = await _sheet<Workout>(
    context,
    (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final list =
          workouts.where((w) => goal == null || w.category == goal).toList();
      return SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _title('Rutina para ${member.name.split(' ').first}'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var d = 1; d <= 6; d++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ChoiceChip(
                          label: SizedBox(
                              width: double.infinity,
                              child: Text(dayShort[d - 1],
                                  textAlign: TextAlign.center)),
                          tooltip: dayNames[d - 1],
                          selected: day == d,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: day == d
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary),
                          onSelected: (_) => setState(() => day = d),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (goals.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final g in [null, ...goals])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(g ?? 'Todas'),
                          selected: goal == g,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => goal = g),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No hay rutinas con ese objetivo.',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final w = list[i];
                        return ListTile(
                          title: Text(w.name,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              [
                                if (w.category != null) w.category!,
                                '${w.exerciseCount} ejercicios',
                                w.level,
                              ].join(' · '),
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          trailing: Icon(Icons.add_circle_outline,
                              color: AppColors.primaryText),
                          onTap: () => Navigator.pop(ctx, w),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }),
  );
  if (picked == null) return;
  try {
    await userProvider.assignWorkoutToDay(member.id, day, picked.id);
    if (context.mounted) {
      AppSnackbar.success(
          context, '${picked.name} asignada el ${dayNames[day - 1].toLowerCase()}');
    }
  } catch (_) {
    if (context.mounted) AppSnackbar.error(context, 'No se pudo asignar');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Copiar el plan semanal de otro socio
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showCopyPlanSheet(BuildContext context, User member) async {
  final others = context
      .read<UserProvider>()
      .users
      .where((u) => u.role == 'user' && u.id != member.id)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  final from = await _sheet<User>(
    context,
    (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: _title('Copiar plan de…'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
                'Se reemplaza la semana de ${member.name} por la del socio que elijas.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: others.isEmpty
                ? Center(
                    child: Text('No hay otros socios.',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: others.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(others[i].name,
                          style: TextStyle(color: AppColors.textPrimary)),
                      trailing: Icon(Icons.content_copy,
                          color: AppColors.textSecondary, size: 20),
                      onTap: () => Navigator.pop(ctx, others[i]),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
  if (from == null) return;
  try {
    final n = await SupabaseConfig.client.rpc('copy_member_plan',
        params: {'p_from': from.id, 'p_to': member.id});
    if (!context.mounted) return;
    final count = (n as num?)?.toInt() ?? 0;
    AppSnackbar.success(
        context,
        count == 0
            ? '${from.name} no tenía plan; la semana quedó vacía'
            : 'Copiados $count días del plan de ${from.name}');
  } catch (_) {
    if (context.mounted) AppSnackbar.error(context, 'No se pudo copiar el plan');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notas privadas (el socio no las ve)
// ─────────────────────────────────────────────────────────────────────────────
class MemberNote {
  final String id;
  final String? authorId;
  final String body;
  final DateTime createdAt;
  const MemberNote(this.id, this.authorId, this.body, this.createdAt);
}

class MemberNotesSection extends StatefulWidget {
  final String memberId;
  const MemberNotesSection({super.key, required this.memberId});

  @override
  State<MemberNotesSection> createState() => _MemberNotesSectionState();
}

class _MemberNotesSectionState extends State<MemberNotesSection> {
  final _ctrl = TextEditingController();
  List<MemberNote> _notes = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await SupabaseConfig.client
          .from('member_notes')
          .select('id, author_id, body, created_at')
          .eq('member_id', widget.memberId)
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _notes = [
          for (final r in rows as List)
            MemberNote(r['id'] as String, r['author_id'] as String?,
                r['body'] as String, DateTime.parse(r['created_at']).toLocal()),
        ];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    final me = context.read<AuthProvider>().currentUser?.id;
    if (me == null) return;
    setState(() => _saving = true);
    try {
      await SupabaseConfig.client.from('member_notes').insert(
          {'member_id': widget.memberId, 'author_id': me, 'body': body});
      _ctrl.clear();
      await _load();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudo guardar la nota');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(MemberNote n) async {
    try {
      await SupabaseConfig.client.from('member_notes').delete().eq('id', n.id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser?.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('NOTAS PRIVADAS',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Lesiones, preferencias, lo que hablaron. El socio no las ve.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ej.: molestia en rodilla izquierda',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Guardar nota',
                onPressed: _saving ? null : _add,
                icon: Icon(Icons.send, color: AppColors.primaryText),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final n in _notes)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body,
                              style: TextStyle(
                                  color: AppColors.textPrimary, height: 1.35)),
                          const SizedBox(height: 2),
                          Text(timeAgo(n.createdAt),
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    if (n.authorId == me)
                      IconButton(
                        tooltip: 'Borrar nota',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () => _delete(n),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
