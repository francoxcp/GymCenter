/// Motor de progresión inteligente (doble progresión).
///
/// A partir del historial de series de UN ejercicio decide qué peso conviene
/// usar hoy:
/// - **Subir**: en la última sesión se completaron todas las series con las
///   repeticiones objetivo usando el mismo peso → +5 lbs (tren superior) o
///   +10 lbs (tren inferior).
/// - **Mantener**: faltaron series o repeticiones → repetir el peso hasta
///   completarlas.
/// - **Descarga**: dos sesiones seguidas sin completar con el mismo peso →
///   bajar ~10 % para recuperar técnica y volver a progresar.
///
/// Internamente los pesos se guardan en kg y la app los muestra en lbs, por
/// eso los incrementos y redondeos se calculan en lbs.
library;

const double kKgToLbs = 2.20462;

/// Una serie registrada en `exercise_set_logs`.
class SetLog {
  final int setIndex;
  final double? weightKg;
  final int? reps;
  final int? targetReps;
  final bool completed;
  final DateTime loggedAt;
  final String exerciseName;

  const SetLog({
    required this.setIndex,
    required this.weightKg,
    required this.reps,
    required this.loggedAt,
    this.targetReps,
    this.completed = true,
    this.exerciseName = '',
  });

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
        setIndex: (json['set_index'] as num?)?.toInt() ?? 0,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        reps: (json['reps'] as num?)?.toInt(),
        targetReps: (json['target_reps'] as num?)?.toInt(),
        // Registros anteriores a esta versión no tenían la columna:
        // se asume completada.
        completed: json['completed'] as bool? ?? true,
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '')
                ?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        exerciseName: json['exercise_name'] as String? ?? '',
      );

  /// Estimación de 1RM (fórmula de Epley).
  double? get estimated1RmKg {
    final w = weightKg;
    final r = reps;
    if (w == null || w <= 0 || r == null || r <= 0) return null;
    if (r == 1) return w;
    return w * (1 + r / 30);
  }
}

/// Una sesión de un ejercicio (todas sus series de un mismo día).
class ExerciseSession {
  final DateTime date;
  final List<SetLog> sets;

  const ExerciseSession(this.date, this.sets);

  double? get topWeightKg {
    final ws = sets.map((s) => s.weightKg).whereType<double>();
    if (ws.isEmpty) return null;
    return ws.reduce((a, b) => a > b ? a : b);
  }

  double? get best1RmKg {
    final vs = sets.map((s) => s.estimated1RmKg).whereType<double>();
    if (vs.isEmpty) return null;
    return vs.reduce((a, b) => a > b ? a : b);
  }

  /// Volumen (kg × reps) de las series completadas.
  double get volumeKg => sets
      .where((s) => s.completed)
      .fold(0.0, (sum, s) => sum + (s.weightKg ?? 0) * (s.reps ?? 0));

  int get completedSets => sets.where((s) => s.completed).length;
}

enum ProgressionAction { increase, maintain, deload }

class ProgressionSuggestion {
  final ProgressionAction action;
  final double lastWeightKg;
  final double suggestedWeightKg;

  /// Series/reps de la última sesión, para mostrar "3×10".
  final int lastCompletedSets;
  final int lastTargetSets;
  final int targetReps;

  const ProgressionSuggestion({
    required this.action,
    required this.lastWeightKg,
    required this.suggestedWeightKg,
    required this.lastCompletedSets,
    required this.lastTargetSets,
    required this.targetReps,
  });

  double get lastWeightLbs => lastWeightKg * kKgToLbs;
  double get suggestedWeightLbs => suggestedWeightKg * kKgToLbs;
}

class ProgressionEngine {
  ProgressionEngine._();

  static const double upperBodyIncrementLbs = 5;
  static const double lowerBodyIncrementLbs = 10;
  static const double deloadFactor = 0.9;

  static const _lowerBodyGroups = [
    'pierna', 'piernas', 'cuádriceps', 'cuadriceps', 'glúteo', 'gluteo',
    'glúteos', 'gluteos', 'femoral', 'isquio', 'pantorrilla', 'gemelo',
    'aductor', 'abductor', 'legs', 'leg', 'quads', 'glutes', 'hamstring',
    'calves',
  ];
  static const _lowerBodyNames = [
    'sentadilla', 'squat', 'peso muerto', 'deadlift', 'prensa', 'leg press',
    'zancada', 'lunge', 'hip thrust', 'extensión de pierna', 'curl femoral',
    'búlgara', 'bulgara', 'gemelo', 'pantorrilla',
  ];

