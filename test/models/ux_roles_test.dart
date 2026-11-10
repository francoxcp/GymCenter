import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/admin/models/member_status.dart';
import 'package:gymlab/features/admin/screens/members_screen.dart';
import 'package:gymlab/features/admin/services/member_status_service.dart';
import 'package:gymlab/features/admin/widgets/weekly_summary_card.dart';
import 'package:gymlab/features/auth/models/user.dart';
import 'package:gymlab/features/home/widgets/streak_row.dart';
import 'package:gymlab/features/notifications/notifications_screen.dart';
import 'package:gymlab/features/notifications/notifications_service.dart';
import 'package:gymlab/features/organization/models/organization.dart';
import 'package:gymlab/features/organization/screens/platform_screen.dart';
import 'package:gymlab/features/profile/screens/edit_profile_screen.dart';
import 'package:gymlab/shared/navigation/role_tabs.dart';
import 'package:gymlab/shared/widgets/top_actions.dart';

User _u(String id,
        {String role = 'user',
        DateTime? end,
        String? trainer,
        DateTime? created}) =>
    User(
      id: id,
      email: '$id@x.com',
      name: id,
      role: role,
      membershipEnd: end,
      trainerId: trainer,
      createdAt: created,
    );

void main() {
  group('pestañas por rol', () {
    test('socio: Hoy · Progreso · Perfil', () {
      expect(memberTabs.map((t) => t.path), ['/home', '/progress', '/profile']);
      expect(tabIndexFor(memberTabs, '/today-workout'), 0);
      expect(tabIndexFor(memberTabs, '/workout-detail/abc'), 0);
      expect(tabIndexFor(memberTabs, '/achievements'), 1);
      expect(tabIndexFor(memberTabs, '/settings'), 2);
    });

    test('entrenador: /admin/members no cae en Hoy', () {
      expect(tabIndexFor(trainerTabs, '/admin/today'), 0);
      expect(tabIndexFor(trainerTabs, '/admin'), 0);
      expect(tabIndexFor(trainerTabs, '/admin/members'), 1);
      expect(tabIndexFor(trainerTabs, '/admin/user-progress/1'), 1);
      expect(tabIndexFor(trainerTabs, '/admin/create-workout'), 3);
      expect(tabIndexFor(trainerTabs, '/chats'), 2);
    });

    test('dueño: Gimnasio y Panel por prefijo más largo', () {
      expect(ownerTabs.length, 5);
      expect(tabIndexFor(ownerTabs, '/admin'), 0);
      expect(tabIndexFor(ownerTabs, '/admin/activity'), 0);
      expect(tabIndexFor(ownerTabs, '/admin/organization'), 3);
      expect(tabIndexFor(ownerTabs, '/admin/memberships'), 1);
      // /administrador no es /admin/…
      expect(tabIndexFor(ownerTabs, '/profile'), 4);
    });
  });

  group('racha semanal', () {
    final now = DateTime(2026, 11, 12); // jueves
    test('sin entrenos = 0', () => expect(weeklyStreak([], now), 0));
    test('semana actual sin entrenar no rompe la racha', () {
      final s = [DateTime(2026, 11, 3), DateTime(2026, 10, 28)];
      expect(weeklyStreak(s, now), 2);
    });
    test('un hueco corta la racha', () {
      final s = [DateTime(2026, 11, 10), DateTime(2026, 10, 27)];
      expect(weeklyStreak(s, now), 1);
    });
  });

  test('snapshot: hoy, semana y solo socios propios', () {
    final now = DateTime(2026, 11, 12, 18);
    final snap = MembersSnapshot.build(
      members: [_u('a'), _u('b')],
      sessions: [
        (userId: 'a', at: DateTime(2026, 11, 12, 7)),
        (userId: 'a', at: DateTime(2026, 11, 10, 7)),
        (userId: 'b', at: DateTime(2026, 11, 1, 7)),
        (userId: 'ajeno', at: DateTime(2026, 11, 12, 9)),
      ],
      plannedByUser: const {'a': 3},
      now: now,
    );
    expect(snap.trainedToday.keys, ['a']);
    expect(snap.sessionsThisWeek, 2);
    expect(snap.status['b']!.light, MemberLight.red);
  });

  test('filtros de socios', () {
    final today = DateTime.now();
    final expired = _u('x', end: today.subtract(const Duration(days: 3)));
    final expiring = _u('y', end: today.add(const Duration(days: 2)), trainer: 't');
    expect(MembersFilter.expired.matches(expired, null), isTrue);
    expect(MembersFilter.expiring.matches(expiring, null), isTrue);
    expect(MembersFilter.noTrainer.matches(expired, null), isTrue);
    expect(MembersFilter.noTrainer.matches(expiring, null), isFalse);
    expect(MembersFilterX.parse('por-vencer'), MembersFilter.expiring);
    expect(MembersFilterX.parse('nada'), isNull);
  });

  test('números de la semana del dueño', () {
    final now = DateTime(2026, 11, 12);
    final w = WeekNumbers.from([
      _u('n', created: DateTime(2026, 11, 10)),
      _u('o', created: DateTime(2026, 10, 1)),
      _u('t', role: 'trainer', created: DateTime(2026, 11, 11)),
    ], now);
    expect(w.newMembers, 1);
  });

  test('avisos: ruta interna y tiempo relativo', () {
    AppNotification n(String? url) => AppNotification(
        id: 1, title: 't', body: 'b', url: url,
        createdAt: DateTime(2026), read: false);
    expect(n('/platform?org=1').route, '/platform?org=1');
    expect(n('https://gym.app/admin/activity').route, '/admin/activity');
    expect(n(null).route, isNull);
    final now = DateTime(2026, 11, 12, 12);
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), 'hace 5 min');
    expect(timeAgo(now.subtract(const Duration(days: 1)), now: now), 'ayer');
  });

  test('clientes de la plataforma: filtros y actividad', () {
    final now = DateTime(2026, 11, 12);
    final org = Organization.fromJson({
      'id': 'o', 'name': 'Gym', 'kind': 'gym', 'status': 'active',
      'billing_status': 'approved',
    });
    final idle = OrgSummary(
        // Con dueño: un cliente sin dueño cae en "Sin dueño", no en "Sin uso"
        org: org, ownerName: 'Ana', ownerEmail: null, trainers: 0,
        members: 3, pendingReviews: 1,
        lastActivity: DateTime(2026, 10, 1), sessions30d: 0);
    expect(OrgFilter.review.matches(idle, now), isTrue);
    expect(OrgFilter.inactive.matches(idle, now), isTrue);
    expect(activityLabel(idle, now: now), 'Último entreno hace 42 días · 0 en 30 días');
  });

  test('teléfono y búsqueda sin tildes', () {
    expect(validPhone(''), isTrue);
    expect(validPhone('8888 8888'), isTrue);
    expect(validPhone('+506 8888 8888'), isTrue);
    expect(validPhone('abc'), isFalse);
    expect(foldText('  María José '), 'maria jose');
  });
}
