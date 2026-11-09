import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/providers/workout_provider.dart';

const weekInitials = ['L', 'K', 'M', 'J', 'V', 'S', 'D'];
const _weekNames = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

/// Semana de lunes a domingo: cada inicial muestra la rutina de ese día.
/// Hoy viene marcado; los días con rutina llevan un punto.
class WeekStrip extends StatefulWidget {
  const WeekStrip({super.key});

  @override
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  Map<int, String> _week = {};
  late int _selected = DateTime.now().weekday;
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
      // Sin conexión: la fila se muestra sin rutinas.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final workouts = context.watch<WorkoutProvider>();
    final selectedId = _week[_selected];
    final Workout? selected =
        selectedId == null ? null : workouts.getWorkoutById(selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var d = 1; d <= 7; d++)
              Expanded(
                child: _DayChip(
                  initial: weekInitials[d - 1],
                  name: _weekNames[d - 1],
                  isToday: d == today,
                  isSelected: d == _selected,
                  hasWorkout: _week[d] != null,
                  onTap: () => setState(() => _selected = d),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !_loaded
              ? const SizedBox(height: 56, key: ValueKey('loading'))
              : _DayDetail(
                  key: ValueKey(_selected),
                  dayName: _selected == today ? 'Hoy' : _weekNames[_selected - 1],
                  workout: selected,
                  hasAssignment: selectedId != null,
                ),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String initial;
  final String name;
  final bool isToday;
  final bool isSelected;
  final bool hasWorkout;
  final VoidCallback onTap;
  const _DayChip({
    required this.initial,
    required this.name,
    required this.isToday,
    required this.isSelected,
    required this.hasWorkout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected
        ? AppColors.onPrimary
        : isToday
            ? AppColors.primaryText
            : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$name${hasWorkout ? ', tiene rutina' : ', descanso'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primaryText, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(initial,
                  style: TextStyle(
                      color: fg, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasWorkout
                      ? (isSelected ? AppColors.onPrimary : AppColors.primaryText)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final String dayName;
  final Workout? workout;
  final bool hasAssignment;
  const _DayDetail({
    super.key,
    required this.dayName,
    required this.workout,
    required this.hasAssignment,
  });

  @override
  Widget build(BuildContext context) {
    final w = workout;
    if (!hasAssignment || w == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          hasAssignment ? '$dayName: rutina no disponible' : '$dayName: descanso',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/workout-detail/${w.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayName.toUpperCase(),
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(w.name,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${w.exerciseCount} ejercicios${w.duration > 0 ? ' · ${w.duration} min' : ''}',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
