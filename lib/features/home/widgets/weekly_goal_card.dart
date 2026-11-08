import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/supabase_config.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/providers/workout_session_provider.dart';

/// "Esta semana": entrenamientos hechos frente al plan del entrenador, con
/// un punto por día y el nombre del entrenador. Motiva sin tener que entrar
/// a Progreso.
class WeeklyGoalCard extends StatefulWidget {
  const WeeklyGoalCard({super.key});

  @override
  State<WeeklyGoalCard> createState() => _WeeklyGoalCardState();
}

class _WeeklyGoalCardState extends State<WeeklyGoalCard> {
  int? _planned;
  Set<int> _plannedDays = {};
  String? _trainerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('user_workout_schedule')
          .select('day_of_week')
          .eq('user_id', uid);
      final days = {
        for (final r in rows as List)
          if (r['day_of_week'] is int) r['day_of_week'] as int,
      };
      final trainer = await auth.loadTrainerName();
      if (!mounted) return;
      setState(() {
        _plannedDays = days;
        _planned = days.length;
        _trainerName = trainer;
      });
    } catch (_) {
      // Sin conexión: se muestra solo lo que hay en el dispositivo
      if (mounted) setState(() => _planned = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = AppL10n.of(context).isEn;
    final sessions = Provider.of<WorkoutSessionProvider>(context).sessions;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final trainedDays = <int>{
      for (final s in sessions)
        if (!DateTime(s.date.toLocal().year, s.date.toLocal().month,
                s.date.toLocal().day)
            .isBefore(weekStart))
          s.date.toLocal().weekday,
    };
    final done = trainedDays.length;
    final planned = _planned ?? 0;
    final ratio = planned > 0 ? (done / planned).clamp(0.0, 1.0) : 0.0;
    final letters = isEn
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    final message = planned == 0
        ? (isEn
            ? 'Your trainer has not set your weekly plan yet.'
            : 'Tu entrenador aún no te asignó un plan semanal.')
        : done >= planned
            ? (isEn ? 'Weekly goal achieved! 🎉' : '¡Meta de la semana cumplida! 🎉')
            : (isEn
                ? '${planned - done} to go this week'
                : 'Te faltan ${planned - done} esta semana');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEn ? 'This week' : 'Esta semana',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                planned > 0 ? '$done/$planned' : '$done',
                style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Un punto por día: amarillo = entrenó, borde = día con rutina
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final trained = trainedDays.contains(weekday);
              final scheduled = _plannedDays.contains(weekday);
              final isToday = weekday == today.weekday;
              return Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: trained ? AppColors.primary : AppColors.surface,
                      border: Border.all(
                        color: scheduled && !trained
                            ? AppColors.primaryText.withValues(alpha: 0.7)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: trained
                        ? Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    letters[i],
                    style: TextStyle(
                      color: isToday ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
          if (planned > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.surface,
                color: ratio >= 1 ? AppColors.success : AppColors.primaryText,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            [
              message,
              if (_trainerName != null)
                isEn ? 'Trainer: $_trainerName' : 'Entrenador: $_trainerName',
            ].join(' · '),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
