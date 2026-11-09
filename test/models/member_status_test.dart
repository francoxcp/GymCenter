import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/admin/models/member_status.dart';

void main() {
  // Jueves 12 de noviembre de 2026 (weekday = 4)
  final now = DateTime(2026, 11, 12, 18);

  MemberStatus status(List<DateTime> sessions, {int planned = 4}) =>
      MemberStatus.compute(
          userId: 'u', plannedPerWeek: planned, sessions: sessions, now: now);

  group('Semáforo de socios', () {
    test('nunca entrenó → rojo', () {
      expect(status([]).light, MemberLight.red);
    });

    test('7 días o más sin venir → rojo', () {
      expect(status([DateTime(2026, 11, 5)]).light, MemberLight.red);
    });

    test('4 días sin venir → amarillo', () {
      expect(status([DateTime(2026, 11, 8)]).light, MemberLight.yellow);
    });

    test('por debajo de lo esperado en la semana → amarillo', () {
      // Plan de 4: el jueves debería llevar floor(4*4/7) = 2; lleva 1
      expect(status([DateTime(2026, 11, 11)]).light, MemberLight.yellow);
    });

    test('al día → verde y cuenta las sesiones de la semana', () {
      final s = status([DateTime(2026, 11, 9), DateTime(2026, 11, 11)]);
      expect(s.light, MemberLight.green);
      expect(s.sessionsThisWeek, 2);
      expect(s.daysSinceLast(now), 1);
    });

    test('sin plan: solo cuenta la recencia', () {
      expect(status([DateTime(2026, 11, 11)], planned: 0).light,
          MemberLight.green);
    });
  });

  group('Socio nuevo', () {
    MemberStatus joined(DateTime joinedAt, {List<DateTime> sessions = const []}) =>
        MemberStatus.compute(
            userId: 'u',
            plannedPerWeek: 3,
            sessions: sessions,
            now: now,
            joinedAt: joinedAt);

    test('se unió hace menos de 7 días y no entrena → nuevo, no rojo', () {
      expect(joined(DateTime(2026, 11, 10)).light, MemberLight.fresh);
    });

    test('se unió hace 7+ días sin entrenar → rojo', () {
      expect(joined(DateTime(2026, 11, 2)).light, MemberLight.red);
    });

    test('nuevo que ya entrenó → semáforo normal', () {
      expect(joined(DateTime(2026, 11, 10), sessions: [DateTime(2026, 11, 11)]).light,
          MemberLight.green);
    });
  });

  group('withPlanned (tras asignar rutinas)', () {
    test('actualiza los días planificados y conserva las sesiones', () {
      final s = status([DateTime(2026, 11, 10)], planned: 0).withPlanned(4, now: now);
      expect(s.plannedPerWeek, 4);
      expect(s.sessionsThisWeek, 1);
      // plan de 4: el jueves debería llevar 2 → atrasado
      expect(s.light, MemberLight.yellow);
    });

    test('un socio nuevo sigue nuevo al recibir su plan', () {
      final s = MemberStatus.compute(
              userId: 'u',
              plannedPerWeek: 0,
              sessions: const [],
              now: now,
              joinedAt: DateTime(2026, 11, 11))
          .withPlanned(3, now: now);
      expect(s.light, MemberLight.fresh);
      expect(s.plannedPerWeek, 3);
    });
  });
}
