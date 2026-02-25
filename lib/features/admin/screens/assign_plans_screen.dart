import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../profile/providers/user_provider.dart';
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
  String? selectedWorkoutId;
  String? selectedMealPlanId;
  bool _isLoading = false;
  List<int> selectedDays = [];

  @override
  void initState() {
    super.initState();
    selectedWorkoutId = widget.user.assignedWorkoutId;
    selectedMealPlanId = widget.user.assignedMealPlanId;
    
    // Cargar rutinas y planes de comida al iniciar
    Future.microtask(() {
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);
      
      workoutProvider.loadWorkouts();
      mealPlanProvider.loadMealPlans();
    });
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
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerCard(height: 120),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Container(
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
                            widget.user.name[0].toUpperCase(),
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
                                widget.user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.user.email,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nivel: ${widget.user.level}',
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
                  ),

                  const SizedBox(height: 24),

                  // Workout Section
                  const Text(
                    'RUTINA DE ENTRENAMIENTO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Consumer<WorkoutProvider>(
                    builder: (context, workoutProvider, child) {
                      if (workoutProvider.isLoading) {
                        return Column(
                          children: List.generate(
                            3,
                            (index) => const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: ShimmerCard(height: 80),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: workoutProvider.workouts.map((workout) {
                          final isSelected = selectedWorkoutId == workout.id;
                          return _SelectableCard(
                            title: workout.name,
                            subtitle:
                                '${workout.duration} min • ${workout.exerciseCount} ejercicios',
                            icon: Icons.fitness_center,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                selectedWorkoutId =
                                    isSelected ? null : workout.id;
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Meal Plan Section
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
                    builder: (context, mealPlanProvider, child) {
                      if (mealPlanProvider.isLoading) {
                        return Column(
                          children: List.generate(
                            3,
                            (index) => const Padding(
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
                            subtitle:
                                '${plan.calories} kcal • ${plan.category}',
                            icon: Icons.restaurant_menu,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                selectedMealPlanId =
                                    isSelected ? null : plan.id;
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Selector de días para asignar rutina
                  const Text(
                    'Selecciona los días para asignar la rutina:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(6, (index) {
                      final dayNumber = index + 1;
                      final dayName = [
                        'Lunes',
                        'Martes',
                        'Miércoles',
                        'Jueves',
                        'Viernes',
                        'Sábado'
                      ][index];
                      return CheckboxListTile(
                        title: Text(dayName),
                        value: selectedDays.contains(dayNumber),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedDays.add(dayNumber);
                            } else {
                              selectedDays.remove(dayNumber);
                            }
                          });
                        },
                      );
                    }),
                  ),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
                        try {
                          // Asignar rutina por días
                          if (selectedWorkoutId != null &&
                              selectedDays.isNotEmpty) {
                            await userProvider.assignWorkoutByDay(
                                widget.user.id,
                                selectedWorkoutId!,
                                selectedDays);
                          }
                          // Asignar plan alimenticio (opcional, lógica actual)
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
                              content: Text('Planes asignados correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al asignar planes: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Guardar Asignaciones',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
            : const Icon(Icons.circle_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
