import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../models/workout.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../providers/workout_progress_provider.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final Workout workout;
  final int durationMinutes;
  final int caloriesBurned;
  final double totalVolume;

  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.totalVolume,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  Map<String, dynamic>? _nextWorkout;
  bool _isLoadingNextWorkout = true;
  String _motivationalMessage = '';

  // Mensajes motivacionales aleatorios
  final List<String> _motivationalMessages = [
    '¡INCREÍBLE TRABAJO!',
    '¡LO LOGRASTE!',
    '¡EXCELENTE!',
    '¡ERES IMPARABLE!',
    '¡BRUTAL ENTRENAMIENTO!',
    '¡SIGUE ASÍ CAMPEÓN!',
    '¡ESPECTACULAR!',
    '¡QUÉ MÁQUINA!',
  ];

  @override
  void initState() {
    super.initState();

    // Elegir mensaje motivacional aleatorio
    _motivationalMessage = _motivationalMessages[
        math.Random().nextInt(_motivationalMessages.length)];

    // Guardar sesión y actualizar estadísticas
    _saveWorkoutSession();

    // Cargar próxima sesión programada
    _loadNextWorkout();
  }

  Future<void> _saveWorkoutSession() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      // Guardar sesión en workout_sessions y actualizar estadísticas
      await progressProvider.completeWorkout(
        userId: userId,
        workoutId: widget.workout.id,
        durationMinutes: widget.durationMinutes,
        exercisesCompleted: widget.workout.exercises.length,
        totalExercises: widget.workout.exercises.length,
        caloriesBurned: widget.caloriesBurned,
        totalVolumeKg: widget.totalVolume,
      );

      // Actualizar estadísticas del usuario
      final currentUser = authProvider.currentUser!;
      await userProvider.updateUserStats(
        userId,
        completedWorkouts: currentUser.completedWorkouts + 1,
      );

      // Refrescar usuario para obtener estadísticas actualizadas
      await authProvider.refreshUser();

      debugPrint('✅ Sesión guardada y estadísticas actualizadas');
    } catch (e) {
      debugPrint('❌ Error al guardar sesión: $e');
    }
  }

  Future<void> _loadNextWorkout() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final progressProvider =
          Provider.of<WorkoutProgressProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        setState(() => _isLoadingNextWorkout = false);
        return;
      }

      final nextWorkoutData =
          await progressProvider.getNextScheduledWorkout(userId);

      setState(() {
        _nextWorkout = nextWorkoutData;
        _isLoadingNextWorkout = false;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar próxima sesión: $e');
      setState(() => _isLoadingNextWorkout = false);
    }
  }

  // Métodos auxiliares
  String _formatDuration(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatVolume(double volume) {
    return volume.toStringAsFixed(1);
  }

  int _estimateWeight(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('sentadilla') || name.contains('squat')) return 85;
    if (name.contains('press') || name.contains('banco')) return 85;
    if (name.contains('peso muerto') || name.contains('deadlift')) return 90;
    if (name.contains('remo')) return 110;
    if (name.contains('dominada') || name.contains('pull')) return 0;
    if (name.contains('burpee') || name.contains('jumping')) return 0;
    return 50;
  }

  Widget _buildNextWorkoutInfo() {
    if (_nextWorkout == null) return const SizedBox();
    final name = _nextWorkout?['name'] ?? 'Rutina';
    final date = _nextWorkout?['scheduled_at'] != null
        ? '${DateTime.parse(_nextWorkout!['scheduled_at']).day}/${DateTime.parse(_nextWorkout!['scheduled_at']).month}/${DateTime.parse(_nextWorkout!['scheduled_at']).year}'
        : 'Próximamente';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(date,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  String _getNextWorkoutMessage() {
    if (_nextWorkout == null) return '¡Prepárate para tu próxima sesión!';
    return '¡No olvides descansar y alimentarte bien antes de tu próxima rutina!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resumen de Entrenamiento'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con imagen de celebración
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background,
                      AppColors.background.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Botón cerrar
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    // Imagen de celebración (placeholder)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.cardBackground,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.celebration,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Mensaje motivador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      _motivationalMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Entrenamiento',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const Text(
                      'Completado!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Estadísticas en tarjetas amarillas
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.timer,
                            label: 'TIEMPO',
                            value: _formatDuration(widget.durationMinutes),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.local_fire_department,
                            label: 'CALORÍAS',
                            value: '${widget.caloriesBurned}',
                            unit: 'kcal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.fitness_center,
                            label: 'VOLUMEN',
                            value: _formatVolume(widget.totalVolume),
                            unit: 'kg',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Resumen de Ejercicios
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resumen de Ejercicios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            '${widget.workout.exercises.length} TOTAL',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Lista de ejercicios completados
                    ...widget.workout.exercises.map((exercise) {
                      // Calcular volumen aproximado
                      final estimatedWeight = _estimateWeight(exercise.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${exercise.sets} series × ${exercise.reps} reps',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$estimatedWeight kg',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Próxima Sesión Programada
                    if (!_isLoadingNextWorkout && _nextWorkout != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Próxima Sesión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNextWorkoutInfo(),
                            const SizedBox(height: 12),
                            Text(
                              _getNextWorkoutMessage(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Botón Volver al Inicio
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Volver al Inicio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.home, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget StatCard
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            if (unit != null)
              Text(unit!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
