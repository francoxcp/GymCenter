import 'package:chamos_fitness_center/config/router/app_router.dart';
import 'package:chamos_fitness_center/features/organization/models/organization.dart';
import 'package:chamos_fitness_center/features/organization/screens/platform_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvitationRow', () {
    test('personas que abrieron y no se registraron', () {
      final i = InvitationRow.fromJson({
        'token': 'ABCDEFGHJK',
        'role': 'user',
        'uses': 2,
        'max_uses': 100,
        'views': 5,
        'expires_at': '2026-12-01T00:00:00Z',
      });
      expect(i.pendingSignups, 3);
      expect(i.roleLabel, 'Socios');
    });

    test('nunca negativo', () {
      final i = InvitationRow.fromJson({
        'token': 'X', 'role': 'trainer', 'uses': 1, 'max_uses': 1, 'views': 0,
        'expires_at': '2026-12-01T00:00:00Z',
      });
      expect(i.pendingSignups, 0);
      expect(i.roleLabel, 'Entrenador');
    });
  });

  test('PlatformStats.fromJson', () {
    final s = PlatformStats.fromJson({
      'collected_this_month': 45000,
      'collected_last_month': 30000,
      'expected_monthly': 60000,
      'active_orgs': 3,
      'in_trial': 1,
      'expiring_7d': 2,
      'pending': 1,
      'suspended': 0,
      'total_members': 40,
    });
    expect(s.collectedThisMonth, 45000);
    expect(s.expiring7d, 2);
    expect(s.totalMembers, 40);
  });

  test('formato de colones', () {
    expect(PlatformScreenTestable.money(0), '₡0');
    expect(PlatformScreenTestable.money(15000), '₡15.000');
    expect(PlatformScreenTestable.money(1234567), '₡1.234.567');
  });

  test('límite de socios en la organización', () {
    final o = Organization.fromJson(
        {'id': 'o', 'name': 'Gym', 'kind': 'gym', 'max_members': 30});
    expect(o.maxMembers, 30);
  });

  test('enlace profundo pendiente se usa una sola vez', () {
    DeepLinkMemory.remember('/admin/organization');
    expect(DeepLinkMemory.take(), '/admin/organization');
    expect(DeepLinkMemory.take(), isNull);
  });
}
