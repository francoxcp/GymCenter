import 'exercise.dart';

/// Superseries: 2 a 4 ejercicios seguidos que se hacen sin descanso entre
/// ellos. Comparten `supersetGroup`; sus `sets` son las rondas y su
/// `restSeconds` el descanso al terminar cada ronda.
const int kSupersetMinSize = 2;
const int kSupersetMaxSize = 4;

/// Tramo [start, end] (ambos incluidos) de una superserie en la lista.
class SupersetSpan {
  final int start;
  final int end;
  const SupersetSpan(this.start, this.end);

  int get size => end - start + 1;
  bool contains(int i) => i >= start && i <= end;

  /// Letra de cada ejercicio dentro del grupo: A, B, C, D.
  String labelFor(int i) => String.fromCharCode(65 + (i - start));

  @override
  bool operator ==(Object other) =>
      other is SupersetSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

int _seq = 0;
String newSupersetGroupId() =>
    'ss${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_seq++}';

/// Superserie que contiene el ejercicio [i], o null si va suelto.
SupersetSpan? supersetSpanAt(List<Exercise> list, int i) {
  if (i < 0 || i >= list.length) return null;
  final g = list[i].supersetGroup;
  if (g == null) return null;
  var s = i;
  while (s > 0 && list[s - 1].supersetGroup == g) {
    s--;
  }
  var e = i;
  while (e < list.length - 1 && list[e + 1].supersetGroup == g) {
    e++;
  }
  return e == s ? null : SupersetSpan(s, e);
}

/// Deja los grupos coherentes: solo tramos seguidos de 2 a 4 ejercicios,
/// un id distinto por tramo y las mismas rondas y descanso en todo el grupo
/// (los del primer ejercicio). Útil tras reordenar, borrar o duplicar.
List<Exercise> normalizeSupersets(List<Exercise> input) {
  final out = <Exercise>[];
  final usedIds = <String>{};
  var i = 0;
  while (i < input.length) {
    final g = input[i].supersetGroup;
    var j = i;
    while (g != null && j + 1 < input.length && input[j + 1].supersetGroup == g) {
      j++;
    }
    // Tramo [i, j] con el mismo id; se parte en bloques de máximo 4.
    for (var s = i; s <= j; s += kSupersetMaxSize) {
      final e = (s + kSupersetMaxSize - 1) < j ? s + kSupersetMaxSize - 1 : j;
      if (g == null || e == s) {
        for (var k = s; k <= e; k++) {
          out.add(input[k].inSuperset
              ? input[k].copyWith(clearSuperset: true)
              : input[k]);
        }
        continue;
      }
      var id = g;
      if (usedIds.contains(id)) id = newSupersetGroupId();
      usedIds.add(id);
      final head = input[s];
      for (var k = s; k <= e; k++) {
        out.add(input[k].copyWith(
          supersetGroup: id,
          sets: head.sets,
          restSeconds: head.restSeconds,
        ));
      }
    }
    i = j + 1;
  }
  return out;
}

/// ¿El ejercicio [i] y el siguiente están en la misma superserie?
bool isLinkedWithNext(List<Exercise> list, int i) =>
    i >= 0 &&
    i + 1 < list.length &&
    list[i].supersetGroup != null &&
    list[i].supersetGroup == list[i + 1].supersetGroup;

/// ¿Se puede unir [i] con el siguiente sin pasar de 4 ejercicios?
bool canLinkWithNext(List<Exercise> list, int i) {
  if (i < 0 || i + 1 >= list.length) return false;
  if (isLinkedWithNext(list, i)) return false;
  final a = supersetSpanAt(list, i)?.size ?? 1;
  final b = supersetSpanAt(list, i + 1)?.size ?? 1;
  return a + b <= kSupersetMaxSize;
}

/// Une [i] con el siguiente (y con sus grupos, si ya tenían). El grupo
/// resultante toma las rondas y el descanso del primer ejercicio.
List<Exercise> linkWithNext(List<Exercise> list, int i) {
  if (!canLinkWithNext(list, i)) return list;
  final a = supersetSpanAt(list, i) ?? SupersetSpan(i, i);
  final b = supersetSpanAt(list, i + 1) ?? SupersetSpan(i + 1, i + 1);
  final id = list[a.start].supersetGroup ??
      list[b.start].supersetGroup ??
      newSupersetGroupId();
  final out = [...list];
  for (var k = a.start; k <= b.end; k++) {
    out[k] = out[k].copyWith(supersetGroup: id);
  }
  return normalizeSupersets(out);
}

/// Separa [i] del siguiente: el grupo se corta en ese punto.
List<Exercise> unlinkFromNext(List<Exercise> list, int i) {
  if (!isLinkedWithNext(list, i)) return list;
  final span = supersetSpanAt(list, i)!;
  final id = newSupersetGroupId();
  final out = [...list];
  for (var k = i + 1; k <= span.end; k++) {
    out[k] = out[k].copyWith(supersetGroup: id);
  }
  return normalizeSupersets(out);
}

/// Aplica rondas y descanso a todo el grupo de [i] (o solo a [i] si va suelto).
List<Exercise> applyRoundsAndRest(
    List<Exercise> list, int i, int rounds, int restSeconds) {
  final span = supersetSpanAt(list, i) ?? SupersetSpan(i, i);
  final out = [...list];
  for (var k = span.start; k <= span.end; k++) {
    out[k] = out[k].copyWith(sets: rounds, restSeconds: restSeconds);
  }
  return out;
}

/// Índice donde insertar la copia de [i]: tras su grupo, para no romperlo.
int duplicateInsertIndex(List<Exercise> list, int i) =>
    (supersetSpanAt(list, i)?.end ?? i) + 1;

/// Qué hacer al marcar la serie [setIndex] del ejercicio [exIndex]
/// dentro de una superserie.
class SupersetStep {
  /// Página a la que llevar al socio (null = quedarse).
  final int? goTo;

