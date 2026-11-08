import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/navigation/safe_pop.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';
import '../widgets/invite_link_sheet.dart';

Color billingColor(BillingState s) => switch (s) {
      BillingState.upToDate => const Color(0xFF2E9D4F),
      BillingState.inReview => const Color(0xFFE09B00),
      BillingState.pending => const Color(0xFFE5484D),
    };

String fmtDay(DateTime d) {
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep',
    'oct', 'nov', 'dic'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// /admin/organization — "Mi gimnasio" / "Mi negocio" (solo el dueño):
/// marca (nombre y logo), suscripción con comprobante de pago e invitaciones.
class MyOrganizationScreen extends StatefulWidget {
  const MyOrganizationScreen({super.key});

  @override
  State<MyOrganizationScreen> createState() => _MyOrganizationScreenState();
}

class _MyOrganizationScreenState extends State<MyOrganizationScreen> {
  List<OrgPayment> _payments = const [];
  bool _loadingPayments = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    await auth.reloadOrganization();
    final org = auth.organization;
    if (org == null) return;
    try {
      final p = await OrganizationService.payments(org.id);
      if (mounted) setState(() => _payments = p);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  Future<PlatformFile?> _pick(List<String> exts) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: exts,
      withData: true,
    );
    final f = r?.files.single;
    if (f == null || f.bytes == null) return null;
    if (f.size > 5 * 1024 * 1024) {
      if (mounted) AppSnackbar.error(context, 'El archivo pesa más de 5 MB');
      return null;
    }
    return f;
  }

  Future<void> _changeLogo(Organization org) async {
    final f = await _pick(const ['png', 'jpg', 'jpeg', 'webp']);
    if (f == null) return;
    if (f.size > 2 * 1024 * 1024) {
      if (mounted) AppSnackbar.error(context, 'El logo debe pesar menos de 2 MB');
      return;
    }
    setState(() => _busy = true);
    try {
      final url = await OrganizationService.uploadLogo(
          orgId: org.id, bytes: f.bytes!, extension: f.extension ?? 'png');
      await OrganizationService.updateMine(logoUrl: url);
      await _refresh();
      if (mounted) AppSnackbar.success(context, 'Logo actualizado');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'No se pudo subir el logo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(Organization org) async {
    final ctrl = TextEditingController(text: org.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nombre del negocio'),
        content: TextField(
          controller: ctrl,
          maxLength: 60,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.length < 2) return;
    try {
      await OrganizationService.updateMine(name: name);
      await _refresh();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudo guardar');
    }
  }

  Future<void> _uploadReceipt(Organization org) async {
    var months = 1;
    final amountCtrl = TextEditingController(
        text: org.monthlyFee != null ? org.monthlyFee!.toStringAsFixed(0) : '');
    PlatformFile? file;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Subir comprobante',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text('¿Cuántos meses pagaste?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final m in const [1, 3, 6, 12])
                      ChoiceChip(
                        label: Text(m == 1 ? '1 mes' : '$m meses'),
                        selected: months == m,
                        onSelected: (_) => set(() => months = m),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Monto pagado (opcional)', prefixText: '₡ '),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final f = await _pick(const ['png', 'jpg', 'jpeg', 'webp', 'pdf']);
                      if (f != null) set(() => file = f);
                    },
                    icon: Icon(file == null ? Icons.attach_file : Icons.check_circle),
                    label: Text(file?.name ?? 'Elegir foto o PDF del comprobante',
                        overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: file == null ? null : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Enviar a revisión',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim());
    amountCtrl.dispose();
    if (ok != true || file == null) return;
    setState(() => _busy = true);
    try {
      await OrganizationService.submitPayment(
        orgId: org.id,
        months: months,
        amount: amount,
        bytes: file!.bytes!,
        extension: file!.extension ?? 'jpg',
      );
      await _refresh();
      if (mounted) {
        AppSnackbar.success(context, 'Comprobante enviado. Te avisamos al validarlo.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(String role, Organization org) async {
    try {
      final token = await OrganizationService.createInvitation(role);
      if (!mounted) return;
      final trainer = role == 'trainer';
      await showInviteLinkSheet(
        context,
        token: token,
        title: trainer ? 'Invitar entrenador' : 'Enlace para socios',
        hint: trainer
            ? 'Sirve para una sola persona y vence en 7 días.'
            : 'Compártelo con tus socios: sirve para varias personas durante 30 días.',
        shareText: trainer
            ? 'Te invito a ser entrenador en ${org.name}. Crea tu cuenta aquí:'
            : 'Únete a ${org.name} para ver tus rutinas y tu progreso:',
      );
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<AuthProvider>().organization;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/admin'),
        ),
        title: Text(org?.isIndependent == true ? 'Mi negocio' : 'Mi gimnasio'),
      ),
      body: org == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _brand(org),
                  const SizedBox(height: 28),
                  _billing(org),
                  const SizedBox(height: 28),
                  _sectionTitle('Invitar'),
                  if (org.isGym)
                    _action(Icons.badge_outlined, 'Invitar entrenador',
                        'Enlace de un solo uso', () => _invite('trainer', org)),
                  _action(Icons.group_add_outlined, 'Enlace para socios',
                      'Para inscribirse directo contigo', () => _invite('user', org)),
                  const SizedBox(height: 28),
                  _sectionTitle('Historial de pagos'),
                  if (_loadingPayments)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()))
                  else if (_payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Todavía no has subido comprobantes.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    for (final p in _payments) _paymentRow(p),
                ],
              ),
            ),
    );
  }

  Widget _brand(Organization org) => Row(children: [
        Semantics(
          button: true,
          label: 'Cambiar logo',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _busy ? null : () => _changeLogo(org),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 76,
                height: 76,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: org.logoUrl != null
                    ? Image.network(org.logoUrl!, width: 76, height: 76, fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo_outlined, color: AppColors.onPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(org.kindLabel.toUpperCase(),
                style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(org.name,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w900)),
            TextButton(
              onPressed: () => _rename(org),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Cambiar nombre'),
            ),
          ]),
        ),
      ]);

  Widget _billing(Organization org) {
    final st = Billing.state(org);
    final color = billingColor(st);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Billing.label(st).toUpperCase(),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        if (org.paidUntil != null) ...[
          Text(st == BillingState.upToDate ? 'Pagado hasta' : 'Venció / vence',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(fmtDay(org.paidUntil!),
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1)),
        ],
        if (org.monthlyFee != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Plan ${org.plan} · ₡${org.monthlyFee!.toStringAsFixed(0)} al mes',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        if (org.billingNote != null && org.billingNote!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(org.billingNote!,
              style: TextStyle(color: AppColors.textPrimary, height: 1.4)),
        ],
        if (st != BillingState.inReview) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : () => _uploadReceipt(org),
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir comprobante de pago',
                style: TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Estamos revisando tu comprobante. Te avisaremos al validarlo.',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          header: true,
          child: Text(t,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
      );

  Widget _action(IconData icon, String title, String subtitle, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 12,
        leading: Icon(icon, color: AppColors.primaryText),
        title: Text(title,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      );

  Widget _paymentRow(OrgPayment p) {
    final color = switch (p.status) {
      'approved' => billingColor(BillingState.upToDate),
      'rejected' => billingColor(BillingState.pending),
      _ => billingColor(BillingState.inReview),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 4, height: 40, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '${p.months == 1 ? '1 mes' : '${p.months} meses'}'
                '${p.amount != null ? ' · ₡${p.amount!.toStringAsFixed(0)}' : ''}',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            Text('${p.statusLabel} · enviado el ${fmtDay(p.submittedAt)}',
                style: TextStyle(color: color, fontSize: 13)),
            if (p.reviewComment != null && p.reviewComment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.reviewComment!,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.35)),
              ),
          ]),
        ),
      ]),
    );
  }
}
