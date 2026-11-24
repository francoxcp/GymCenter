import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/auth/models/user.dart';

void main() {
  final today = DateTime(2026, 11, 8, 15, 30);

  test('sin fecha → none', () {
    expect(Membership.status(null, today: today), MembershipStatus.none);
    expect(Membership.label(null, today: today), 'Sin membresía');
  });

  test('vence hoy cuenta como por vencer', () {
    final end = DateTime(2026, 11, 8);
    expect(Membership.daysLeft(end, today: today), 0);
    expect(Membership.status(end, today: today), MembershipStatus.expiring);
    expect(Membership.label(end, today: today), 'Vence hoy');
  });

  test('7 días = por vencer, 8 = activa', () {
    expect(Membership.status(DateTime(2026, 11, 15), today: today),
        MembershipStatus.expiring);
    expect(Membership.status(DateTime(2026, 11, 16), today: today),
        MembershipStatus.active);
  });

  test('vencida', () {
    final end = DateTime(2026, 11, 5);
    expect(Membership.status(end, today: today), MembershipStatus.expired);
    expect(Membership.label(end, today: today), 'Vencida hace 3 días');
  });

  test('fromJson/toJson conserva la membresía', () {
    final u = User.fromJson({
      'id': '1',
      'email': 'a@b.c',
      'name': 'A',
      'membership_plan': 'Mensual',
      'membership_end': '2026-12-01',
    });
    expect(u.membershipEnd, DateTime(2026, 12, 1));
    final back = User.fromJson(u.toJson());
    expect(back.membershipPlan, 'Mensual');
    expect(back.membershipEnd, DateTime(2026, 12, 1));
  });

  group('Membership.canCharge', () {
    User u(String id, String role, {String? trainer}) =>
        User(id: id, email: '$id@x.com', name: id, role: role, trainerId: trainer);

    final owner = u('owner', 'admin');
    final coach = u('coach', 'trainer');
    final otherCoach = u('coach2', 'trainer');
    final member = u('m1', 'user', trainer: 'coach');

    test('el dueño cobra a cualquier socio', () {
      expect(Membership.canCharge(owner, member), isTrue);
    });
    test('el entrenador cobra solo a sus socios', () {
      expect(Membership.canCharge(coach, member), isTrue);
      expect(Membership.canCharge(otherCoach, member), isFalse);
    });
    test('un socio no cobra, y no se cobra a personal', () {
      expect(Membership.canCharge(member, member), isFalse);
      expect(Membership.canCharge(owner, coach), isFalse);
      expect(Membership.canCharge(null, member), isFalse);
    });
  });
}