  /// Si empieza el descanso (solo al cerrar una ronda).
  final bool rest;

  const SupersetStep({this.goTo, required this.rest});

  @override
  bool operator ==(Object other) =>
      other is SupersetStep && other.goTo == goTo && other.rest == rest;

  @override
  int get hashCode => Object.hash(goTo, rest);

  @override
  String toString() => 'SupersetStep(goTo: $goTo, rest: $rest)';
}

/// Flujo guiado: A → B → (C) → descanso → A… Devuelve null si el ejercicio
/// no está en una superserie (se usa el flujo normal).
SupersetStep? supersetStepAfterSet(
    List<Exercise> list, int exIndex, int setIndex) {
  final span = supersetSpanAt(list, exIndex);
  if (span == null) return null;
  if (exIndex < span.end) {
    return SupersetStep(goTo: exIndex + 1, rest: false);
  }
  final rounds = list[exIndex].sets;
  if (setIndex < rounds - 1) {
    return SupersetStep(goTo: span.start, rest: true);
  }
  final isLastOfWorkout = span.end == list.length - 1;
  return SupersetStep(
    goTo: isLastOfWorkout ? null : span.end + 1,
    rest: !isLastOfWorkout,
  );
}

// -- Operaciones del editor (crear/editar rutina) ---------------------------

/// Reemplaza el ejercicio [i] conservando su superserie; si está en una,
/// sus rondas y descanso pasan a todo el grupo.
List<Exercise> replaceKeepingSuperset(
    List<Exercise> list, int i, Exercise updated) {
  final old = list[i];
  final out = [...list];
  if (!old.inSuperset) {
    out[i] = updated;
    return out;
  }
  out[i] = updated.copyWith(supersetGroup: old.supersetGroup);
  return applyRoundsAndRest(out, i, out[i].sets, out[i].restSeconds);
}

/// Mueve un ejercicio (índices de ReorderableListView.onReorder).
List<Exercise> moveExercise(List<Exercise> list, int oldIndex, int newIndex) {
  if (newIndex > oldIndex) newIndex--;
  final out = [...list];
  final item = out.removeAt(oldIndex);
  out.insert(newIndex, item);
  return normalizeSupersets(out);
}

List<Exercise> removeExerciseAt(List<Exercise> list, int i) =>
    normalizeSupersets([...list]..removeAt(i));

/// Inserta [copy] (suelta) después del grupo del ejercicio [i].
List<Exercise> insertDuplicate(List<Exercise> list, int i, Exercise copy) =>
    [...list]..insert(duplicateInsertIndex(list, i),
        copy.copyWith(clearSuperset: true));

/// Une o separa [i] con el siguiente.
List<Exercise> toggleLinkWithNext(List<Exercise> list, int i) =>
    isLinkedWithNext(list, i) ? unlinkFromNext(list, i) : linkWithNext(list, i);
