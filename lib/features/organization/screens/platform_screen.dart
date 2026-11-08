import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/navigation/safe_pop.dart';
import '../../../shared/web/web_bridge.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';
import '../widgets/invite_link_sheet.dart';
import 'my_organization_screen.dart' show billingColor, fmtDay;

/// /platform — súper admin: clientes, comprobantes por revisar y altas.
class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  List<OrgSummary> _orgs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await OrganizationService.platformList();
      if (mounted) setState(() => _orgs = list);
    } catch (e) {
      if (mounted) setState(() => _error = OrganizationService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newClient() async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    var kind = 'gym';
    var trial = 14;
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
                  Text('Nuevo cliente',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'gym', label: Text('Gimnasio')),
                      ButtonSegment(value: 'independent', label: Text('Entrenador')),
                    ],
                    selected: {kind},
                    onSelectionChanged: (s) => set(() => kind = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: kind == 'gym'
                            ? 'Nombre del gimnasio'
                            : 'Nombre del entrenador o marca'),
                  ),
                  TextField(
                    controller: feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Cuota mensual (opcional)', prefixText: '₡ '),
                  ),
                  const SizedBox(height: 16),
                  Text('Días de prueba gratis',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Wrap(spacing: 8, children: [
                    for (final d in const [0, 7, 14, 30])
                      ChoiceChip(
                        label: Text(d == 0 ? 'Sin prueba' : '$d días'),
                        selected: trial == d,
                        onSelected: (_) => set(() => trial = d),
                      ),
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().length < 2) return;
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Crear y generar invitación',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    final fee = double.tryParse(feeCtrl.text.replaceAll(',', '.').trim());
    nameCtrl.dispose();
    feeCtrl.dispose();
    if (ok != true) return;
    try {
      final token = await OrganizationService.platformCreateOrg(
          name: name, kind: kind, monthlyFee: fee, trialDays: trial);
      await _load();
      if (!mounted) return;
      await showInviteLinkSheet(
        context,
        token: token,
        title: 'Invitación para $name',
        hint: 'Envíasela al dueño. Sirve una sola vez y vence en 7 días.',
        shareText: 'Te doy acceso a la app de rutinas para $name. Crea tu cuenta aquí:',
      );
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orgs.fold<int>(0, (s, o) => s + o.pendingReviews);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/admin'),
        ),
        title: const Text('Clientes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newClient,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cliente'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: AppColors.error)),
                  Row(children: [
                    _bigStat('${_orgs.length}', 'clientes'),
                    _bigStat('$pending', 'por revisar',
                        color: pending > 0 ? billingColor(BillingState.inReview) : null),
                    _bigStat(
                        '${_orgs.where((o) => Billing.state(o.org) == BillingState.pending).length}',
                        'pendientes',
                        color: billingColor(BillingState.pending)),
                  ]),
                  const SizedBox(height: 20),
                  for (final o in _orgs) _orgTile(o),
                ],
              ),
      ),
    );
  }

  Widget _bigStat(String value, String label, {Color? color}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );

  Widget _orgTile(OrgSummary s) {
    final st = Billing.state(s.org);
    final color = billingColor(st);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlatformOrgScreen(summary: s)));
          _load();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.org.name,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(
                    '${s.org.kindLabel} · ${s.members} socios'
                    '${s.org.isGym ? ' · ${s.trainers} entrenadores' : ''}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                    s.org.isSuspended
                        ? 'Suspendido'
                        : '${Billing.label(st)}'
                            '${s.org.paidUntil != null ? ' · hasta ${fmtDay(s.org.paidUntil!)}' : ''}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
            if (s.pendingReviews > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: billingColor(BillingState.inReview),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${s.pendingReviews} por revisar',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
      ),
    );
  }
}

/// Detalle de un cliente: comprobantes, aprobar/rechazar, suspender.
class PlatformOrgScreen extends StatefulWidget {
  final OrgSummary summary;
  const PlatformOrgScreen({super.key, required this.summary});

  @override
  State<PlatformOrgScreen> createState() => _PlatformOrgScreenState();
}

class _PlatformOrgScreenState extends State<PlatformOrgScreen> {
  List<OrgPayment> _payments = const [];
  bool _loading = true;
  late String _status = widget.summary.org.status;

