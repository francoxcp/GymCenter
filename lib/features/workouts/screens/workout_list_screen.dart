import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_workout_screen.dart';
import 'edit_workout_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
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

  Future<void> _startExtraWorkout(
    BuildContext context,
    String workoutId,
    WorkoutProgressProvider progressProvider,
  ) async {
    // Si hay una rutina en progreso, avisar al usuario
    if (progressProvider.hasProgress) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Rutina en Progreso',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tienes una rutina en curso. ¿Quieres continuar esa o iniciar esta como extra?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue_assigned'),
              child: const Text(
                'Continuar en progreso',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'start_extra'),
              child: const Text(
                'Iniciar esta rutina',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (choice == 'continue_assigned') {
        context.push('/today-workout');
      } else if (choice == 'start_extra') {
        context.push('/today-workout?workoutId=$workoutId');
      }
      // 'cancel' → no hace nada
    } else {
      context.push('/today-workout?workoutId=$workoutId');
    }
  }

  Future<void> _loadNextSchedule(String userId) async {
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);
    final next = await progressProvider.getNextScheduledWorkout(userId);
    if (mounted) setState(() => _nextSchedule = next);
  }

  /// Construye un tile de rutina con permisos correctos según el rol y dueño.
  Widget _buildWorkoutTile(
    BuildContext context, {
    required Workout workout,
    required bool isOfficial,
    required bool isAdmin,
    required String? currentUserId,
    required String? assignedWorkoutId,
    required WorkoutProvider workoutProvider,
    required WorkoutProgressProvider progressProvider,
  }) {
    final canManage = isAdmin || workout.createdBy == currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/workout-detail/${workout.id}'),
        borderRadius: BorderRadius.circular(16),
        child: _WorkoutCard(
          title: workout.name,
          duration: workout.duration,
          exerciseCount: workout.exerciseCount,
          level: workout.level,
          isOfficial: isOfficial,
          onEdit: canManage
              ? () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditWorkoutScreen(workout: workout),
                    ),
                  );
                  if (result == true && context.mounted) {
                    workoutProvider.loadWorkouts(
                      forceRefresh: true,
                      userId: currentUserId,
                      isAdmin: isAdmin,
                    );
                  }
                }
              : null,
          onDelete: canManage
              ? () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('¿Eliminar rutina?',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                        '¿Estás seguro de eliminar "${workout.name}"? Esta acción no se puede deshacer.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (shouldDelete == true && context.mounted) {
                    try {
                      await workoutProvider.deleteWorkout(workout.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rutina eliminada correctamente'),
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
                }
              : null,
          onPlay: workout.id != assignedWorkoutId
              ? () => _startExtraWorkout(context, workout.id, progressProvider)
              : null,
        ),
      ),
    );
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
          // Escuchar WorkoutProgressProvider para el flag en memoria
          final progressProvider =
              Provider.of<WorkoutProgressProvider>(context);
          final today = DateTime.now();
          // Verificar flag en memoria primero, luego sesiones de Supabase
          final todayCompleted = hasAssignedWorkout &&
              currentUser?.assignedWorkoutId != null &&
              (progressProvider.completedWorkoutIdToday ==
                      currentUser!.assignedWorkoutId ||
                  sessionProvider.sessions.any((s) {
                    final d = s.date.toLocal();
                    return s.workoutId == currentUser.assignedWorkoutId &&
                        d.year == today.year &&
                        d.month == today.month &&
                        d.day == today.day;
                  }));

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

              // Workout List — dividido en secciones por origen
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => workoutProvider.loadWorkouts(
                    forceRefresh: true,
                    userId: currentUser?.id,
                    isAdmin: isAdmin,
                  ),
                  color: AppColors.primary,
                  child: Builder(builder: (context) {
                    final officialWorkouts = workoutProvider.filteredWorkouts
                        .where((w) => w.createdBy == null)
                        .toList();
                    final userWorkouts = workoutProvider.filteredWorkouts
                        .where((w) => w.createdBy != null)
                        .toList();

                    if (officialWorkouts.isEmpty && userWorkouts.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No hay rutinas disponibles',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // ── Rutinas Oficiales ──
                        if (officialWorkouts.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'Rutinas Oficiales',
                            icon: Icons.verified_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          ...officialWorkouts.map(
                            (w) => _buildWorkoutTile(
                              context,
                              workout: w,
                              isOfficial: true,
                              isAdmin: isAdmin,
                              currentUserId: currentUser?.id,
                              assignedWorkoutId: currentUser?.assignedWorkoutId,
                              workoutProvider: workoutProvider,
                              progressProvider: progressProvider,
                            ),
                          ),
                        ],
                        // ── Mis Rutinas / Rutinas de Usuarios ──
                        if (userWorkouts.isNotEmpty) ...[
                          if (officialWorkouts.isNotEmpty)
                            const SizedBox(height: 8),
                          _SectionHeader(
                            label:
                                isAdmin ? 'Rutinas de Usuarios' : 'Mis Rutinas',
                            icon: isAdmin
                                ? Icons.people_alt_rounded
                                : Icons.star_rounded,
                            color: isAdmin
                                ? AppColors.textSecondary
                                : Colors.amber,
                          ),
                          const SizedBox(height: 12),
                          ...userWorkouts.map(
                            (w) => _buildWorkoutTile(
                              context,
                              workout: w,
                              isOfficial: false,
                              isAdmin: isAdmin,
                              currentUserId: currentUser?.id,
                              assignedWorkoutId: currentUser?.assignedWorkoutId,
                              workoutProvider: workoutProvider,
                              progressProvider: progressProvider,
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
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
  final bool isOfficial;
  final bool isClickable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    this.isOfficial = false,
    this.isClickable = false,
    this.onEdit,
    this.onDelete,
    this.onPlay,
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
                Row(
                  children: [
                    Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getLevelColor(),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOfficial) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.45),
                              width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 9, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text('OFICIAL',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                    ],
                  ],
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
          // Botón play para iniciar como rutina extra
          if (onPlay != null)
            GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header de sección para separar rutinas oficiales de las del usuario.
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
