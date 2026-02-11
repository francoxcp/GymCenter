import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_goals_provider.dart';
import '../../models/workout.dart';

class CompleteWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final int durationMinutes;

  const CompleteWorkoutScreen({
    super.key,
    required this.workout,
    required this.durationMinutes,
  });

  @override
  State<CompleteWorkoutScreen> createState() => _CompleteWorkoutScreenState();
}

class _CompleteWorkoutScreenState extends State<CompleteWorkoutScreen> {
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Calcular calorías estimadas automáticamente (5 cal/min)
    final estimatedCalories = widget.durationMinutes * 5;
    _caloriesController.text = estimatedCalories.toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeWorkout() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final calories = int.tryParse(_caloriesController.text) ?? 0;

      // Guardar sesión en la base de datos
      await SupabaseConfig.client.from('workout_sessions').insert({
        'user_id': userId,
        'workout_id': widget.workout.id,
        'completed_at': DateTime.now().toIso8601String(),
        'duration_minutes': widget.durationMinutes,
        'calories_burned': calories,
        'notes': _notesController.text.trim(),
      });

      // Recalcular metas automáticamente
      final goalsProvider =
          Provider.of<UserGoalsProvider>(context, listen: false);
      await goalsProvider.recalculateAllGoals(userId);

      if (mounted) {
        Navigator.pop(context, true); // Retornar true indicando éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Entrenamiento completado! 💪'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al completar entrenamiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Completar Entrenamiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono de éxito
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Título
            const Text(
              '¡Sesión Completada!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Info del entrenamiento
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.fitness_center,
                    'Rutina',
                    widget.workout.name,
                  ),
                  const Divider(height: 24, color: AppColors.surface),
                  _buildInfoRow(
                    Icons.access_time,
                    'Duración',
                    '${widget.durationMinutes} min',
                  ),
                  const Divider(height: 24, color: AppColors.surface),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Fecha',
                    _formatDate(DateTime.now()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Campo de calorías
            const Text(
              'Calorías Quemadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si tienes reloj inteligente, agrega el valor aquí. Sino, usamos ${widget.durationMinutes * 5} kcal estimadas.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                suffixText: 'kcal',
                suffixStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notas opcionales
            const Text(
              'Notas (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: Me sentí con mucha energía, aumenté peso...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _completeWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Guardar y Finalizar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
