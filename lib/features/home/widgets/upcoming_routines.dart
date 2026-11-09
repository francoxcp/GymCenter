import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../../workouts/providers/workout_provider.dart';

const _names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/// Próximos 6 días a partir de mañana: (etiqueta, día de la semana 1–7).
List<(String, int)> upcomingDays(DateTime now) => [
      for (var i = 1; i <= 6; i++)
        (
          i == 1 ? 'Mañana' : _names[now.add(Duration(days: i)).weekday - 1],
          now.add(Duration(days: i)).weekday,
        )
    ];

/// "Próximas rutinas": mañana y los días siguientes, deslizando.
class UpcomingRoutines extends StatefulWidget {
  const UpcomingRoutines({super.key});

  @override
  State<UpcomingRoutines> createState() => _UpcomingRoutinesState();
}

class _UpcomingRoutinesState extends State<UpcomingRoutines> {
  Map<int, String> _week = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = context.read<AuthProvider>().currentUser?.id;
    if (id == null) return;
    try {
      final w = await context.read<UserProvider>().getWeekWorkouts(id);
      if (mounted) setState(() => _week = w);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _week.isEmpty) return const SizedBox.shrink();
    final workouts = context.watch<WorkoutProvider>();
    final days = upcomingDays(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PRÓXIMAS RUTINAS',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (label, weekday) = days[i];
              final wid = _week[weekday];
              final w = wid == null ? null : workouts.getWorkoutById(wid);
              final rest = w == null;
              return Material(
                color: i == 0 && !rest
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: w == null ? null : () => context.push('/workout-detail/${w.id}'),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: i == 0 && !rest
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryText, width: 1.2))
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label.toUpperCase(),
                            style: TextStyle(
                                color: i == 0 ? AppColors.primaryText : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const Spacer(),
                        Text(w == null ? 'Descanso' : w.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: rest ? AppColors.textSecondary : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.15)),
                        if (w != null)
                          Text(
                              '${w.exerciseCount} ejercicios${w.duration > 0 ? ' · ${w.duration} min' : ''}',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
