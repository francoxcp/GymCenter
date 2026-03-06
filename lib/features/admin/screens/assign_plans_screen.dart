import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../profile/providers/user_provider.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class AssignPlansScreen extends StatefulWidget {
  final User user;

  const AssignPlansScreen({super.key, required this.user});

  @override
  State<AssignPlansScreen> createState() => _AssignPlansScreenState();
}

class _AssignPlansScreenState extends State<AssignPlansScreen> {
  final Map<int, String?> _schedule = {};
  Map<int, String?> _originalSchedule = {};
  bool _isLoadingSchedule = true;
  bool _isSaving = false;

  static const _dayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
  };

  static const _dayShort = {
    1: 'LU',
    2: 'MA',
    3: 'MI',
    4: 'JU',
    5: 'VI',
    6: 'SÁ',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await Future.wait([
      workoutProvider.loadWorkouts(),
      _loadSchedule(userProvider),
    ]);
  }

  Future<void> _loadSchedule(UserProvider userProvider) async {
    try {
      final weekMap = await userProvider.getWeekWorkouts(widget.user.id);
      if (mounted) {
        setState(() {
          for (int day = 1; day <= 6; day++) {
            _schedule[day] = weekMap[day];
          }
          _originalSchedule = Map.from(_schedule);
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  void _selectDay(int day, String? workoutId) {
    setState(() => _schedule[day] = workoutId);
  }

  void _showDayPicker(int day, List<Workout> workouts) {
    final currentId = _schedule[day];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String selectedCategory = 'Todos';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = selectedCategory == 'Todos'
                ? workouts
                : workouts
                    .where((w) => w.category == selectedCategory)
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              _dayNames[day]!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cerrar',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.surface),
                      // Chips de categoría
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: ['Todos', ...Workout.categories].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setSheetState(() => selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.black
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          children: [
                            if (selectedCategory == 'Todos')
                              _BottomSheetTile(
                                title: 'Día de descanso',
                                subtitle: 'Sin rutina asignada',
                                icon: Icons.hotel,
                                isSelected: currentId == null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _selectDay(day, null);
                                },
                              ),
                            if (selectedCategory == 'Todos')
                              const SizedBox(height: 8),
                            if (filtered.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'No hay rutinas en esta categoría',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...filtered.map((w) {
                                final sel = currentId == w.id;
                                return _BottomSheetTile(
                                  title: w.name,
                                  subtitle:
                                      '${w.duration} min · ${w.exerciseCount} ejercicios',
                                  icon: Icons.fitness_center,
                                  isSelected: sel,
                                  badge: w.category,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _selectDay(day, w.id);
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      for (int day = 1; day <= 6; day++) {
        final original = _originalSchedule[day];
        final current = _schedule[day];
        if (original == current) continue;

        if (current != null) {
          await userProvider.assignWorkoutToDay(widget.user.id, day, current);
        } else {
          await userProvider.removeWorkoutFromDay(widget.user.id, day);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rutina guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASIGNAR RUTINA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserInfoCard(user: widget.user),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'RUTINA SEMANAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Toca un día para asignar',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Consumer<WorkoutProvider>(
                    builder: (context, workoutProvider, _) {
                      final workouts = workoutProvider.workouts;

                      if (_isLoadingSchedule || workoutProvider.isLoading) {
                        return Column(
                          children: List.generate(
                            6,
                            (_) => const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: ShimmerCard(height: 72),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: List.generate(6, (index) {
                          final day = index + 1;
                          final workoutId = _schedule[day];
                          final hasChange =
                              _originalSchedule[day] != workoutId;

                          String workoutName = 'Día de descanso';
                          if (workoutId != null) {
                            final match = workouts
                                .where((w) => w.id == workoutId)
                                .toList();
                            if (match.isNotEmpty) {
                              workoutName = match.first.name;
                            }
                          }

                          final hasWorkout = workoutId != null;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasChange
                                    ? AppColors.primary
                                    : hasWorkout
                                        ? AppColors.primary.withOpacity(0.4)
                                        : Colors.transparent,
                                width: hasChange ? 2 : 1.5,
                              ),
                            ),
                            child: ListTile(
                              onTap: _isSaving
                                  ? null
                                  : () => _showDayPicker(day, workouts),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: hasWorkout
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    _dayShort[day]!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: hasWorkout
                                          ? Colors.black
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    _dayNames[day]!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (hasChange) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'modificado',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                workoutName,
                                style: TextStyle(
                                  color: hasWorkout
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                hasWorkout
                                    ? Icons.edit
                                    : Icons.add_circle_outline,
                                color: hasWorkout
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Botón guardar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving || _isLoadingSchedule
                    ? null
                    : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Guardar rutina',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  final User user;
  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 30,
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel: ${user.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _BottomSheetTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
      ),
    );
  }
}

