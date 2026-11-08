import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/organization.dart';
import '../screens/my_organization_screen.dart' show billingColor, fmtDay;

/// Aviso en el panel del dueño cuando la suscripción no está al día o
/// vence pronto. No ocupa espacio si todo está en orden.
class OrgBillingBanner extends StatelessWidget {
  const OrgBillingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final org = auth.organization;
    if (!auth.isAdmin || org == null) return const SizedBox.shrink();
    final st = Billing.state(org);
    final daysLeft = org.paidUntil?.difference(DateTime.now()).inDays;
    final soon = st == BillingState.upToDate && daysLeft != null && daysLeft <= 5;
    if (st == BillingState.upToDate && !soon) return const SizedBox.shrink();
    final color = soon ? billingColor(BillingState.inReview) : billingColor(st);
    final text = switch (st) {
      BillingState.inReview => 'Comprobante en revisión',
      BillingState.pending => org.billingNote?.isNotEmpty == true
          ? 'Pago pendiente: ${org.billingNote}'
          : 'Pago pendiente de la suscripción',
      BillingState.upToDate => 'Tu suscripción vence el ${fmtDay(org.paidUntil!)}',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/admin/organization'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Text(text,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
              Icon(Icons.chevron_right, color: color),
            ]),
          ),
        ),
      ),
    );
  }
}
