import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/supabase_config.dart';
import 'notification_service.dart';

/// Servicio que genera y envía reportes semanales de progreso del usuario.
///
/// Flujo:
///  1. Al arrancar la app (si progressReports == true), se llama a [checkAndSend].
///  2. Si han pasado ≥ 7 días desde el último reporte (o nunca se envió),
///     consulta Supabase con las sesiones de los últimos 7 días,
///     calcula las estadísticas y muestra una notificación local inmediata.
///  3. La fecha del último envío se guarda en SharedPreferences para no
///     repetir la notificación en cada apertura de la app.
class ProgressReportService {
  static final ProgressReportService _instance =
      ProgressReportService._internal();
  factory ProgressReportService() => _instance;
  ProgressReportService._internal();

  static const String _lastReportKey = 'last_progress_report_date';
  static const int _progressReportId = 50;
  static const int _minDaysBetweenReports = 7;

  /// Verifica si corresponde enviar el reporte y lo envía si es necesario.
  /// Llamar después de que el usuario esté autenticado.
  Future<void> checkAndSend({
    required String userId,
    required bool isEnglish,
  }) async {
    try {
      if (!await _shouldSendReport()) return;

      final stats = await _fetchWeeklyStats(userId);
      if (stats == null) return;

      await _sendNotification(stats: stats, isEnglish: isEnglish);
      await _saveReportDate();
    } catch (e) {
      debugPrint('[ProgressReportService] Error: $e');
    }
  }

  /// Envía el reporte inmediatamente (sin verificar fecha).
  /// Útil cuando el usuario activa la opción por primera vez.
  Future<void> sendNow({
    required String userId,
    required bool isEnglish,
  }) async {
    try {
      final stats = await _fetchWeeklyStats(userId);
      if (stats == null) return;
      await _sendNotification(stats: stats, isEnglish: isEnglish);
      await _saveReportDate();
    } catch (e) {
      debugPrint('[ProgressReportService] sendNow error: $e');
    }
  }

  // ─── Privados ────────────────────────────────────────────────────────────

  Future<bool> _shouldSendReport() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastReportKey);
    if (lastDateStr == null) return true;

    final lastDate = DateTime.tryParse(lastDateStr);
    if (lastDate == null) return true;

    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= _minDaysBetweenReports;
  }

  Future<void> _saveReportDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastReportKey, DateTime.now().toIso8601String());
  }

  /// Consulta Supabase por las sesiones de los últimos 7 días y calcula stats.
  Future<_WeeklyStats?> _fetchWeeklyStats(String userId) async {
    final since = DateTime.now().subtract(const Duration(days: 7));

    final response = await SupabaseConfig.client
        .from('workout_sessions')
        .select('duration_minutes, calories_burned, completed_at')
        .eq('user_id', userId)
        .gte('completed_at', since.toIso8601String());

    final rows = response as List;
    if (rows.isEmpty) return null;

    final totalWorkouts = rows.length;
    final totalMinutes = rows.fold<int>(
        0, (sum, r) => sum + ((r['duration_minutes'] as num?)?.toInt() ?? 0));
    final totalCalories = rows.fold<int>(
        0, (sum, r) => sum + ((r['calories_burned'] as num?)?.toInt() ?? 0));

    // Racha actual: días consecutivos con al menos una sesión
    final streak = await _computeStreak(userId);

    return _WeeklyStats(
      workouts: totalWorkouts,
      minutes: totalMinutes,
      calories: totalCalories,
      streak: streak,
    );
  }

  Future<int> _computeStreak(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('workout_sessions')
          .select('completed_at')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(30);

      final rows = response as List;
      if (rows.isEmpty) return 0;

      // Construir un set de fechas únicas (solo la parte Date)
      final Set<String> days = {};
      for (final r in rows) {
        final dt = DateTime.tryParse(r['completed_at'] as String? ?? '');
        if (dt != null) {
          days.add('${dt.year}-${dt.month}-${dt.day}');
        }
      }

      int streak = 0;
      var check = DateTime.now();
      while (true) {
        final key = '${check.year}-${check.month}-${check.day}';
        if (days.contains(key)) {
          streak++;
          check = check.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _sendNotification({
    required _WeeklyStats stats,
    required bool isEnglish,
  }) async {
    final hours = stats.minutes ~/ 60;
    final mins = stats.minutes % 60;
    final timeStr = hours > 0
        ? (isEnglish ? '${hours}h ${mins}m' : '${hours}h ${mins}min')
        : (isEnglish ? '${mins}m' : '${mins}min');

    final String title;
    final String body;

    if (isEnglish) {
      title = '📊 Your weekly progress report';
      final workoutWord = stats.workouts == 1 ? 'workout' : 'workouts';
      body = '${stats.workouts} $workoutWord · $timeStr · ${stats.calories} kcal'
          '${stats.streak > 1 ? ' · 🔥 ${stats.streak}-day streak' : ''}';
    } else {
      title = '📊 Tu reporte semanal de progreso';
      final workoutWord =
          stats.workouts == 1 ? 'entrenamiento' : 'entrenamientos';
      body =
          '${stats.workouts} $workoutWord · $timeStr · ${stats.calories} kcal'
          '${stats.streak > 1 ? ' · 🔥 ${stats.streak} días de racha' : ''}';
    }

    await NotificationService().showNotification(
      id: _progressReportId,
      title: title,
      body: body,
      payload: 'progress_report',
    );
  }
}

class _WeeklyStats {
  final int workouts;
  final int minutes;
  final int calories;
  final int streak;

  const _WeeklyStats({
    required this.workouts,
    required this.minutes,
    required this.calories,
    required this.streak,
  });
}
