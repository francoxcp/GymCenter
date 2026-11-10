import 'package:flutter_test/flutter_test.dart';
import 'package:gymlab/features/organization/models/organization.dart';

void main() {
  // Lunes 9 de noviembre de 2026
  final now = DateTime(2026, 11, 9, 10);

  OrgSummary client({
    String name = 'Cliente',
    String status = 'active',
    String billing = 'approved',
    String? paidUntil = '2026-12-31',
    String? owner = 'Ana',
    String? inviteToken,
    String? inviteExpires,
    int reviews = 0,
    bool trial = false,
    bool internal = false,
    String? lastActivity = '2026-11-08T10:00:00Z',
  }) =>
      OrgSummary.fromJson({
        'id': name,
        'name': name,
        'kind': 'gym',
        'status': status,
        'billing_status': billing,
        'paid_until': paidUntil,
        'plan': internal ? 'Interno' : 'Mensual',
        'owner_name': owner,
        'invite_token': inviteToken,
        'invite_expires_at': inviteExpires,
        'pending_reviews': reviews,
        'in_trial': trial,
        'is_internal': internal,
        'last_activity': lastActivity,
      });

  group('Estado del cliente', () {
    test('suspendido nunca se ve al día', () {
      expect(client(status: 'suspended').state(now), ClientState.suspended);
    });

    test('sin dueño: invitación pendiente o vencida', () {
      final pending = client(
          owner: null, inviteToken: 'ABC', inviteExpires: '2026-11-12T00:00:00Z');
      expect(pending.state(now), ClientState.noOwner);
      expect(pending.invitePending, isTrue);
      final expired = client(owner: null);
      expect(expired.inviteExpired, isTrue);
    });

    test('comprobante por revisar va antes que pago pendiente', () {
      expect(client(reviews: 1, billing: 'pending').state(now), ClientState.review);
      expect(client(billing: 'pending').state(now), ClientState.pending);
    });

    test('interno no es un cliente', () {
      expect(client(internal: true).state(now), ClientState.internal);
      expect(OrgFilter.all.matches(client(internal: true), now), isFalse);
    });

    test('días restantes y por vencer', () {
      final soon = client(paidUntil: '2026-11-14');
      expect(soon.daysLeft(now), 5);
      expect(soon.expiringSoon(now), isTrue);
      expect(client(paidUntil: '2026-11-20').expiringSoon(now), isFalse);
      // Suspendido no cuenta como "por vencer"
      expect(client(paidUntil: '2026-11-14', status: 'suspended').expiringSoon(now),
          isFalse);
    });
  });

  group('Filtros', () {
    test('en prueba no incluye suspendidos', () {
      expect(OrgFilter.trial.matches(client(trial: true), now), isTrue);
      expect(OrgFilter.trial.matches(client(trial: true, status: 'suspended'), now),
          isFalse);
    });

    test('sin uso solo con dueño y activo', () {
      final idle = client(lastActivity: '2026-10-01T10:00:00Z');
      expect(OrgFilter.inactive.matches(idle, now), isTrue);
      expect(OrgFilter.inactive.matches(client(owner: null, lastActivity: null), now),
          isFalse);
      expect(OrgFilter.noOwner.matches(client(owner: null), now), isTrue);
    });
  });

  group('Para atender hoy', () {
    test('una tarea por cliente, la más urgente, en orden', () {
      final tasks = platformTasks([
        client(name: 'Inactivo', lastActivity: '2026-10-01T10:00:00Z'),
        client(name: 'Vence', paidUntil: '2026-11-10'),
        client(name: 'Comprobante', reviews: 2, billing: 'pending'),
        client(name: 'SinDueño', owner: null,
            inviteToken: 'X', inviteExpires: '2026-11-12T00:00:00Z'),
        client(name: 'Debe', billing: 'pending', paidUntil: '2026-11-01'),
        client(name: 'AlDía'),
        client(name: 'Suspendido', status: 'suspended', billing: 'pending'),
        client(name: 'Interno', internal: true, billing: 'pending'),
      ], now);
      expect(tasks.map((t) => t.client.org.name), [
        'Comprobante',
        'SinDueño',
        'Debe',
        'Vence',
        'Inactivo',
      ]);
      expect(tasks.first.detail, 'Subió 2 comprobantes de pago');
      expect(tasks[1].detail, contains('No ha aceptado la invitación'));
      expect(tasks[3].detail, 'La suscripción vence mañana');
    });

    test('invitación vencida pide enviar una nueva', () {
      final t = platformTasks([client(owner: null)], now).single;
      expect(t.kind, TaskKind.noOwner);
      expect(t.detail, contains('venció'));
    });

    test('sin nada pendiente → lista vacía', () {
      expect(platformTasks([client()], now), isEmpty);
    });
  });

  test('pago manual se reconoce por la ruta', () {
    final p = OrgPayment.fromJson({
      'id': 'p', 'org_id': 'o', 'months': 1, 'receipt_path': 'manual/123',
      'status': 'approved', 'submitted_at': '2026-11-09T10:00:00Z',
      'receipt_deleted_at': '2026-11-09T10:00:00Z',
    });
    expect(p.isManual, isTrue);
  });
}
