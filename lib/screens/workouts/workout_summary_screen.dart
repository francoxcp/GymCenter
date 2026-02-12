import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../models/workout.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/rating_dialog.dart';

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
  bool _hasShownRatingDialog = false;

  @override
  void initState() {
    super.initState();
    // Mostrar rating dialog después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasShownRatingDialog) {
        _showRatingDialog();
      }
    });
  }

  Future<void> _showRatingDialog() async {
    if (_hasShownRatingDialog) return;

    setState(() => _hasShownRatingDialog = true);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        title: '¿Cómo te fue?',
        subtitle: 'Califica tu entrenamiento de ${widget.workout.name}',
        onSubmit: (rating, comment) async {
          await _saveRating(rating, comment);
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu feedback! 💪'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveRating(int rating, String? comment) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Buscar la última sesión de workout de este usuario para este workout
      final sessionResponse = await SupabaseConfig.client
          .from('workout_sessions')
          .select('id')
          .eq('user_id', userId)
          .eq('workout_id', widget.workout.id)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final sessionId = sessionResponse?['id'];

      // Guardar rating
      await SupabaseConfig.client.from('workout_ratings').insert({
        'user_id': userId,
        'workout_id': widget.workout.id,
        'session_id': sessionId,
        'rating': rating,
        'comment': comment,
      });

      debugPrint('✅ Rating guardado: $rating estrellas');
    } catch (e) {
      debugPrint('❌ Error al guardar rating: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    const Text(
                      '¡INCREÍBLE TRABAJO!',
                      style: TextStyle(
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
                          child: _StatCard(
                            icon: Icons.timer,
                            label: 'TIEMPO',
                            value: _formatDuration(widget.durationMinutes),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department,
                            label: 'CALORÍAS',
                            value: '${widget.caloriesBurned}',
                            unit: 'kcal',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
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

                    // Botón Calificar Entrenamiento
                    if (!_hasShownRatingDialog)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.star, color: Colors.black),
                          label: const Text(
                            'Calificar Entrenamiento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    if (!_hasShownRatingDialog) const SizedBox(height: 16),

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

                    const SizedBox(height: 16),

                    // Botón Compartir Progreso
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _shareWorkout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                              color: AppColors.primary, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Compartir Progreso',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
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

  String _formatDuration(int minutes) {
    final mins = minutes % 60;
    final secs = (minutes * 60) % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}k';
    }
    return volume.toStringAsFixed(0);
  }

  int _estimateWeight(String exerciseName) {
    // Estimación de peso basada en el tipo de ejercicio
    final name = exerciseName.toLowerCase();
    if (name.contains('sentadilla') || name.contains('squat')) return 85;
    if (name.contains('press') || name.contains('banco')) return 85;
    if (name.contains('peso muerto') || name.contains('deadlift')) return 90;
    if (name.contains('remo')) return 110;
    if (name.contains('dominada') || name.contains('pull')) return 0;
    if (name.contains('burpee') || name.contains('jumping')) return 0;
    return 50; // peso por defecto
  }

  void _shareWorkout(BuildContext context) {
    final shareText = '''
🏋️ ¡Entrenamiento Completado en Chamos Fitness Center! 💪

📋 Rutina: ${widget.workout.name}
⏱️ Duración: ${widget.durationMinutes} minutos
🔥 Calorías: ${widget.caloriesBurned} kcal
💪 Volumen Total: ${widget.totalVolume.toStringAsFixed(1)} kg

${widget.workout.description}

#ChamosFitnessCenter #Fitness #Workout #Training
    '''
        .trim();

    Share.share(
      shareText,
      subject: '¡Completé mi entrenamiento! 💪',
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.black87,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(height: 2),
            Text(
              unit!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
