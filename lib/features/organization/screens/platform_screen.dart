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
  /// Cliente a abrir directamente (aviso "Comprobante por revisar").
  final String? openOrgId;
  const PlatformScreen({super.key, this.openOrgId});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  List<OrgSummary> _orgs = const [];
  PlatformStats? _stats;
  bool _loading = true;
  String? _error;
  OrgFilter _filter = OrgFilter.all;
  String? _pendingOpen;

  @override
  void initState() {
    super.initState();
    _pendingOpen = widget.openOrgId;
    _load();
  }

  void _openPending() {
    final id = _pendingOpen;
    if (id == null) return;
    _pendingOpen = null;
    final match = _orgs.where((o) => o.org.id == id);
    if (match.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlatformOrgScreen(summary: match.first)));
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        OrganizationService.platformList(),
        OrganizationService.platformStats(),
      ]);
      if (mounted) {
        setState(() {
          _orgs = r[0] as List<OrgSummary>;
          _stats = r[1] as PlatformStats?;
        });
        _openPending();
      }
    } catch (e) {
      if (mounted) setState(() => _error = OrganizationService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newClient() async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
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
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Máximo de socios (vacío = sin límite)'),
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
    final limit = int.tryParse(limitCtrl.text.trim());
    nameCtrl.dispose();
    feeCtrl.dispose();
    limitCtrl.dispose();
    if (ok != true) return;
    try {
      final token = await OrganizationService.platformCreateOrg(
          name: name, kind: kind, monthlyFee: fee, trialDays: trial, maxMembers: limit);
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
                  if (_stats != null) _revenue(_stats!),
                  const SizedBox(height: 20),
                  Row(children: [
                    _bigStat('${_orgs.length}', 'clientes'),
                    _bigStat('$pending', 'por revisar',
                        color: pending > 0 ? billingColor(BillingState.inReview) : null),
                    _bigStat(
                        '${_orgs.where((o) => Billing.state(o.org) == BillingState.pending).length}',
                        'pendientes',
                        color: billingColor(BillingState.pending)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final f in OrgFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              selected: _filter == f,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _filter == f
                                      ? AppColors.onPrimary
                                      : AppColors.textPrimary),
                              label: Text(
                                  '${f.label}  ${_orgs.where((o) => f.matches(o, DateTime.now())).length}'),
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final o in _orgs.where((o) => _filter.matches(o, DateTime.now())))
                    _orgTile(o),
                  if (_orgs.isNotEmpty &&
                      !_orgs.any((o) => _filter.matches(o, DateTime.now())))
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Ningún cliente en "${_filter.label}".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                ],
              ),
      ),
    );
  }

  static String money(double v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '₡$b';
  }

  Widget _revenue(PlatformStats st) {
    final diff = st.collectedThisMonth - st.collectedLastMonth;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COBRADO ESTE MES',
            style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(money(st.collectedThisMonth),
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 40, fontWeight: FontWeight.w900)),
        Text(
            '${diff >= 0 ? '+' : '−'}${money(diff.abs())} vs. mes pasado · '
            'esperado ${money(st.expectedMonthly)}/mes',
            style: TextStyle(
                color: diff >= 0
                    ? billingColor(BillingState.upToDate)
                    : billingColor(BillingState.pending),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Wrap(spacing: 18, runSpacing: 8, children: [
          _mini('${st.activeOrgs}', 'activos'),
          _mini('${st.inTrial}', 'en prueba'),
          _mini('${st.expiring7d}', 'vencen en 7 días',
              color: st.expiring7d > 0 ? billingColor(BillingState.inReview) : null),
          _mini('${st.suspended}', 'suspendidos'),
          _mini('${st.totalMembers}', 'socios en total'),
        ]),
      ]),
    );
  }

  Widget _mini(String v, String l, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(l, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      );

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
                    '${s.org.kindLabel} · ${s.members}${s.org.maxMembers != null ? '/${s.org.maxMembers}' : ''} socios'
                    '${s.org.isGym ? ' · ${s.trainers} entrenadores' : ''}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                    s.org.isSuspended
                        ? 'Suspendido'
                        : s.inTrial
                        ? 'En prueba${s.org.paidUntil != null ? ' hasta ${fmtDay(s.org.paidUntil!)}' : ''}'
                        : '${Billing.label(st)}'
                            '${s.org.paidUntil != null ? ' · hasta ${fmtDay(s.org.paidUntil!)}' : ''}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(activityLabel(s),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

/// "Último entreno hace 3 días · 42 entrenos en 30 días".
String activityLabel(OrgSummary s, {DateTime? now}) {
  final d = s.daysSinceActivity(now ?? DateTime.now());
  final last = d == null
      ? 'Sin entrenos aún'
      : d == 0
          ? 'Entrenaron hoy'
          : d == 1
              ? 'Último entreno ayer'
              : 'Último entreno hace $d días';
  return '$last · ${s.sessions30d} en 30 días';
}

/// Acceso para pruebas al formato de dinero.
class PlatformScreenTestable {
  PlatformScreenTestable._();
  static String money(double v) => _PlatformScreenState.money(v);
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

  Future<void> _editPlan() async {
    final planCtrl = TextEditingController(text: org.plan);
    final feeCtrl = TextEditingController(
        text: org.monthlyFee == null ? '' : org.monthlyFee!.toStringAsFixed(0));
    final limitCtrl = TextEditingController(text: org.maxMembers?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan y límite'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: planCtrl, decoration: const InputDecoration(labelText: 'Plan')),
          TextField(
            controller: feeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cuota mensual', prefixText: '₡ '),
          ),
          TextField(
            controller: limitCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Máximo de socios (vacío = sin límite)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    final plan = planCtrl.text.trim();
    final fee = double.tryParse(feeCtrl.text.replaceAll(',', '.').trim());
    final limit = int.tryParse(limitCtrl.text.trim());
    planCtrl.dispose();
    feeCtrl.dispose();
    limitCtrl.dispose();
    if (ok != true) return;
    try {
      await OrganizationService.platformUpdateOrg(org.id,
          plan: plan.isEmpty ? 'Mensual' : plan, monthlyFee: fee, maxMembers: limit);
      if (mounted) AppSnackbar.success(context, 'Plan actualizado');
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

  Widget _history(OrgSummary s) {
    final approved = _payments.where((p) => p.status == 'approved').toList();
    Widget cell(String v, String l) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            Text(l, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            s.createdAt == null
                ? 'HISTORIAL'
                : 'CLIENTE DESDE ${fmtDay(s.createdAt!).toUpperCase()}',
            style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          cell('${s.members}', 'socios'),
          cell('${s.sessions30d}', 'entrenos 30 d'),
          cell('${approved.length}', 'pagos aprobados'),
        ]),
        const SizedBox(height: 8),
        Text(activityLabel(s).split(' · ').first,
            style: TextStyle(
                color: (s.daysSinceActivity(DateTime.now()) ?? 999) >= 14
                    ? billingColor(BillingState.pending)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
      ]),
    );
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
              onPressed: _editPlan,
              icon: const Icon(Icons.tune),
              label: const Text('Plan y límite'),
            ),
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
          const SizedBox(height: 20),
          _history(s),
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
          if (p.receiptDeleted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Comprobante archivado (se borró por antigüedad)',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
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
