import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../profile/providers/user_provider.dart';
import '../../workouts/models/workout.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../meal_plans/providers/meal_plan_provider.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class AssignPlansScreen extends StatefulWidget {
  final User user;

  const AssignPlansScreen({super.key, required this.user});

  @override
  State<AssignPlansScreen> createState() => _AssignPlansScreenState();
}

class _AssignPlansScreenState extends State<AssignPlansScreen> {
  String? selectedMealPlanId;
  bool _isSavingMealPlan = false;
  final Map<int, String?> _schedule = {};
  final Set<int> _savingDays = {};

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
    selectedMealPlanId = widget.user.assignedMealPlanId;

    Future.microtask(() async {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      workoutProvider.loadWorkouts();
      mealPlanProvider.loadMealPlans();

      final weekWorkouts = await userProvider.getWeekWorkouts(widget.user.id);
      if (mounted) {
        setState(() {
          for (int day = 1; day <= 6; day++) {
            _schedule[day] = weekWorkouts[day];
          }
        });
      }
    });
  }

  Future<void> _assignDay(int day, Workout workout) async {
    setState(() => _savingDays.add(day));
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.assignWorkoutToDay(
          widget.user.id, day, workout.id);
      if (mounted) {
        setState(() => _schedule[day] = workout.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar día: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDays.remove(day));
    }
  }

  Future<void> _clearDay(int day) async {
    setState(() => _savingDays.add(day));
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.removeWorkoutFromDay(widget.user.id, day);
      if (mounted) {
        setState(() => _schedule[day] = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar día: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDays.remove(day));
    }
  }

  void _showDayPicker(int day, List<Workout> workouts) {
    final currentId = _schedule[day];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.surface),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        // Descanso option
                        _BottomSheetTile(
                          title: 'Descanso',
                          subtitle: 'Sin rutina asignada',
                          icon: Icons.hotel,
                          isSelected: currentId == null,
                          onTap: () {
                            Navigator.pop(ctx);
                            _clearDay(day);
                          },
                        ),
                        const SizedBox(height: 8),
                        ...workouts.map((w) {
                          final sel = currentId == w.id;
                          return _BottomSheetTile(
                            title: w.name,
                            subtitle:
                                '${w.duration} min · ${w.exerciseCount} ejercicios',
                            icon: Icons.fitness_center,
                            isSelected: sel,
                            onTap: () {
                              Navigator.pop(ctx);
                              _assignDay(day, w);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ASIGNAR PLANES',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            _UserInfoCard(user: widget.user),

            const SizedBox(height: 28),

            // Weekly schedule section
            Row(
              children: [
                const Text(
                  'HORARIO SEMANAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                if (workoutProvider.isLoading) {
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
                    final isSaving = _savingDays.contains(day);

                    String workoutName = 'Descanso';
                    if (workoutId != null) {
                      final match = workouts
                          .where((w) => w.id == workoutId)
                          .toList();
                      if (match.isNotEmpty) workoutName = match.first.name;
                    }

                    final hasWorkout = workoutId != null;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasWorkout
                              ? AppColors.primary.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: isSaving
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
                        title: Text(
                          _dayNames[day]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
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
                        trailing: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : Icon(
                                hasWorkout ? Icons.edit : Icons.add_circle_outline,
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

            const SizedBox(height: 28),

            // Meal plan section
            const Text(
              'PLAN ALIMENTICIO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            Consumer<MealPlanProvider>(
              builder: (context, mealPlanProvider, _) {
                if (mealPlanProvider.isLoading) {
                  return Column(
                    children: List.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerCard(height: 80),
                      ),
                    ),
                  );
                }

                return Column(
                  children: mealPlanProvider.mealPlans.map((plan) {
                    final isSelected = selectedMealPlanId == plan.id;
                    return _SelectableCard(
                      title: plan.name,
                      subtitle: '${plan.calories} kcal · ${plan.category}',
                      icon: Icons.restaurant_menu,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          selectedMealPlanId = isSelected ? null : plan.id;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Save meal plan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSavingMealPlan
                    ? null
                    : () async {
                        setState(() => _isSavingMealPlan = true);
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        try {
                          if (selectedMealPlanId != null &&
                              selectedMealPlanId !=
                                  widget.user.assignedMealPlanId) {
                            await userProvider.assignMealPlan(
                                widget.user.id, selectedMealPlanId!);
                          }
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Plan alimenticio guardado'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al guardar plan: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingMealPlan = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSavingMealPlan
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Guardar Plan Alimenticio',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
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

  const _BottomSheetTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
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
          color:
              isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : Colors.white,
          ),
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

class _SelectableCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color:
                isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : Colors.white,
          ),
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
            : const Icon(
                Icons.circle_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
