import 'package:gymlab/features/organization/models/organization.dart';
import 'package:gymlab/features/organization/screens/join_organization_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Organization', () {
    test('fromJson y tipos', () {
      final o = Organization.fromJson({
        'id': 'o1',
        'name': 'Gym Norte',
        'kind': 'independent',
        'paid_until': '2026-12-01',
        'billing_status': 'in_review',
      });
      expect(o.isIndependent, isTrue);
      expect(o.kindLabel, 'Entrenador independiente');
      expect(o.paidUntil, DateTime(2026, 12, 1));
      expect(Billing.state(o), BillingState.inReview);
      expect(Billing.label(Billing.state(o)), 'En revisión');
    });

    test('estado de cobro', () {
      Organization withStatus(String s) =>
          Organization(id: 'x', name: 'X', kind: 'gym', billingStatus: s);
      expect(Billing.state(withStatus('approved')), BillingState.upToDate);
      expect(Billing.state(withStatus('pending')), BillingState.pending);
      expect(Billing.state(withStatus('cualquier cosa')), BillingState.pending);
    });

    test('invitación: etiqueta de rol', () {
      InvitationInfo info(String role, String kind) => InvitationInfo(
          orgName: 'A', orgLogo: null, orgKind: kind, role: role, valid: true);
      expect(info('admin', 'gym').roleLabel, 'dueño');
      expect(info('admin', 'independent').roleLabel, 'entrenador');
      expect(info('trainer', 'gym').roleLabel, 'entrenador');
      expect(info('user', 'gym').roleLabel, 'socio');
    });
  });

  group('Código para unirse', () {
    test('acepta código, código con espacios y enlace completo', () {
      expect(normalizeJoinCode(' f5pzey '), 'F5PZEY');
      expect(normalizeJoinCode('AB12-CD34-EF'), 'AB12CD34EF');
      expect(
          normalizeJoinCode(
              'https://gym-nine-sand.vercel.app/invitacion/AB12CD34EF'),
          'AB12CD34EF');
    });
  });
}