  Organization get org => widget.summary.org;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await OrganizationService.payments(org.id);
      if (mounted) setState(() => _payments = p);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openReceipt(OrgPayment p) async {
    try {
      final url = await OrganizationService.receiptUrl(p.receiptPath);
      if (!mounted) return;
      if (p.receiptPath.toLowerCase().endsWith('.pdf')) {
        WebBridge.openUrl(url);
        return;
      }
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => WebBridge.openUrl(url),
                  child: const Text('Abrir en otra pestaña')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ]),
          ]),
        ),
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'No se pudo abrir el comprobante');
    }
  }

  Future<void> _review(OrgPayment p, bool approve) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Aprobar pago' : 'Marcar como pago pendiente'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            approve
                ? 'Se sumarán ${p.months} mes(es) a la suscripción.'
                : 'Escribe el motivo. El dueño lo verá en su pantalla.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLength: 500,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              labelText: approve ? 'Comentario (opcional)' : 'Motivo',
              hintText: approve ? null : 'Ej.: el monto no coincide con la cuota',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (!approve && ctrl.text.trim().length < 3) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve
                  ? billingColor(BillingState.upToDate)
                  : billingColor(BillingState.pending),
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Aprobar' : 'Pago pendiente'),
          ),
        ],
      ),
    );
    final comment = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return;
    try {
      await OrganizationService.reviewPayment(p.id,
          approve: approve, comment: comment.isEmpty ? null : comment);
      await _load();
      if (mounted) {
        AppSnackbar.success(context, approve ? 'Pago aprobado' : 'Marcado como pendiente');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  Future<void> _toggleSuspend() async {
    final next = _status == 'suspended' ? 'active' : 'suspended';
    try {
      await OrganizationService.platformSetStatus(org.id, next);
      setState(() => _status = next);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  Future<void> _ownerInvite() async {
    try {
      final token = await OrganizationService.platformOwnerInvite(org.id);
      if (!mounted) return;
      await showInviteLinkSheet(
        context,
        token: token,
        title: 'Nueva invitación de dueño',
        hint: 'Para ${org.name}. Sirve una sola vez y vence en 7 días.',
        shareText: 'Acceso de dueño para ${org.name}:',
      );
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return Scaffold(
      appBar: AppBar(title: Text(org.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(org.kindLabel.toUpperCase(),
              style: TextStyle(
                  color: AppColors.primaryText,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
          Text(s.ownerName ?? 'Sin dueño todavía',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
          if (s.ownerEmail != null)
            Text(s.ownerEmail!, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _ownerInvite,
              icon: const Icon(Icons.link),
              label: const Text('Invitación de dueño'),
            ),
            OutlinedButton.icon(
              onPressed: _toggleSuspend,
              icon: Icon(_status == 'suspended' ? Icons.play_arrow : Icons.pause),
              label: Text(_status == 'suspended' ? 'Reactivar' : 'Suspender'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: _status == 'suspended'
                      ? billingColor(BillingState.upToDate)
                      : billingColor(BillingState.pending)),
            ),
          ]),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text('Comprobantes',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_payments.isEmpty)
            Text('Aún no ha subido comprobantes.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            for (final p in _payments) _paymentCard(p),
        ],
      ),
    );
  }

  Widget _paymentCard(OrgPayment p) {
    final inReview = p.status == 'in_review';
    final color = switch (p.status) {
      'approved' => billingColor(BillingState.upToDate),
      'rejected' => billingColor(BillingState.pending),
      _ => billingColor(BillingState.inReview),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            '${p.months == 1 ? '1 mes' : '${p.months} meses'}'
            '${p.amount != null ? ' · ₡${p.amount!.toStringAsFixed(0)}' : ''}',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        Text('${p.statusLabel} · ${fmtDay(p.submittedAt)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        if (p.reviewComment != null && p.reviewComment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(p.reviewComment!, style: TextStyle(color: AppColors.textSecondary)),
          ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => _openReceipt(p),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Ver comprobante'),
          ),
          if (inReview) ...[
            ElevatedButton(
              onPressed: () => _review(p, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: billingColor(BillingState.upToDate),
                  foregroundColor: Colors.white),
              child: const Text('Aprobar'),
            ),
            OutlinedButton(
              onPressed: () => _review(p, false),
              style: OutlinedButton.styleFrom(
                  foregroundColor: billingColor(BillingState.pending)),
              child: const Text('Pago pendiente'),
            ),
          ],
        ]),
      ]),
    );
  }
}
