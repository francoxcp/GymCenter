import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/auth/models/user.dart';

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
}
