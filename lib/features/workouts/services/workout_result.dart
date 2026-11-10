import '../models/exercise.dart';
import '../models/superset.dart';
import 'calorie_estimator.dart';

/// Mejor serie del entreno (la de más peso; a igual peso, más reps).
class BestSet {
  final String exercise;
  final double weightKg;
  final int reps;
  const BestSet(this.exercise, this.weightKg, this.reps);
}

/// Resultado de una rutina terminada, calculado con lo que se hizo de verdad.
class WorkoutResult {
  final int durationSeconds;
  final int setsDone;
  final int exercisesDone;
  final int supersets;
  /// Grupos funcionales (circuitos) del entreno.
  final int functionals;
  /// Peso × repeticiones reales, solo series hechas con peso anotado
  /// (o el peso indicado por el entrenador). Sin pesos inventados.
  final double volumeKg;
  final int repsDone;
  final BestSet? bestSet;
  final double met;
  final int calories;

  const WorkoutResult({
    required this.durationSeconds,
    required this.setsDone,
    required this.exercisesDone,
    required this.supersets,
    this.functionals = 0,
    required this.volumeKg,
    required this.repsDone,
    required this.bestSet,
    required this.met,
    required this.calories,
  });

  /// Minutos redondeados; un entreno de segundos cuenta como 1 minuto.
  int get durationMinutes => durationSeconds <= 0
      ? 0
      : (durationSeconds / 60).round().clamp(1, 1 << 30);

  /// "52:18" o "1:05:09".
  static String clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  static WorkoutResult compute({
    required List<Exercise> exercises,
    required List<List<bool>> completed,
    required Map<int, Map<int, double?>> weightsKg,
    required Map<int, Map<int, int>> reps,
    required int durationSeconds,
    required bool Function(Exercise) isCardio,
    double? bodyWeightKg,
    double? heightCm,
    int? age,
    String? sex,
  }) {
    var sets = 0, totalReps = 0, exDone = 0;
    var volume = 0.0;
    BestSet? best;
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      final done = i < completed.length ? completed[i] : const <bool>[];
      var any = false;
      for (var j = 0; j < done.length; j++) {
        if (!done[j]) continue;
        any = true;
        sets++;
        // Por tiempo no suma repeticiones (ni volumen sin peso)
        final r = e.isTimed ? 0 : (reps[i]?[j] ?? e.reps);
        totalReps += r;
        // Peso anotado; si no, el que indicó el entrenador (lbs → kg)
        final w = weightsKg[i]?[j] ?? (e.weight > 0 ? e.weight / 2.20462 : 0.0);
        if (w > 0 && !e.isTimed) {
          volume += w * r;
          if (best == null ||
              w > best.weightKg ||
              (w == best.weightKg && r > best.reps)) {
            best = BestSet(e.name, w, r);
          }
        }
      }
      if (any) exDone++;
    }

    var supersets = 0, functionals = 0, inSuperset = 0;
    var cardioWeight = 0.0;
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      final span = supersetSpanAt(exercises, i);
      if (span != null) {
        inSuperset++;
        if (span.start == i) {
          if (groupKindAt(exercises, i) == kGroupFunctional) {
            functionals++;
          } else {
            supersets++;
          }
        }
      }
      // Cardio cuenta entero; un ejercicio de circuito funcional, medio
      // (Compendio: entrenamiento en circuito, más intenso que pesas)
      if (isCardio(e)) {
        cardioWeight += 1;
      } else if (span != null && groupKindAt(exercises, i) == kGroupFunctional) {
        cardioWeight += 0.5;
      }
    }
    final minutes = durationSeconds / 60;
    final met = CalorieEstimator.metForSession(
      setsDone: sets,
      minutes: minutes,
      cardioRatio: exercises.isEmpty ? 0 : cardioWeight / exercises.length,
      supersetRatio: exercises.isEmpty ? 0 : inSuperset / exercises.length,
    );
    return WorkoutResult(
      durationSeconds: durationSeconds,
      setsDone: sets,
      exercisesDone: exDone,
      supersets: supersets,
      functionals: functionals,
      volumeKg: volume,
      repsDone: totalReps,
      bestSet: best,
      met: met,
      calories: CalorieEstimator.estimateSession(
        seconds: durationSeconds,
        met: met,
        weightKg: bodyWeightKg,
        heightCm: heightCm,
        age: age,
        sex: sex,
      ),
    );
  }
}
