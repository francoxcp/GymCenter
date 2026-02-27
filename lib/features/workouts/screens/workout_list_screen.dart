import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_workout_screen.dart';
import 'edit_workout_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_session_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/filter_chip_button.dart';
import '../../../shared/widgets/assigned_workout_card.dart';
import '../../../shared/widgets/coming_soon_workout_card.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _nextSchedule;

  static String _dayName(int dayOfWeek) {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return days[(dayOfWeek - 1).clamp(0, 6)];
  }

  String get _availableLabel {
    if (_nextSchedule == null) return 'Disponible mañana';
    final daysUntil = _nextSchedule!['days_until'] as int? ?? 1;
    if (daysUntil == 1) return 'Disponible mañana';
    final nextDay = _nextSchedule!['day_of_week'] as int?;
    if (nextDay != null) return 'Disponible el ${_dayName(nextDay)}';
    return 'Disponible en $daysUntil días';
  }

  @override
  void initState() {
    super.initState();
    // Cargar rutinas y sesiones al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final sessionProvider =
          Provider.of<WorkoutSessionProvider>(context, listen: false);
      workoutProvider.loadWorkouts(
        userId: authProvider.currentUser?.id,
        isAdmin: authProvider.isAdmin,
      );
      if (authProvider.currentUser?.id != null) {
        sessionProvider.loadSessions(authProvider.currentUser!.id,
            forceRefresh: true);
        _loadNextSchedule(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNextSchedule(String userId) async {
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);
    final next = await progressProvider.getNextScheduledWorkout(userId);
    if (mounted) setState(() => _nextSchedule = next);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final currentUser = authProvider.currentUser;
    final hasAssignedWorkout =
        !isAdmin && currentUser?.assignedWorkoutId != null;

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
          final assignedWorkout = hasAssignedWorkout
              ? workoutProvider.getWorkoutById(currentUser!.assignedWorkoutId!)
              : null;
          final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
          final today = DateTime.now();
          final todayCompleted = hasAssignedWorkout &&
              currentUser?.assignedWorkoutId != null &&
              sessionProvider.sessions.any((s) {
                final d = s.date.toLocal();
                return s.workoutId == currentUser!.assignedWorkoutId &&
                    d.year == today.year &&
                    d.month == today.month &&
                    d.day == today.day;
              });

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

              // Assigned Workout Hero Card (ocultar si ya se completó hoy)
              if (hasAssignedWorkout &&
                  assignedWorkout != null &&
                  !todayCompleted) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AssignedWorkoutCard(
                    workout: assignedWorkout,
                    onStart: () => context.push('/today-workout'),
                  ),
                ),
              ] else if (hasAssignedWorkout &&
                  assignedWorkout != null &&
                  todayCompleted) ...[
                // Rutina de hoy completada → mostrar próxima en estilo "próximamente"
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ComingSoonWorkoutCard(
                    workout: assignedWorkout,
                    availableLabel: _availableLabel,
                  ),
                ),
              ],
              if (hasAssignedWorkout && assignedWorkout != null) ...[
                const SizedBox(height: 24),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Todas las Rutinas',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 16),

              // Workout List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => workoutProvider.loadWorkouts(
                    forceRefresh: true,
                    userId: currentUser?.id,
                    isAdmin: isAdmin,
                  ),
                  color: AppColors.primary,
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
                                workoutProvider.loadWorkouts(
                                  forceRefresh: true,
                                  userId: currentUser?.id,
                                  isAdmin: isAdmin,
                                );
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
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete == true) {
                                try {
                                  await workoutProvider
                                      .deleteWorkout(workout.id);
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
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
            await workoutProvider.loadWorkouts(
              forceRefresh: true,
              userId: currentUser?.id,
              isAdmin: isAdmin,
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 32,
        ),
      ),
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
