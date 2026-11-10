import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/workouts/models/exercise.dart';
import 'package:gymlab/features/workouts/models/superset.dart';

Exercise ex(String name,
        {String? group, int sets = 3, int rest = 60, int reps = 12}) =>
    Exercise(
      id: name,
      name: name,
      sets: sets,
      reps: reps,
      restSeconds: rest,
      muscleGroup: 'Pierna',
      supersetGroup: group,
    );

List<String?> groups(List<Exercise> l) => l.map((e) => e.supersetGroup).toList();

void main() {
  group('Exercise.supersetGroup', () {
    test('se lee de la BD y de la caché local', () {
      expect(
          Exercise.fromJson({'name': 'A', 'superset_group': 'g1'}).supersetGroup,
          'g1');
      expect(Exercise.fromJson({'name': 'A', 'supersetGroup': 'g2'}).supersetGroup,
          'g2');
      expect(Exercise.fromJson({'name': 'A', 'superset_group': ''}).supersetGroup,
          isNull);
      expect(Exercise.fromJson({'name': 'A'}).supersetGroup, isNull);
    });

    test('toJson/fromJson conserva el grupo', () {
      final e = ex('A', group: 'g1');
      expect(Exercise.fromJson(e.toJson()).supersetGroup, 'g1');
    });
  });

  group('supersetSpanAt', () {
    test('detecta el tramo y las letras', () {
      final l = [ex('X'), ex('A', group: 'g'), ex('B', group: 'g'), ex('Y')];
      final span = supersetSpanAt(l, 2)!;
      expect(span, const SupersetSpan(1, 2));
      expect(span.labelFor(1), 'A');
      expect(span.labelFor(2), 'B');
      expect(supersetSpanAt(l, 0), isNull);
    });

    test('un ejercicio solo con grupo no es superserie', () {
      expect(supersetSpanAt([ex('A', group: 'g'), ex('B')], 0), isNull);
    });
  });

  group('linkWithNext / unlinkFromNext', () {
    test('une dos sueltos con rondas y descanso del primero', () {
      final l = linkWithNext(
          [ex('A', sets: 4, rest: 90), ex('B', sets: 3, rest: 30)], 0);
      expect(l[0].supersetGroup, isNotNull);
      expect(l[0].supersetGroup, l[1].supersetGroup);
      expect(l.map((e) => e.sets), [4, 4]);
      expect(l.map((e) => e.restSeconds), [90, 90]);
    });

    test('agrega un tercero y un cuarto, pero no un quinto', () {
      var l = [ex('A'), ex('B'), ex('C'), ex('D'), ex('E')];
      l = linkWithNext(l, 0);
      l = linkWithNext(l, 1);
      l = linkWithNext(l, 2);
      expect(supersetSpanAt(l, 0)!.size, 4);
      expect(canLinkWithNext(l, 3), isFalse);
      expect(linkWithNext(l, 3), same(l));
    });

    test('no une dos grupos que sumen más de 4', () {
      final l = [
        ex('A', group: 'g1'),
        ex('B', group: 'g1'),
        ex('C', group: 'g1'),
        ex('D', group: 'g2'),
        ex('E', group: 'g2'),
      ];
      expect(canLinkWithNext(l, 2), isFalse);
    });

    test('separar en medio deja un grupo y un suelto', () {
      var l = linkWithNext(linkWithNext([ex('A'), ex('B'), ex('C')], 0), 1);
      l = unlinkFromNext(l, 1);
      expect(supersetSpanAt(l, 0), const SupersetSpan(0, 1));
      expect(l[2].supersetGroup, isNull);
    });

    test('separar un par deja los dos sueltos', () {
      final l = unlinkFromNext(linkWithNext([ex('A'), ex('B')], 0), 0);
      expect(groups(l), [null, null]);
    });
  });

  group('normalizeSupersets', () {
    test('al reordenar, un grupo separado se divide y los sueltos se limpian',
        () {
      final l = normalizeSupersets([
        ex('A', group: 'g'),
        ex('X'),
        ex('B', group: 'g'),
        ex('C', group: 'g'),
      ]);
      expect(l[0].supersetGroup, isNull);
      expect(l[2].supersetGroup, isNotNull);
      expect(l[2].supersetGroup, l[3].supersetGroup);
    });

    test('mismo id en dos tramos da ids distintos', () {
      final l = normalizeSupersets([
        ex('A', group: 'g'),
        ex('B', group: 'g'),
        ex('X'),
        ex('C', group: 'g'),
        ex('D', group: 'g'),
      ]);
      expect(l[0].supersetGroup, isNot(l[3].supersetGroup));
      expect(l[3].supersetGroup, l[4].supersetGroup);
    });

    test('más de 4 seguidos se parte', () {
      final l = normalizeSupersets(
          [for (final n in 'ABCDE'.split('')) ex(n, group: 'g')]);
      expect(supersetSpanAt(l, 0)!.size, 4);
      expect(l[4].supersetGroup, isNull);
    });
  });

  test('applyRoundsAndRest cambia todo el grupo', () {
    final l = applyRoundsAndRest(
        [ex('X'), ex('A', group: 'g'), ex('B', group: 'g')], 2, 5, 120);
    expect(l.map((e) => e.sets), [3, 5, 5]);
    expect(l.map((e) => e.restSeconds), [60, 120, 120]);
  });

  test('duplicar dentro de un grupo inserta después del grupo', () {
    final l = [ex('A', group: 'g'), ex('B', group: 'g'), ex('X')];
    expect(duplicateInsertIndex(l, 0), 2);
    expect(duplicateInsertIndex(l, 2), 3);
  });

  group('supersetStepAfterSet (flujo guiado)', () {
    final l = [
      ex('A', group: 'g', sets: 3),
      ex('B', group: 'g', sets: 3),
      ex('C', group: 'g', sets: 3),
      ex('X'),
    ];

    test('ejercicio suelto usa el flujo normal', () {
      expect(supersetStepAfterSet(l, 3, 0), isNull);
    });

    test('A y B pasan al siguiente sin descanso', () {
      expect(supersetStepAfterSet(l, 0, 0),
          const SupersetStep(goTo: 1, rest: false));
      expect(supersetStepAfterSet(l, 1, 1),
          const SupersetStep(goTo: 2, rest: false));
    });

    test('el último de la ronda descansa y vuelve al primero', () {
      expect(supersetStepAfterSet(l, 2, 0),
          const SupersetStep(goTo: 0, rest: true));
    });

    test('última ronda: descanso y pasa al ejercicio de después', () {
      expect(supersetStepAfterSet(l, 2, 2),
          const SupersetStep(goTo: 3, rest: true));
    });

    test('superserie al final de la rutina: sin descanso ni salto', () {
      final end = [ex('X'), ex('A', group: 'g', sets: 2), ex('B', group: 'g', sets: 2)];
      expect(supersetStepAfterSet(end, 2, 1),
          const SupersetStep(goTo: null, rest: false));
    });
  });

  group('operaciones del editor', () {
    test('editar un miembro sincroniza rondas y descanso del grupo', () {
      final l = [ex('A', group: 'g'), ex('B', group: 'g')];
      final out = replaceKeepingSuperset(
          l, 1, Exercise(id: 'B', name: 'B', sets: 5, reps: 8, restSeconds: 45, muscleGroup: 'x'));
      expect(out[1].supersetGroup, 'g');
      expect(out.map((e) => e.sets), [5, 5]);
      expect(out.map((e) => e.restSeconds), [45, 45]);
      expect(out[1].reps, 8);
      expect(out[0].reps, 12);
    });

    test('sacar un ejercicio arrastrándolo deja el resto unido', () {
      final l = [ex('A', group: 'g'), ex('B', group: 'g'), ex('C', group: 'g'), ex('X')];
      final out = moveExercise(l, 0, 4);
      expect(out.map((e) => e.name), ['B', 'C', 'X', 'A']);
      expect(supersetSpanAt(out, 0), const SupersetSpan(0, 1));
      expect(out[3].supersetGroup, isNull);
    });

    test('borrar uno de un par deja el otro suelto', () {
      final out = removeExerciseAt([ex('A', group: 'g'), ex('B', group: 'g')], 0);
      expect(out.single.supersetGroup, isNull);
    });

    test('duplicar dentro del grupo agrega la copia suelta al final del grupo', () {
      final l = [ex('A', group: 'g'), ex('B', group: 'g')];
      final out = insertDuplicate(l, 0, l[0]);
      expect(out.map((e) => e.name), ['A', 'B', 'A']);
      expect(out[2].supersetGroup, isNull);
      expect(supersetSpanAt(out, 1), const SupersetSpan(0, 1));
    });

    test('toggleLinkWithNext une y separa', () {
      var l = [ex('A'), ex('B')];
      l = toggleLinkWithNext(l, 0);
      expect(isLinkedWithNext(l, 0), isTrue);
      l = toggleLinkWithNext(l, 0);
      expect(isLinkedWithNext(l, 0), isFalse);
    });
  });
}
