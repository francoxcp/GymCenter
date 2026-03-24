import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'create_workout_screen.dart';
import 'edit_workout_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_l10n.dart';
import '../providers/workout_provider.dart';
import '../models/workout.dart';
import '../providers/workout_session_provider.dart';
import '../providers/workout_progress_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/filter_chip_button.dart';
import '../../../shared/widgets/assigned_workout_card.dart';
import '../../../shared/widgets/coming_soon_workout_card.dart';
import '../../../shared/widgets/app_snackbar.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final _searchController = TextEditingController();
  bool _searchHasText = false;
  Map<String, dynamic>? _nextSchedule;

  String _dayName(BuildContext context, int dayOfWeek) {
    final days = AppL10n.of(context).dayNamesFull;
    return days[(dayOfWeek - 1).clamp(0, 6)];
  }

  String _availableLabel(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (_nextSchedule == null) return l10n.availableTomorrow;
    final daysUntil = _nextSchedule!['days_until'] as int? ?? 1;
    if (daysUntil == 1) return l10n.availableTomorrow;
    final nextDay = _nextSchedule!['day_of_week'] as int?;
    if (nextDay != null) return l10n.availableOnDay(_dayName(context, nextDay));
    return l10n.availableInDays(daysUntil);
  }

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el campo de b�squeda
    _searchController.addListener(() {
      final hasText = _searchController.text.isNotEmpty;
      if (hasText != _searchHasText) setState(() => _searchHasText = hasText);
    });
    // Cargar rutinas y sesiones al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final sessionProvider =
          Provider.of<WorkoutSessionProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      workoutProvider.loadWorkouts(
        userId: authProvider.currentUser?.id,
        isAdmin: authProvider.isAdmin,
      );
      if (authProvider.currentUser?.id != null) {
        sessionProvider.loadSessions(authProvider.currentUser!.id,
            forceRefresh: true);
        progressProvider.loadProgress(authProvider.currentUser!.id);
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
          title: Text(
            AppL10n.of(ctx).workoutInProgressTitle,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppL10n.of(ctx).workoutInProgressBody,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(
                AppL10n.of(ctx).cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue_assigned'),
              child: Text(
                AppL10n.of(ctx).continueInProgress,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'start_extra'),
              child: Text(
                AppL10n.of(ctx).startThisWorkout,
                style: const TextStyle(color: Colors.white),
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
      // 'cancel' ? no hace nada
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

  /// Construye un tile de rutina con permisos correctos seg�n el rol y due�o.
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
                      title: Text(AppL10n.of(context).deleteWorkoutTitle,
                          style: const TextStyle(color: Colors.white)),
                      content: Text(
                        AppL10n.of(context).deleteWorkoutConfirm(workout.name),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppL10n.of(context).cancel,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(AppL10n.of(context).delete,
                              style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (shouldDelete == true && context.mounted) {
                    try {
                      await workoutProvider.deleteWorkout(workout.id);
                      if (context.mounted) {
                        AppSnackbar.success(
                            context, AppL10n.of(context).workoutDeletedOk);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.error(
                            context,
                            AppL10n.of(context)
                                .workoutDeleteError(e.toString()));
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
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appTitleUpper,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              l10n.workoutListTitle,
              style: const TextStyle(
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
          final l10n = AppL10n.of(context);
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
                  onChanged: (value) =>
                      Provider.of<WorkoutProvider>(context, listen: false)
                          .setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: AppL10n.of(context).searchWorkoutsHint,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchHasText
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<WorkoutProvider>(context,
                                      listen: false)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
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
                      label: l10n.filterAll,
                      isSelected: workoutProvider.selectedFilter == 'Todos',
                      onTap: () => workoutProvider.setFilter('Todos'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: l10n.beginner,
                      isSelected:
                          workoutProvider.selectedFilter == 'Principiante',
                      onTap: () => workoutProvider.setFilter('Principiante'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: l10n.intermediate,
                      isSelected:
                          workoutProvider.selectedFilter == 'Intermedio',
                      onTap: () => workoutProvider.setFilter('Intermedio'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: l10n.advanced,
                      isSelected: workoutProvider.selectedFilter == 'Avanzado',
                      onTap: () => workoutProvider.setFilter('Avanzado'),
                    ),
                  ],
                ),
              ),

              // Banner: rutina en pausa
              if (progressProvider.hasProgress) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PausedWorkoutBanner(
                    workoutName: workoutProvider
                            .getWorkoutById(
                                progressProvider.currentProgress!.workoutId)
                            ?.name ??
                        l10n.routineFallback,
                    exerciseIndex:
                        progressProvider.currentProgress!.exerciseIndex,
                    onContinue: () {
                      final pausedId =
                          progressProvider.currentProgress!.workoutId;
                      final isAssigned =
                          pausedId == currentUser?.assignedWorkoutId;
                      if (isAssigned) {
                        context.push('/today-workout');
                      } else {
                        context.push('/today-workout?workoutId=$pausedId');
                      }
                    },
                    onDiscard: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: Text(
                            l10n.endRoutineTitle,
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            l10n.endRoutineConfirm,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.endAction),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await Provider.of<WorkoutProgressProvider>(
                          context,
                          listen: false,
                        ).deleteProgress();
                      }
                    },
                  ),
                ),
              ],

              // Assigned Workout Hero Card (ocultar si ya se complet� hoy)
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
                // Rutina de hoy completada ? mostrar pr�xima en estilo "pr�ximamente"
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ComingSoonWorkoutCard(
                    workout: assignedWorkout,
                    availableLabel: _availableLabel(context),
                    compact: true,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.allRoutines,
                          style: const TextStyle(
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

              // Workout List � dividido en secciones por origen
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
                    // Usuarios normales ven solo sus propias rutinas.
                    // El admin ve todas las rutinas creadas por usuarios.
                    final userWorkouts = workoutProvider.filteredWorkouts
                        .where((w) =>
                            w.createdBy != null &&
                            (isAdmin || w.createdBy == currentUser?.id))
                        .toList();

                    if (officialWorkouts.isEmpty && userWorkouts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noRoutinesAvailable,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // -- Rutinas Oficiales --
                        if (officialWorkouts.isNotEmpty) ...[
                          _SectionHeader(
                            label: l10n.officialRoutines,
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
                        // -- Mis Rutinas / Rutinas de Usuarios --
                        if (userWorkouts.isNotEmpty) ...[
                          if (officialWorkouts.isNotEmpty)
                            const SizedBox(height: 8),
                          _SectionHeader(
                            label: isAdmin
                                ? l10n.userRoutinesLabel
                                : l10n.myRoutines,
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    this.isOfficial = false,
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
    final l10n = AppL10n.of(context);
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 9, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(l10n.officialBadge,
                                style: const TextStyle(
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
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.editLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.deleteLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          // Bot�n play para iniciar como rutina extra
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

class _PausedWorkoutBanner extends StatelessWidget {
  final String workoutName;
  final int exerciseIndex;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const _PausedWorkoutBanner({
    required this.workoutName,
    required this.exerciseIndex,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.22),
            AppColors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.routinePausedTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workoutName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l10n.exerciseNumber(exerciseIndex + 1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  child: Text(l10n.continueButton),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.primary.withOpacity(0.2),
          ),
          TextButton.icon(
            onPressed: onDiscard,
            icon: const Icon(Icons.stop_circle_outlined,
                size: 16, color: Colors.redAccent),
            label: Text(
              AppL10n.of(context).endRoutineTitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(double.infinity, 0),
              alignment: Alignment.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header de secci�n para separar rutinas oficiales de las del usuario.
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
