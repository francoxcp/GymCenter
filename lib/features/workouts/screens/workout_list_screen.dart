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
    // Escuchar cambios en el campo de búsqueda
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
      // Resetear búsqueda: el texto del campo se pierde al navegar;
      // sin esto, el provider filtraría invisiblemente con la query anterior.
      workoutProvider.setSearchQuery('');
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
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            AppL10n.of(ctx).workoutInProgressBody,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(
                AppL10n.of(ctx).cancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'continue_assigned'),
              child: Text(
                AppL10n.of(ctx).continueInProgress,
                style: TextStyle(color: AppColors.primaryText),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'start_extra'),
              child: Text(
                AppL10n.of(ctx).startThisWorkout,
                style: TextStyle(color: AppColors.textPrimary),
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
          isOfficial: isOfficial,
          onEdit: canManage
              ? () async {
                  // Cargar ejercicios primero: el workout de la lista tiene
                  // exercises:[] porque se cargan de forma perezosa.
                  // Sin esto, updateWorkout borraría todos los ejercicios.
                  await workoutProvider.ensureExercisesLoaded(workout.id);
                  if (!context.mounted) return;
                  final freshWorkout =
                      workoutProvider.getWorkoutById(workout.id) ?? workout;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditWorkoutScreen(workout: freshWorkout),
                    ),
                  );
                  // updateWorkout actualiza memoria directamente, no es necesario
                  // llamar loadWorkouts aquí.
                }
              : null,
          onDelete: canManage
              ? () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(AppL10n.of(context).deleteWorkoutTitle,
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: Text(
                        AppL10n.of(context).deleteWorkoutConfirm(workout.name),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppL10n.of(context).cancel,
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(AppL10n.of(context).delete,
                              style: TextStyle(color: Colors.redAccent)),
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
        !authProvider.isStaff && currentUser?.assignedWorkoutId != null;
    final l10n = AppL10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appTitleUpper,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              l10n.workoutListTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
            child: Icon(
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
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchHasText
                        ? IconButton(
                            icon: Icon(
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
                    for (final c in workoutProvider.categoriesInUse) ...[
                      const SizedBox(width: 8),
                      FilterChipButton(
                        label: c,
                        isSelected: workoutProvider.selectedFilter == c,
                        onTap: () => workoutProvider.setFilter(c),
                      ),
                    ],
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
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          content: Text(
                            l10n.endRoutineConfirm,
                            style:
                                TextStyle(color: AppColors.textSecondary),
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
                                foregroundColor: AppColors.textPrimary,
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
                // Rutina de hoy completada ? mostrar próxima en estilo "próximamente"
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
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.allRoutines,
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
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
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
                  color: AppColors.primaryText,
                  child: Builder(builder: (context) {
                    // La base de datos ya filtra qué rutinas puede ver cada
                    // rol (RLS). Aquí solo se separan en dos secciones:
                    // - Dueño: arriba la biblioteca del gimnasio (las suyas
                    //   y las antiguas), abajo las de entrenadores y socios.
                    // - Entrenador/socio: arriba las del gimnasio y de su
                    //   entrenador, abajo "Mis rutinas".
                    final me = currentUser?.id;
                    bool isOfficial(Workout w) => isAdmin
                        ? (w.createdBy == null || w.createdBy == me)
                        : w.createdBy != me;
                    final officialWorkouts = workoutProvider.filteredWorkouts
                        .where(isOfficial)
                        .toList();
                    final userWorkouts = workoutProvider.filteredWorkouts
                        .where((w) => !isOfficial(w))
                        .toList();

                    if (officialWorkouts.isEmpty && userWorkouts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noRoutinesAvailable,
                            style:
                                TextStyle(color: AppColors.textSecondary),
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
                            color: AppColors.primaryText,
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

          await navigator.push(
            MaterialPageRoute(
              builder: (context) => const CreateWorkoutScreen(),
            ),
          );
          // addWorkout ya actualiza _workouts en memoria y llama notifyListeners.
          // No es necesario un loadWorkouts adicional aquí.
        },
        backgroundColor: AppColors.primary,
        child: Icon(
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
  final bool isOfficial;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPlay;

  const _WorkoutCard({
    required this.title,
    required this.duration,
    required this.exerciseCount,
    this.isOfficial = false,
    this.onEdit,
    this.onDelete,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center,
              color: AppColors.primaryText,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Duración y ejercicios van una sola vez (en la fila de abajo)
                if (isOfficial) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: AppColors.primaryText.withValues(alpha: 0.45),
                              width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 9, color: AppColors.primaryText),
                            const SizedBox(width: 3),
                            Text(l10n.officialBadge,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$duration min',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$exerciseCount ejercicios',
                      style: TextStyle(
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
              icon: Icon(
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
                      Icon(Icons.edit,
                          color: AppColors.primaryText, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.editLabel,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        l10n.deleteLabel,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Icon(
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryText.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primaryText,
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
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.45),
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
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.primaryText,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workoutName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.exerciseNumber(exerciseIndex + 1),
                        style: TextStyle(
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
            color: AppColors.primaryText.withValues(alpha: 0.2),
          ),
          TextButton.icon(
            onPressed: onDiscard,
            icon: Icon(Icons.stop_circle_outlined,
                size: 16, color: Colors.redAccent),
            label: Text(
              AppL10n.of(context).endRoutineTitle,
              style: TextStyle(
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
              color: color.withValues(alpha: 0.15),
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
              color: color.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
