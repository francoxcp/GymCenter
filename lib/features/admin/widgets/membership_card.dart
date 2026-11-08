import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';

const kMembershipPlans = <String, int>{
  'Mensual': 1,
  'Trimestral': 3,
  'Semestral': 6,
  'Anual': 12,
};

Color membershipColor(MembershipStatus s) => switch (s) {
      MembershipStatus.active => const Color(0xFF34C759),
      MembershipStatus.expiring => Colors.orangeAccent,
      MembershipStatus.expired => const Color(0xFFFF5A5F),
      MembershipStatus.none => AppColors.textSecondary,
    };

String fmtDate(DateTime d) {
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep',
    'oct', 'nov', 'dic'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Estado de la membresía del socio. El dueño puede registrar pagos y
/// corregir el vencimiento; el entrenador solo la ve.
class MembershipCard extends StatelessWidget {
  final String memberId;
  const MembershipCard({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    final member = context.watch<UserProvider>().userById(memberId);
    if (member == null) return const SizedBox.shrink();
    final status = member.membershipStatus;
    final color = membershipColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.card_membership, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.membershipPlan ?? 'Membresía',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(
                    member.membershipEnd == null
                        ? 'Sin membresía registrada'
                        : '${Membership.label(member.membershipEnd)} · ${fmtDate(member.membershipEnd!)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ]),
          if (isOwner) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showRenewMembershipDialog(context, member),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Registrar pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Cambiar fecha de vencimiento',
                onPressed: () => _editEnd(context, member),
                icon: const Icon(Icons.edit_calendar),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              IconButton(
                tooltip: 'Historial de pagos',
                onPressed: () => _showHistory(context, member),
                icon: const Icon(Icons.receipt_long),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _editEnd(BuildContext context, User member) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: member.membershipEnd ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      helpText: 'Vencimiento de la membresía',
    );
    if (picked == null || !context.mounted) return;
    final err =
        await context.read<UserProvider>().setMembershipEnd(member.id, picked);
    if (!context.mounted) return;
    err == null
        ? AppSnackbar.success(context, 'Vencimiento actualizado')
        : AppSnackbar.error(context, err);
  }

  Future<void> _showHistory(BuildContext context, User member) async {
    final rows =
        await context.read<UserProvider>().loadMembershipPayments(member.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Aún no hay pagos registrados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Historial de pagos',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  for (final r in rows)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          '${r['plan']}${r['amount'] != null ? ' · ₡${(r['amount'] as num).toStringAsFixed(0)}' : ''}',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                          '${r['period_start']} → ${r['period_end']}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ),
                ],
              ),
      ),
    );
  }
}

Future<void> showRenewMembershipDialog(BuildContext context, User member) {
  var plan = 'Mensual';
  final amountCtrl = TextEditingController();
  var saving = false;
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pago de ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in kMembershipPlans.keys)
                  ChoiceChip(
                    label: Text(p),
                    selected: plan == p,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: plan == p ? Colors.black : Colors.white),
                    onSelected: (_) => setState(() => plan = p),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto (opcional)',
                prefixText: '₡ ',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              member.membershipStatus == MembershipStatus.active ||
                      member.membershipStatus == MembershipStatus.expiring
                  ? 'Se suma a partir del vencimiento actual.'
                  : 'Empieza a contar desde hoy.',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    final amount = double.tryParse(
                        amountCtrl.text.replaceAll(',', '.').trim());
                    final err = await context
                        .read<UserProvider>()
                        .renewMembership(
                          userId: member.id,
                          plan: plan,
                          months: kMembershipPlans[plan]!,
                          amount: amount,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
                    err == null
                        ? AppSnackbar.success(context, 'Membresía registrada')
                        : AppSnackbar.error(context, err);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  ).whenComplete(amountCtrl.dispose);
}