  /// ¿El ejercicio es de tren inferior? (decide el incremento de peso)
  static bool isLowerBody(String muscleGroup, String exerciseName) {
    final g = muscleGroup.toLowerCase();
    if (_lowerBodyGroups.any(g.contains)) return true;
    final n = exerciseName.toLowerCase();
    return _lowerBodyNames.any(n.contains);
  }

  /// Agrupa los registros en sesiones (una por día). Si el mismo día se
  /// guardó más de una vez (p. ej. guardado parcial y final), se queda con
  /// el registro más reciente de cada serie. Devuelve de más reciente a más
  /// antigua.
  static List<ExerciseSession> groupSessions(Iterable<SetLog> logs) {
    final byDay = <DateTime, Map<int, SetLog>>{};
    for (final log in logs) {
      final d = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      final sets = byDay.putIfAbsent(d, () => {});
      final prev = sets[log.setIndex];
      if (prev == null || log.loggedAt.isAfter(prev.loggedAt)) {
        sets[log.setIndex] = log;
      }
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days)
        ExerciseSession(
          d,
          byDay[d]!.values.toList()
            ..sort((a, b) => a.setIndex.compareTo(b.setIndex)),
        ),
    ];
  }

  /// Sugerencia para hoy, o `null` si no hay historial con peso.
  static ProgressionSuggestion? suggest({
    required Iterable<SetLog> logs,
    required int targetSets,
    required int targetReps,
    required bool lowerBody,
  }) {
    final sessions =
        groupSessions(logs).where((s) => s.topWeightKg != null).toList();
    if (sessions.isEmpty || targetSets <= 0) return null;

    final last = sessions.first;
    final lastWeight = last.topWeightKg!;
    if (lastWeight <= 0) return null;

    final lastOk = _isSuccessful(last, lastWeight, targetSets, targetReps);

    if (lastOk) {
      final inc = lowerBody ? lowerBodyIncrementLbs : upperBodyIncrementLbs;
      final nextLbs = roundLbs(lastWeight * kKgToLbs + inc);
      return ProgressionSuggestion(
        action: ProgressionAction.increase,
        lastWeightKg: lastWeight,
        suggestedWeightKg: nextLbs / kKgToLbs,
        lastCompletedSets: _setsMeetingTarget(last, lastWeight, targetReps),
        lastTargetSets: targetSets,
        targetReps: targetReps,
      );
    }

    // Dos sesiones seguidas sin completar con (aprox.) el mismo peso → descarga
    if (sessions.length >= 2) {
      final prev = sessions[1];
      final prevWeight = prev.topWeightKg!;
      final sameWeight = (prevWeight - lastWeight).abs() <= lastWeight * 0.02;
      if (sameWeight &&
          !_isSuccessful(prev, prevWeight, targetSets, targetReps)) {
        final deloadLbs = roundLbs(lastWeight * kKgToLbs * deloadFactor);
        return ProgressionSuggestion(
          action: ProgressionAction.deload,
          lastWeightKg: lastWeight,
          suggestedWeightKg: deloadLbs / kKgToLbs,
          lastCompletedSets: _setsMeetingTarget(last, lastWeight, targetReps),
          lastTargetSets: targetSets,
          targetReps: targetReps,
        );
      }
    }

    return ProgressionSuggestion(
      action: ProgressionAction.maintain,
      lastWeightKg: lastWeight,
      suggestedWeightKg: lastWeight,
      lastCompletedSets: _setsMeetingTarget(last, lastWeight, targetReps),
      lastTargetSets: targetSets,
      targetReps: targetReps,
    );
  }

  static int _setsMeetingTarget(
      ExerciseSession s, double weight, int targetReps) {
    return s.sets
        .where((set) =>
            set.completed &&
            (set.weightKg ?? 0) >= weight * 0.98 &&
            (set.reps ?? targetReps) >= targetReps)
        .length;
  }

  static bool _isSuccessful(
      ExerciseSession s, double weight, int targetSets, int targetReps) {
    return _setsMeetingTarget(s, weight, targetReps) >= targetSets;
  }

  /// Redondea a múltiplos de 2.5 lbs (discos más pequeños habituales).
  static double roundLbs(double lbs) => (lbs / 2.5).round() * 2.5;
}
