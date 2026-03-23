import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../workouts/providers/workout_provider.dart';
import '../../workouts/providers/workout_progress_provider.dart';
import '../../workouts/providers/workout_session_provider.dart';
import '../../../shared/widgets/animated_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/coming_soon_workout_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      // Cargar rutinas para que estén disponibles
      workoutProvider.loadWorkouts(
        userId: userId,
        isAdmin: authProvider.isAdmin,
      );

      // Cargar progreso pendiente
      if (userId != null) {
        progressProvider.loadProgress(userId);

        // Cargar sesiones usando caché (5 min) al cambiar de tab.
        // Solo el pull-to-refresh obliga a re-descargar desde red.
        final sessionProvider =
            Provider.of<WorkoutSessionProvider>(context, listen: false);
        sessionProvider.loadSessions(userId);
      }
    });
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);

    final sessionProvider =
        Provider.of<WorkoutSessionProvider>(context, listen: false);

    await Future.wait<void>([
      authProvider.refreshUser().catchError((e) {
        debugPrint('Error refreshing user: $e');
      }),
      workoutProvider
          .loadWorkouts(
        forceRefresh: true,
        userId: authProvider.currentUser?.id,
        isAdmin: authProvider.isAdmin,
      )
          .catchError((e) {
        debugPrint('Error refreshing workouts: $e');
      }),
      if (authProvider.currentUser?.id != null)
        sessionProvider
            .loadSessions(
          authProvider.currentUser!.id,
          forceRefresh: true,
        )
            .catchError((e) {
          debugPrint('Error refreshing sessions: $e');
        }),
    ]);

    // Cargar progreso si hay usuario autenticado
    if (authProvider.currentUser != null) {
      await progressProvider.loadProgress(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: 200,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerCard(height: 120),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ShimmerCard(height: 120),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ShimmerCard(height: 180),
                SizedBox(height: 16),
                ShimmerListTile(),
                ShimmerListTile(),
                ShimmerListTile(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          strokeWidth: 3.0,
          displacement: 40,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Optimized spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CHAMOS FITNESS CENTER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '¡Hola, ${currentUser.name.split(' ')[0]}!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Banner modo offline
                Consumer<WorkoutProvider>(
                  builder: (context, wp, _) {
                    if (!wp.isOffline) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.orange, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sin conexión · Mostrando datos guardados',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Banner de progreso pendiente
                Consumer<WorkoutProgressProvider>(
                  builder: (context, progressProvider, _) {
                    final progress = progressProvider.currentProgress;
                    // No mostrar si no hay progreso, si es admin,
                    // o si ese workout ya fue completado hoy (evita race condition
                    // entre el delete en BD y la recarga de loadProgress),
                    // ni mientras loadProgress está cargando (evita flash residual)
                    if (!progressProvider.isLoading &&
                        progressProvider.hasProgress &&
                        progress != null &&
                        progressProvider.completedWorkoutIdToday !=
                            progress.workoutId) {
                      final workoutProvider =
                          Provider.of<WorkoutProvider>(context);
                      final workout =
                          workoutProvider.getWorkoutById(progress.workoutId);

                      if (workout != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PendingWorkoutBanner(
                            workoutName: workout.name,
                            progress: progress,
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                _UserHomeContent(currentUser: currentUser),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Contenido para el Usuario
class _UserHomeContent extends StatefulWidget {
  final User currentUser;

  const _UserHomeContent({required this.currentUser});

  @override
  State<_UserHomeContent> createState() => _UserHomeContentState();
}

class _UserHomeContentState extends State<_UserHomeContent> {
  Map<String, dynamic>? _nextSchedule;
  bool _isRestDay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNextWorkout();
    });
  }

  Future<void> _loadNextWorkout() async {
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    // Cargar próxima sesión y verificar si hoy es día de descanso en paralelo
    final results = await Future.wait([
      progressProvider.getNextScheduledWorkout(userId),
      progressProvider.isTodayScheduled(userId),
    ]);

    if (mounted) {
      setState(() {
        _nextSchedule = results[0] as Map<String, dynamic>?;
        _isRestDay = !(results[1] as bool);
      });
    }
  }

  bool _isTodayCompleted(WorkoutSessionProvider sessionProvider) {
    if (widget.currentUser.assignedWorkoutId == null) return false;
    final assignedId = widget.currentUser.assignedWorkoutId!;

    // 1️⃣ Primero revisar el flag en memoria (instantáneo, sin red)
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);
    if (progressProvider.completedWorkoutIdToday == assignedId) return true;

    // 2️⃣ Verificar las sesiones cargadas de Supabase
    final today = DateTime.now();
    return sessionProvider.sessions.any((s) {
      final localDate = s.date.toLocal();
      return s.workoutId == assignedId &&
          localDate.year == today.year &&
          localDate.month == today.month &&
          localDate.day == today.day;
    });
  }

  String _dayName(int dayOfWeek) {
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
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final sessionProvider = Provider.of<WorkoutSessionProvider>(context);
    // Escuchar también WorkoutProgressProvider para capturar el flag en memoria
    Provider.of<WorkoutProgressProvider>(context); // listen:true para rebuild
    final hasAssignedWorkout = widget.currentUser.assignedWorkoutId != null;
    final assignedWorkout = hasAssignedWorkout
        ? workoutProvider.getWorkoutById(widget.currentUser.assignedWorkoutId!)
        : null;
    final todayCompleted = _isTodayCompleted(sessionProvider);

    // Calcular stats reales desde sesiones cargadas (más precisos que los campos BD)
    final realSessions = sessionProvider.sessions;
    final realCompletedCount = realSessions.isNotEmpty
        ? realSessions.length
        : widget.currentUser.completedWorkouts;
    final realActiveDays = realSessions.isNotEmpty
        ? realSessions
            .map((s) {
              final d = s.date.toLocal();
              return DateTime(d.year, d.month, d.day);
            })
            .toSet()
            .length
        : widget.currentUser.activeDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Stats - Optimized spacing and added animations
        Row(
          children: [
            Expanded(
              child: FadeInCard(
                delay: 0,
                child: AnimatedCard(
                  padding: const EdgeInsets.all(14),
                  onTap: null,
                  enableAnimation: false,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event_available,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$realActiveDays',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Días activos',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInCard(
                delay: 100,
                child: AnimatedCard(
                  padding: const EdgeInsets.all(14),
                  onTap: null,
                  enableAnimation: false,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$realCompletedCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Sesiones',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Today's Workout
        Text(
          todayCompleted
              ? 'Próxima rutina'
              : _isRestDay
                  ? 'Descanso programado'
                  : 'Tu rutina asignada',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        // Mostrar loading si está cargando
        if (workoutProvider.isLoading) ...[
          FadeInCard(
            delay: 200,
            child: AnimatedCard(
              padding: const EdgeInsets.all(20),
              onTap: null,
              enableAnimation: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                padding: const EdgeInsets.all(40),
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando rutinas...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else if (hasAssignedWorkout &&
            assignedWorkout != null &&
            !todayCompleted &&
            _isRestDay) ...[
          // Día de descanso
          FadeInCard(
            delay: 200,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bedtime_outlined,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Día de descanso! 💤',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nextSchedule != null
                        ? 'Descansa y recupera músculos.\nTu próxima sesión es el ${_dayName(_nextSchedule!["day_of_week"] as int)}.'
                        : 'Hoy no tienes entrenamiento programado.\nDescansa y recupera músculos.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else if (hasAssignedWorkout &&
            assignedWorkout != null &&
            todayCompleted) ...[
          // Workout de hoy completado → mostrar próxima rutina en estilo "próximamente"
          ComingSoonWorkoutCard(
            workout: assignedWorkout,
            availableLabel: _availableLabel,
          ),
        ] else if (hasAssignedWorkout && assignedWorkout != null) ...[
          FadeInCard(
            delay: 200,
            child: AnimatedCard(
              padding: const EdgeInsets.all(18),
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/today-workout');
              },
              enableShadow: true,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFE6C200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignedWorkout.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.timer,
                            size: 18, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          '${assignedWorkout.duration} min',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.fitness_center,
                            size: 18, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          '${assignedWorkout.exerciseCount} ejercicios',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.push('/today-workout');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'ENTRENAR AHORA',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (hasAssignedWorkout && assignedWorkout == null) ...[
          // Tiene rutina asignada pero no se encontró
          FadeInCard(
            delay: 200,
            child: AnimatedCard(
              padding: const EdgeInsets.all(20),
              onTap: null,
              enableAnimation: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 56,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rutina no encontrada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La rutina asignada (ID: ${widget.currentUser.assignedWorkoutId}) no está disponible.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Sin rutina asignada
          FadeInCard(
            delay: 200,
            child: AnimatedCard(
              padding: const EdgeInsets.all(20),
              onTap: null,
              enableAnimation: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surface),
                ),
                padding: const EdgeInsets.all(20),
                child: const Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 56,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No tienes rutina asignada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tu entrenador te asignará una rutina pronto',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Quick Actions
        const Text(
          'Explorar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: FadeInCard(
                delay: 300,
                child: _QuickActionCard(
                  title: 'Rutinas',
                  icon: Icons.fitness_center,
                  onTap: () => context.push('/workouts'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FadeInCard(
                delay: 400,
                child: _QuickActionCard(
                  title: 'Planes',
                  icon: Icons.restaurant_menu,
                  onTap: () => context.push('/meal-plans'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Banner de Workout Pendiente
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      enableAnimation: true,
      enableShadow: false,
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingWorkoutBanner extends StatelessWidget {
  final String workoutName;
  final dynamic progress;

  const _PendingWorkoutBanner({
    required this.workoutName,
    required this.progress,
  });

  String _getTimeAgoText(Duration duration) {
    if (duration.inMinutes < 60) {
      return 'hace ${duration.inMinutes} min';
    } else if (duration.inHours < 24) {
      return 'hace ${duration.inHours}h';
    } else {
      return 'hace ${duration.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = progress.progressPercentage.toInt();
    final timeAgo = _getTimeAgoText(progress.timeSinceUpdate);

    return AnimatedCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/today-workout');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.7),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.black,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notification_important,
                        size: 16,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RUTINA EN PROGRESO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workoutName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$progressPercent% completado',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        ' • $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
