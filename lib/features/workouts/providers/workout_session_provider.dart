import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../../../config/supabase_config.dart';

class WorkoutSessionProvider extends ChangeNotifier {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = false;
  DateTime? _lastFetch;

  List<WorkoutSession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  // Cache por 5 minutos
  bool get _shouldRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!).inMinutes > 5;
  }

  /// Carga las sesiones de entrenamiento del usuario actual
  Future<void> loadSessions(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldRefresh && _sessions.isNotEmpty) {
      return; // Usar caché
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('workout_sessions')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      _sessions = (response as List).map((json) {
        return WorkoutSession.fromJson({
          'id': json['id'],
          'userId': json['user_id'],
          'workoutId': json['workout_id'],
          'date': json['completed_at'],
          'durationMinutes': json['duration_minutes'],
          'caloriesBurned': json['calories_burned'] ?? 0,
          'totalVolumeKg': (json['total_volume_kg'] ?? 0).toDouble(),
          'exercisesCompleted': (json['exercises_completed'] is List)
              ? json['exercises_completed']
              : [],
          'isCompleted': true,
        });
      }).toList();

      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading workout sessions: $e');
    }
  }

  /// Guarda una nueva sesión de entrenamiento
  Future<void> saveSession(WorkoutSession session) async {
    try {
      await SupabaseConfig.client.from('workout_sessions').insert({
        'user_id': session.userId,
        'workout_id': session.workoutId,
        'duration_minutes': session.durationMinutes,
        'exercises_completed': session.exercisesCompleted
            .map((e) => {
                  'exerciseId': e.exerciseId,
                  'setsCompleted': e.setsCompleted,
                  'notes': e.notes,
                })
            .toList(),
        'completed_at': session.date.toIso8601String(),
      });

      await loadSessions(session.userId, forceRefresh: true);
    } catch (e) {
      debugPrint('Error saving workout session: $e');
      rethrow;
    }
  }

  /// Obtiene las sesiones de un mes específico (para calendario)
  List<WorkoutSession> getSessionsForMonth(int year, int month) {
    return _sessions.where((session) {
      return session.date.year == year && session.date.month == month;
    }).toList();
  }

  /// Obtiene las sesiones de un día específico
  List<WorkoutSession> getSessionsForDay(DateTime day) {
    return _sessions.where((session) {
      return session.date.year == day.year &&
          session.date.month == day.month &&
          session.date.day == day.day;
    }).toList();
  }

  /// Obtiene estadísticas del usuario
  Map<String, dynamic> getStats() {
    if (_sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'averageDuration': 0,
        'completionRate': 0.0,
      };
    }

    final totalSessions = _sessions.length;
    final totalMinutes = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final completedSessions = _sessions.where((s) => s.isCompleted).length;

    return {
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'averageDuration': totalMinutes ~/ totalSessions,
      'completionRate': (completedSessions / totalSessions * 100).round(),
    };
  }

  /// Obtiene la racha actual de entrenamientos consecutivos
  int getCurrentStreak() {
    if (_sessions.isEmpty) return 0;

    final sortedSessions = List<WorkoutSession>.from(_sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDay; // solo fecha (sin hora)

    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);
    // DateTime con day-1 es correcto: Dart normaliza automáticamente cambios de mes
    final yesterdayDay = DateTime(now.year, now.month, now.day - 1);

    for (var session in sortedSessions) {
      final sessionDay =
          DateTime(session.date.year, session.date.month, session.date.day);

      if (lastDay == null) {
        // Primera sesión: debe ser hoy o ayer para iniciar racha
        if (sessionDay == todayDay || sessionDay == yesterdayDay) {
          streak = 1;
          lastDay = sessionDay;
        } else {
          break; // Racha rota
        }
      } else {
        // Sesión siguiente: debe ser exactamente el día anterior a lastDay
        final expectedDay =
            DateTime(lastDay.year, lastDay.month, lastDay.day - 1);
        if (sessionDay == expectedDay) {
          streak++;
          lastDay = sessionDay;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
