/// Reglas para dar por terminada una rutina.
///
/// Un socio solo puede finalizar cuando TODAS las series de TODOS los
/// ejercicios están marcadas como hechas y cada una tiene el peso usado
/// registrado. Los ejercicios de cardio no piden peso; para ejercicios con
/// peso corporal se registra 0 ("Peso corporal").
class PendingExercise {
  final int index;
  final String name;

  /// Series (base 1) que aún no se marcaron como hechas.
  final List<int> unfinishedSets;

  /// Series (base 1) hechas pero sin peso registrado.
  final List<int> setsWithoutWeight;

  const PendingExercise({
    required this.index,
    required this.name,
    required this.unfinishedSets,
    required this.setsWithoutWeight,
  });

  int get missingCount => unfinishedSets.length + setsWithoutWeight.length;
}

class WorkoutCompletion {
  WorkoutCompletion._();

  /// Devuelve los ejercicios con algo pendiente. Lista vacía = puede terminar.
  ///
  /// [completed] es la matriz ejercicio × serie de series hechas.
  /// [weights] es ejercicio → serie → peso (kg); `0` = peso corporal.
  /// [weightRequired] indica por ejercicio si hace falta anotar peso.
  static List<PendingExercise> pending({
    required List<String> names,
    required List<List<bool>> completed,
    required Map<int, Map<int, double?>> weights,
    required List<bool> weightRequired,
  }) {
    final result = <PendingExercise>[];
    for (var i = 0; i < names.length; i++) {
      final sets = i < completed.length ? completed[i] : const <bool>[];
      final needsWeight = i < weightRequired.length ? weightRequired[i] : true;
      final unfinished = <int>[];
      final noWeight = <int>[];
      for (var j = 0; j < sets.length; j++) {
        if (!sets[j]) {
          unfinished.add(j + 1);
        } else if (needsWeight && weights[i]?[j] == null) {
          noWeight.add(j + 1);
        }
      }
      if (unfinished.isNotEmpty || noWeight.isNotEmpty) {
        result.add(PendingExercise(
          index: i,
          name: names[i],
          unfinishedSets: unfinished,
          setsWithoutWeight: noWeight,
        ));
      }
    }
    return result;
  }

  static int totalMissing(List<PendingExercise> pending) =>
      pending.fold(0, (sum, p) => sum + p.missingCount);
}
