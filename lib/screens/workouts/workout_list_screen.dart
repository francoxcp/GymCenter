import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_workout_screen.dart';
import 'edit_workout_screen.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/filter_chip_button.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAMOS FITNESS CENTER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Lista de Rutinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar rutinas por nombre...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChipButton(
                      label: 'Todos',
                      isSelected: workoutProvider.selectedFilter == 'Todos',
                      onTap: () => workoutProvider.setFilter('Todos'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'Principiante',
                      isSelected:
                          workoutProvider.selectedFilter == 'Principiante',
                      onTap: () => workoutProvider.setFilter('Principiante'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'Intermedio',
                      isSelected:
                          workoutProvider.selectedFilter == 'Intermedio',
                      onTap: () => workoutProvider.setFilter('Intermedio'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'Avanzado',
                      isSelected: workoutProvider.selectedFilter == 'Avanzado',
                      onTap: () => workoutProvider.setFilter('Avanzado'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Workout List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workoutProvider.filteredWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = workoutProvider.filteredWorkouts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () =>
                            context.push('/workout-detail/${workout.id}'),
                        child: _WorkoutCard(
                          title: workout.name,
                          duration: workout.duration,
                          exerciseCount: workout.exerciseCount,
                          level: workout.level,
                          isClickable: true,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditWorkoutScreen(workout: workout),
                              ),
                            );
                            if (result == true) {
                              workoutProvider.loadWorkouts(forceRefresh: true);
                            }
                          },
                          onDelete: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text(
                                  '¿Eliminar rutina?',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: Text(
                                  '¿Estás seguro de eliminar "${workout.name}"? Esta acción no se puede deshacer.',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true) {
                              try {
                                await workoutProvider.deleteWorkout(workout.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Rutina eliminada correctamente'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al eliminar: $e'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              // End of List
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Fin de la lista',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final workoutProvider =
                    Provider.of<WorkoutProvider>(context, listen: false);

                final result = await navigator.push(
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutScreen(),
                  ),
                );

                if (result == true) {
                  await workoutProvider.loadWorkouts(forceRefresh: true);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.add,
                color: Colors.black,
                size: 32,
              ),
            )
          : null,
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String title;
  final int duration;
  final int exerciseCount;
  final String level;
  final bool isClickable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    this.isClickable = false,
    this.onEdit,
    this.onDelete,
  });

  Color _getLevelColor() {
    switch (level) {
      case 'Principiante':
        return AppColors.badgePrincipiante;
      case 'Intermedio':
        return AppColors.badgeIntermedio;
      case 'Avanzado':
        return AppColors.badgeAvanzado;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getLevelColor(),
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$duration min',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$exerciseCount ejercicios',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  onEdit!();
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Editar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (isClickable)
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
