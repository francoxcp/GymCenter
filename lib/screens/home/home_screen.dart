import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/workout_progress_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar progreso pendiente al iniciar
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        progressProvider.loadProgress(authProvider.currentUser!.id);
      }
    });
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);
    final progressProvider =
        Provider.of<WorkoutProgressProvider>(context, listen: false);

    await Future.wait([
      authProvider.refreshUser(),
      workoutProvider.loadWorkouts(forceRefresh: true),
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
    final isAdmin = authProvider.isAdmin;

    if (currentUser == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(
                  width: 200,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerCard(height: 120),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShimmerCard(height: 120),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const ShimmerCard(height: 180),
                const SizedBox(height: 16),
                const ShimmerListTile(),
                const ShimmerListTile(),
                const ShimmerListTile(),
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
          child: SingleChildScrollView(
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
                            isAdmin
                                ? '¡Hola, Entrenador!'
                                : '¡Hola, ${currentUser.name.split(' ')[0]}!',
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/profile');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            currentUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Banner de progreso pendiente
                Consumer<WorkoutProgressProvider>(
                  builder: (context, progressProvider, _) {
                    if (!isAdmin && progressProvider.hasProgress) {
                      final progress = progressProvider.currentProgress!;
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

                // Contenido diferente según el rol
                if (isAdmin)
                  _AdminHomeContent()
                else
                  _UserHomeContent(currentUser: currentUser),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Contenido para el Admin (Entrenador)
class _AdminHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Panel de Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats - Using fade-in animation
        Row(
          children: [
            Expanded(
              child: FadeInCard(
                delay: 0,
                child: _StatCard(
                  icon: Icons.people,
                  title: 'USUARIOS',
                  value: '24',
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FadeInCard(
                delay: 100,
                child: _StatCard(
                  icon: Icons.fitness_center,
                  title: 'RUTINAS',
                  value: '12',
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 16),

        FadeInCard(
          delay: 200,
          child: _QuickActionCard(
            title: 'Gestionar Rutinas',
            subtitle: 'Crear, editar y asignar rutinas',
            icon: Icons.fitness_center,
            onTap: () => context.push('/workouts'),
          ),
        ),

        const SizedBox(height: 12),

        FadeInCard(
          delay: 300,
          child: _QuickActionCard(
            title: 'Gestionar Planes Alimenticios',
            subtitle: 'Crear y asignar dietas',
            icon: Icons.restaurant_menu,
            onTap: () => context.push('/meal-plans'),
          ),
        ),

        const SizedBox(height: 12),

        FadeInCard(
          delay: 400,
          child: _QuickActionCard(
            title: 'Panel de Administración',
            subtitle: 'Ver estadísticas y usuarios',
            icon: Icons.dashboard,
            onTap: () => context.push('/admin'),
          ),
        ),
      ],
    );
  }
}

// Contenido para el Usuario
class _UserHomeContent extends StatelessWidget {
  final User currentUser;

  const _UserHomeContent({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final hasAssignedWorkout = currentUser.assignedWorkoutId != null;
    final assignedWorkout = hasAssignedWorkout
        ? workoutProvider.getWorkoutById(currentUser.assignedWorkoutId!)
        : null;

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
                        '${currentUser.activeDays}',
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
                        '${currentUser.completedWorkouts}',
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
        const Text(
          'Tu Rutina Asignada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 16),

        if (hasAssignedWorkout && assignedWorkout != null) ...[
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
                          '${assignedWorkout.exercises.length} ejercicios',
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
        ] else ...[
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

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      onTap: null,
      enableAnimation: false,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: double.tryParse(value) ?? 0.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, animatedValue, child) {
              return Text(
                animatedValue.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: subtitle != null
          ? const EdgeInsets.all(18)
          : const EdgeInsets.all(20),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      enableAnimation: true,
      enableShadow: false,
      child: subtitle != null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            )
          : Column(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: AppColors.primary,
                ),
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

// Banner de Workout Pendiente
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
