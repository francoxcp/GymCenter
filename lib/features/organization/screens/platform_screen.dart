import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/share_helper.dart';
import '../../../shared/web/web_bridge.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';
import '../widgets/invite_link_sheet.dart';
import 'my_organization_screen.dart' show billingColor, fmtDay;

/// Color de cada estado de cliente (un suspendido nunca va en verde).
Color clientStateColor(ClientState s) => switch (s) {
      ClientState.review => billingColor(BillingState.inReview),
      ClientState.pending => billingColor(BillingState.pending),
      ClientState.noOwner => billingColor(BillingState.inReview),
      ClientState.trial => AppColors.primaryText,
      ClientState.upToDate => billingColor(BillingState.upToDate),
      ClientState.suspended => AppColors.textSecondary,
      ClientState.internal => AppColors.textSecondary,
    };

/// Texto de invitación según el tipo de cliente.
String _inviteeLabel(Organization o) => o.isIndependent ? 'al entrenador' : 'al dueño';

/// /platform — administrador de GYMLAB: qué atender hoy, clientes y altas.
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
  String _query = '';
  bool _allTasks = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(match.first));
  }

  Future<void> _load() async {
    setState(() {
      _loading = _orgs.isEmpty;
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

  Future<void> _open(OrgSummary s) async {
    // El gimnasio interno propio se administra en "Mi gimnasio"
    if (s.isInternal &&
        s.org.id == context.read<AuthProvider>().organization?.id) {
      context.push('/admin/organization');
      return;
    }
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlatformOrgScreen(summary: s)));
    _load();
  }

  Future<void> _newClient() async {
    final created = await showNewClientSheet(context);
    if (created == null || !mounted) return;
    await _load();
    final match = _orgs.where((o) => o.org.id == created);
    if (match.isNotEmpty && mounted) _open(match.first);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clients = _orgs.where((o) => !o.isInternal).toList();
    final internal = _orgs.where((o) => o.isInternal).toList();
    final tasks = platformTasks(clients, now);
    final q = _query.trim().toLowerCase();
    final visible = clients
        .where((o) => _filter.matches(o, now))
        .where((o) =>
            q.isEmpty ||
            o.org.name.toLowerCase().contains(q) ||
            (o.ownerName ?? '').toLowerCase().contains(q))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newClient,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo cliente',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
                  children: [
                    Text('GYMLAB · PLATAFORMA',
                        style: TextStyle(
                            color: AppColors.primaryText,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Clientes',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: TextStyle(color: AppColors.error)),
                      ),
                    if (_stats != null) _revenue(_stats!),
                    const SizedBox(height: 24),
                    _tasksSection(tasks),
                    const SizedBox(height: 24),
                    _filters(clients, now),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o dueño',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final o in visible) _clientTile(o, now),
                    if (clients.isEmpty)
                      _emptyClients()
                    else if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                            q.isNotEmpty
                                ? 'Nadie coincide con "$_query".'
                                : 'Ningún cliente en "${_filter.label}".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    if (internal.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionLabel('INTERNO · NO SE COBRA'),
                      const SizedBox(height: 8),
                      for (final o in internal) _clientTile(o, now),
                    ],
                  ],
                ),
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

  Widget _sectionLabel(String t) => Text(t,
      style: TextStyle(
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.w800));

  Widget _revenue(PlatformStats st) {
    final diff = st.collectedThisMonth - st.collectedLastMonth;
    final ratio = st.expectedMonthly <= 0
        ? 0.0
        : (st.collectedThisMonth / st.expectedMonthly).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('COBRADO ESTE MES'),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(st.collectedThisMonth),
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('de ${money(st.expectedMonthly)}',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.inputFill,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
            '${diff >= 0 ? '+' : '−'}${money(diff.abs())} vs. mes pasado · '
            '${st.activeOrgs} activos · ${st.totalMembers} socios',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  // ── Para atender hoy ─────────────────────────────────────────────────
  Widget _tasksSection(List<PlatformTask> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.check_circle, color: billingColor(BillingState.upToDate)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Nada pendiente hoy: todos al día.',
                style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }
    final shown = _allTasks ? tasks : tasks.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _sectionLabel('PARA ATENDER HOY'),
        const SizedBox(width: 8),
        Text('${tasks.length}',
            style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 8),
      for (final t in shown) _taskRow(t),
      if (tasks.length > 4)
        TextButton(
          onPressed: () => setState(() => _allTasks = !_allTasks),
          child: Text(_allTasks ? 'Ver menos' : 'Ver las ${tasks.length}'),
        ),
    ]);
  }

  Widget _taskRow(PlatformTask t) {
    final (icon, action) = switch (t.kind) {
      TaskKind.review => (Icons.receipt_long, 'Revisar'),
      TaskKind.noOwner => (Icons.link, t.client.invitePending ? 'Reenviar' : 'Nueva'),
      TaskKind.pending => (Icons.payments_outlined, 'Cobrar'),
      TaskKind.expiring => (Icons.event, 'Cobrar'),
      TaskKind.inactive => (Icons.bedtime_outlined, 'Escribir'),
    };
    final color = clientStateColor(switch (t.kind) {
      TaskKind.review => ClientState.review,
      TaskKind.noOwner => ClientState.noOwner,
      TaskKind.pending => ClientState.pending,
      TaskKind.expiring => ClientState.review,
      TaskKind.inactive => ClientState.suspended,
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(t.client),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  Text(t.detail,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ),
              TextButton(
                onPressed: () => _taskAction(t),
                child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _taskAction(PlatformTask t) async {
    final c = t.client;
    switch (t.kind) {
      case TaskKind.noOwner:
        await sendOwnerInvite(context, c);
        _load();
      case TaskKind.pending:
      case TaskKind.expiring:
        final ok = await showRegisterPaymentSheet(context, c.org);
        if (ok) _load();
      case TaskKind.inactive:
        contactOwner(context, c,
            text: 'Hola ${c.ownerName?.split(' ').first ?? ''}, vi que no hay '
                'entrenos registrados en GYMLAB estos días. ¿Te ayudo con algo?');
      case TaskKind.review:
        _open(c);
    }
  }

  // ── Filtros ─────────────────────────────────────────────────────────
  Widget _filters(List<OrgSummary> clients, DateTime now) {
    final options = [
      for (final f in OrgFilter.values)
        (f, clients.where((o) => f.matches(o, now)).length),
    ].where((e) => e.$1 == OrgFilter.all || e.$2 > 0 || e.$1 == _filter);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (f, n) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                selected: _filter == f,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _filter == f ? AppColors.onPrimary : AppColors.textPrimary),
                label: Text('${f.label}  $n'),
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyClients() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tu primer cliente',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Toca "Nuevo cliente", elige gimnasio o entrenador y mándale el enlace por WhatsApp.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ]),
      );

  Widget _clientTile(OrgSummary s, DateTime now) {
    final st = s.state(now);
    final color = clientStateColor(st);
    final left = s.daysLeft(now);
    final status = switch (st) {
      ClientState.trial =>
        'En prueba${s.org.paidUntil != null ? ' hasta ${fmtDay(s.org.paidUntil!)}' : ''}',
      ClientState.upToDate =>
        'Al día${s.org.paidUntil != null ? ' hasta ${fmtDay(s.org.paidUntil!)}' : ''}',
      ClientState.pending => left != null && left < 0
          ? 'Pago pendiente · venció hace ${-left} días'
          : 'Pago pendiente',
      ClientState.noOwner => s.invitePending
          ? 'Invitación pendiente · vence ${fmtDay(s.inviteExpiresAt!)}'
          : 'Invitación vencida',
      _ => st.label,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(s),
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
                      [
                        s.org.kindLabel,
                        if (s.hasOwner && s.org.isGym) s.ownerName!,
                        '${s.members}${s.org.maxMembers != null ? '/${s.org.maxMembers}' : ''} socios',
                        if (s.org.isGym) '${s.trainers} entren.',
                      ].join(' · '),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(status,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                  if (s.hasOwner && !s.isInternal)
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

// ─────────────────────────────────────────────────────────────────────────
// Acciones compartidas (lista y ficha)
// ─────────────────────────────────────────────────────────────────────────

/// Reenvía la invitación vigente o genera una nueva si venció.
Future<void> sendOwnerInvite(BuildContext context, OrgSummary s,
    {bool forceNew = false}) async {
  try {
    final token = !forceNew && s.inviteToken != null
        ? s.inviteToken!
        : await OrganizationService.platformOwnerInvite(s.org.id);
    if (!context.mounted) return;
    await showInviteLinkSheet(
      context,
      token: token,
      title: 'Invitación para ${s.org.name}',
      hint: 'Envíasela ${_inviteeLabel(s.org)}. Sirve una sola vez y vence en 7 días.',
      shareText: 'Te doy acceso a GYMLAB para ${s.org.name}. Crea tu cuenta aquí:',
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }
}

/// WhatsApp del dueño si lo tiene; si no, correo.
void contactOwner(BuildContext context, OrgSummary s, {String text = ''}) {
  if ((s.ownerPhone ?? '').trim().isNotEmpty) {
    ShareHelper.whatsappTo(s.ownerPhone!, text);
  } else if ((s.ownerEmail ?? '').isNotEmpty) {
    WebBridge.openUrl(
        'mailto:${s.ownerEmail}?body=${Uri.encodeComponent(text)}');
  } else {
    AppSnackbar.error(context, 'Este cliente aún no tiene dueño con contacto.');
  }
}

/// Alta de cliente. Devuelve el id del cliente creado (o null).
Future<String?> showNewClientSheet(BuildContext context) async {
  final nameCtrl = TextEditingController();
  final feeCtrl = TextEditingController();
  final limitCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  var kind = 'gym';
  var trial = 14;
  String? nameError;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        Widget kindOption(String value, String title, String sub, IconData icon) {
          final sel = kind == value;
          return Expanded(
            child: Semantics(
              selected: sel,
              button: true,
              child: InkWell(
                onTap: () => set(() => kind = value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(icon, color: sel ? AppColors.onPrimary : AppColors.textSecondary),
                    const SizedBox(height: 6),
                    Text(title,
                        style: TextStyle(
                            color: sel ? AppColors.onPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.w800)),
                    Text(sub,
                        style: TextStyle(
                            color: sel
                                ? AppColors.onPrimary.withValues(alpha: 0.75)
                                : AppColors.textSecondary,
                            fontSize: 12)),
                  ]),
                ),
              ),
            ),
          );
        }

        final isGym = kind == 'gym';
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
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
                  Row(children: [
                    kindOption('gym', 'Gimnasio', 'Dueño con entrenadores',
                        Icons.storefront_outlined),
                    const SizedBox(width: 8),
                    kindOption('independent', 'Entrenador', 'Trabaja por su cuenta',
                        Icons.person_outline),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: isGym
                            ? 'Nombre del gimnasio'
                            : 'Nombre del entrenador o su marca',
                        errorText: nameError),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: isGym
                            ? 'WhatsApp del dueño (opcional)'
                            : 'WhatsApp del entrenador (opcional)',
                        helperText: 'Para mandarle la invitación directo'),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, children: [
                    for (final d in const [0, 7, 14, 30])
                      ChoiceChip(
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: trial == d
                                ? AppColors.onPrimary
                                : AppColors.textPrimary),
                        label: Text(d == 0 ? 'Sin prueba' : '$d días'),
                        selected: trial == d,
                        onSelected: (_) => set(() => trial = d),
                      ),
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().length < 2) {
                        set(() => nameError = 'Escribe al menos 2 letras');
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Crear y enviar invitación',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  final name = nameCtrl.text.trim();
  final fee = double.tryParse(feeCtrl.text.replaceAll(',', '.').trim());
  final limit = int.tryParse(limitCtrl.text.trim());
  final phone = phoneCtrl.text.trim();
  nameCtrl.dispose();
  feeCtrl.dispose();
  limitCtrl.dispose();
  phoneCtrl.dispose();
  if (ok != true || !context.mounted) return null;
  try {
    final created = await OrganizationService.platformCreateOrgWithId(
        name: name, kind: kind, monthlyFee: fee, trialDays: trial, maxMembers: limit);
    if (!context.mounted) return created.orgId;
    await showInviteLinkSheet(
      context,
      token: created.token,
      title: 'Invitación para $name',
      hint: 'Envíasela ${kind == 'gym' ? 'al dueño' : 'al entrenador'}. '
          'Sirve una sola vez y vence en 7 días.',
      shareText: 'Te doy acceso a GYMLAB para $name. Crea tu cuenta aquí:',
      phone: phone.isEmpty ? null : phone,
    );
    return created.orgId;
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
    return null;
  }
}

/// Registrar un pago en efectivo, SINPE o transferencia. true = registrado.
Future<bool> showRegisterPaymentSheet(BuildContext context, Organization org) async {
  var months = 1;
  final amountCtrl = TextEditingController(
      text: org.monthlyFee == null || org.monthlyFee == 0
          ? ''
          : org.monthlyFee!.toStringAsFixed(0));
  final noteCtrl = TextEditingController();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Registrar pago',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${org.name} · efectivo, SINPE o transferencia',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: Text('Meses',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15))),
                  IconButton(
                      tooltip: 'Menos meses',
                      onPressed: () => set(() {
                            months = (months - 1).clamp(1, 12);
                            if (org.monthlyFee != null && org.monthlyFee! > 0) {
                              amountCtrl.text = (org.monthlyFee! * months).toStringAsFixed(0);
                            }
                          }),
                      icon: const Icon(Icons.remove_circle_outline)),
                  SizedBox(
                    width: 56,
                    child: Text('$months',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                      tooltip: 'Más meses',
                      onPressed: () => set(() {
                            months = (months + 1).clamp(1, 12);
                            if (org.monthlyFee != null && org.monthlyFee! > 0) {
                              amountCtrl.text = (org.monthlyFee! * months).toStringAsFixed(0);
                            }
                          }),
                      icon: Icon(Icons.add_circle_outline, color: AppColors.primaryText)),
                ]),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto recibido', prefixText: '₡ '),
                ),
                TextField(
                  controller: noteCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(
                      labelText: 'Nota (opcional)', hintText: 'Ej.: SINPE del 9 nov'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text('Registrar $months ${months == 1 ? 'mes' : 'meses'}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.').trim());
  final note = noteCtrl.text.trim();
  amountCtrl.dispose();
  noteCtrl.dispose();
  if (ok != true || !context.mounted) return false;
  try {
    final until = await OrganizationService.platformRegisterPayment(org.id,
        months: months, amount: amount, note: note.isEmpty ? null : note);
    if (context.mounted) {
      AppSnackbar.success(context,
          until == null ? 'Pago registrado' : 'Pago registrado · al día hasta el ${fmtDay(until)}');
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ficha del cliente
// ─────────────────────────────────────────────────────────────────────────

/// Detalle de un cliente: estado, cobro, contacto, equipo y comprobantes.
class PlatformOrgScreen extends StatefulWidget {
  final OrgSummary summary;
  const PlatformOrgScreen({super.key, required this.summary});

  @override
  State<PlatformOrgScreen> createState() => _PlatformOrgScreenState();
}

class _PlatformOrgScreenState extends State<PlatformOrgScreen> {
  late OrgSummary s = widget.summary;
  List<OrgPayment> _payments = const [];
  List<TeamMember> _team = const [];
  bool _loading = true;

  Organization get org => s.org;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        OrganizationService.payments(org.id),
        OrganizationService.platformOrgTeam(org.id),
        OrganizationService.platformList(),
      ]);
      if (!mounted) return;
      final fresh = (r[2] as List<OrgSummary>).where((o) => o.org.id == org.id);
      setState(() {
        _payments = r[0] as List<OrgPayment>;
        _team = r[1] as List<TeamMember>;
        if (fresh.isNotEmpty) s = fresh.first;
      });
    } catch (_) {
      // Sin conexión: se mantiene lo recibido
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
    final suspending = !org.isSuspended;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspending ? 'Suspender ${org.name}' : 'Reactivar ${org.name}'),
        content: Text(
          suspending
              ? 'Su dueño, sus entrenadores y sus socios dejarán de usar la app hasta que lo reactives. '
                  'El dueño solo verá la pantalla para pagar. No se borra nada.'
              : 'Todos vuelven a entrar normalmente.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: suspending
                  ? billingColor(BillingState.pending)
                  : billingColor(BillingState.upToDate),
              foregroundColor: Colors.white,
            ),
            child: Text(suspending ? 'Suspender' : 'Reactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OrganizationService.platformSetStatus(
          org.id, suspending ? 'suspended' : 'active');
      await _load();
      if (mounted) {
        AppSnackbar.success(context, suspending ? 'Cliente suspendido' : 'Cliente reactivado');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  Future<void> _extend() async {
    final days = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Dar más días',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Sin cobrar: para extender la prueba o dar tiempo para pagar.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(children: [
              for (final d in const [7, 14, 30]) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, d),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text('+$d días', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                if (d != 30) const SizedBox(width: 8),
              ],
            ]),
          ]),
        ),
      ),
    );
    if (days == null) return;
    try {
      final until = await OrganizationService.platformExtendDays(org.id, days);
      await _load();
      if (mounted) {
        AppSnackbar.success(context,
            until == null ? '+$days días' : 'Activo hasta el ${fmtDay(until)}');
      }
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
      await _load();
      if (mounted) AppSnackbar.success(context, 'Plan actualizado');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, OrganizationService.friendlyError(e));
    }
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
          fontSize: 12,
          fontWeight: FontWeight.w800));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _fact(String value, String label, {Color? color}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      );

  Widget _billingCard(DateTime now) {
    final left = s.daysLeft(now);
    final leftText = left == null
        ? 'Sin fecha'
        : left < 0
            ? 'Venció hace ${-left} días'
            : left == 0
                ? 'Vence hoy'
                : 'Quedan $left días';
    final leftColor = left == null
        ? null
        : left < 0
            ? billingColor(BillingState.pending)
            : left <= 7
                ? billingColor(BillingState.inReview)
                : null;
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _label(s.inTrial ? 'PRUEBA GRATIS' : 'SUSCRIPCIÓN')),
          IconButton(
            tooltip: 'Editar plan y límite',
            onPressed: _editPlan,
            icon: Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        Text(org.paidUntil == null ? '—' : 'Hasta el ${fmtDay(org.paidUntil!)}',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(leftText,
            style: TextStyle(
                color: leftColor ?? AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: [
          _fact(
              org.monthlyFee == null || org.monthlyFee == 0
                  ? 'Gratis'
                  : _PlatformScreenState.money(org.monthlyFee!),
              'cuota / mes'),
          _fact(org.plan, 'plan'),
          _fact('${s.members}${org.maxMembers != null ? '/${org.maxMembers}' : ''}', 'socios'),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                if (await showRegisterPaymentSheet(context, org)) _load();
              },
              child: const Text('Registrar pago', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: _extend,
              child: const Text('Dar más días'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _ownerCard() {
    if (!s.hasOwner) {
      return _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(org.isIndependent ? 'ENTRENADOR' : 'DUEÑO'),
          const SizedBox(height: 4),
          Text(
              s.invitePending
                  ? 'Todavía no aceptó la invitación'
                  : 'La invitación venció',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          if (s.invitePending)
            Text('Vence el ${fmtDay(s.inviteExpiresAt!)}',
                style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton.icon(
              onPressed: () async {
                await sendOwnerInvite(context, s);
                _load();
              },
              icon: const Icon(Icons.send),
              label: Text(s.invitePending ? 'Reenviar invitación' : 'Enviar nueva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
            if (s.invitePending)
              TextButton(
                onPressed: () async {
                  await sendOwnerInvite(context, s, forceNew: true);
                  _load();
                },
                child: const Text('Generar otra'),
              ),
          ]),
        ]),
      );
    }
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(org.isIndependent ? 'ENTRENADOR' : 'DUEÑO'),
        const SizedBox(height: 4),
        Text(s.ownerName!,
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        if (s.ownerEmail != null)
          Text(s.ownerEmail!, style: TextStyle(color: AppColors.textSecondary)),
        if ((s.ownerPhone ?? '').isNotEmpty)
          Text(s.ownerPhone!, style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if ((s.ownerPhone ?? '').isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => ShareHelper.whatsappTo(
                  s.ownerPhone!, 'Hola ${s.ownerName!.split(' ').first}, '),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp'),
            ),
          if (s.ownerEmail != null)
            OutlinedButton.icon(
              onPressed: () => WebBridge.openUrl('mailto:${s.ownerEmail}'),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Correo'),
            ),
        ]),
      ]),
    );
  }

  Widget _teamCard() {
    final trainers = _team.where((t) => t.role == 'trainer').toList();
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('ENTRENADORES · ${trainers.length}'),
        const SizedBox(height: 8),
        if (trainers.isEmpty)
          Text('Aún no invitó entrenadores.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          for (final t in trainers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    if (t.email != null)
                      Text(t.email!,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ),
                Text('${t.members}',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Text('socios', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
      ]),
    );
  }

  Widget _usageCard() => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(s.createdAt == null
              ? 'USO'
              : 'CLIENTE DESDE ${fmtDay(s.createdAt!).toUpperCase()}'),
          const SizedBox(height: 10),
          Row(children: [
            _fact('${s.members}', 'socios'),
            _fact('${s.sessions30d}', 'entrenos 30 d'),
            _fact('${_payments.where((p) => p.status == 'approved').length}', 'pagos'),
          ]),
          const SizedBox(height: 8),
          Text(activityLabel(s).split(' · ').first,
              style: TextStyle(
                  // En rojo solo si ya tiene dueño y lleva 14+ días sin uso
                  color: s.hasOwner && (s.daysSinceActivity(DateTime.now()) ?? 999) >= 14
                      ? billingColor(BillingState.pending)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final st = s.state(now);
    final reviews = _payments.where((p) => p.status == 'in_review').toList();
    final history = _payments.where((p) => p.status != 'in_review').toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(org.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(org.kindLabel.toUpperCase(),
                style: TextStyle(
                    color: AppColors.primaryText,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: clientStateColor(st), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(st.label,
                  style: TextStyle(
                      color: clientStateColor(st), fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 16),
            // Comprobantes por revisar: lo primero que hay que resolver
            if (reviews.isNotEmpty) ...[
              _label('POR REVISAR'),
              const SizedBox(height: 8),
              for (final p in reviews) _paymentCard(p),
              const SizedBox(height: 8),
            ],
            _billingCard(now),
            const SizedBox(height: 12),
            _ownerCard(),
            if (org.isGym && s.hasOwner) ...[
              const SizedBox(height: 12),
              _teamCard(),
            ],
            const SizedBox(height: 12),
            _usageCard(),
            const SizedBox(height: 24),
            _label('PAGOS'),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (history.isEmpty)
              Text('Todavía no hay pagos.', style: TextStyle(color: AppColors.textSecondary))
            else
              for (final p in history) _paymentCard(p),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _toggleSuspend,
              icon: Icon(org.isSuspended ? Icons.play_arrow : Icons.pause),
              label: Text(org.isSuspended ? 'Reactivar cliente' : 'Suspender cliente'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: org.isSuspended
                    ? billingColor(BillingState.upToDate)
                    : billingColor(BillingState.pending),
              ),
            ),
          ],
        ),
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
            '${p.amount != null ? ' · ${_PlatformScreenState.money(p.amount!)}' : ''}',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(
            '${p.isManual ? 'Registrado a mano' : p.statusLabel} · ${fmtDay(p.submittedAt)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        if (p.reviewComment != null && p.reviewComment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(p.reviewComment!, style: TextStyle(color: AppColors.textSecondary)),
          ),
        if (!p.isManual) ...[
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
        ],
      ]),
    );
  }
}
