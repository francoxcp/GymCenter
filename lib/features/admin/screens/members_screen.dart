import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_actions.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/chat_service.dart';
import '../../organization/widgets/invite_flow.dart';
import '../../profile/providers/user_provider.dart';
import '../models/member_status.dart';
import '../services/member_status_service.dart';
import '../widgets/membership_card.dart';
import 'member_hub_screen.dart';

/// Filtros de la lista unificada de socios.
enum MembersFilter { all, upToDate, expiring, expired, absent, noTrainer }

extension MembersFilterX on MembersFilter {
  String get label => switch (this) {
        MembersFilter.all => 'Todos',
        MembersFilter.upToDate => 'Al día',
        MembersFilter.expiring => 'Por vencer',
        MembersFilter.expired => 'Vencidas',
        MembersFilter.absent => 'Sin venir',
        MembersFilter.noTrainer => 'Sin entrenador',
      };

  static MembersFilter? parse(String? s) => switch (s) {
        'al-dia' => MembersFilter.upToDate,
        'por-vencer' => MembersFilter.expiring,
        'vencidas' => MembersFilter.expired,
        'sin-venir' => MembersFilter.absent,
        'sin-entrenador' => MembersFilter.noTrainer,
        _ => null,
      };

  bool matches(User u, MemberStatus? s) => switch (this) {
        MembersFilter.all => true,
        MembersFilter.upToDate => u.membershipStatus == MembershipStatus.active,
        MembersFilter.expiring =>
          u.membershipStatus == MembershipStatus.expiring,
        MembersFilter.expired => u.membershipStatus == MembershipStatus.expired,
        MembersFilter.absent => s?.light == MemberLight.red,
        MembersFilter.noTrainer => u.trainerId == null,
      };
}

/// Socios: una sola lista con filtros, cobro rápido e invitar.
class MembersScreen extends StatefulWidget {
  final String? initialFilter;
  const MembersScreen({super.key, this.initialFilter});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  late MembersFilter _filter;
  String _query = '';
  MembersSnapshot _snap = MembersSnapshot.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _filter = MembersFilterX.parse(widget.initialFilter) ?? MembersFilter.all;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final up = context.read<UserProvider>();
    setState(() => _loading = true);
    try {
      await up.loadUsers();
      final members = up.users.where((u) => u.role == 'user').toList();
      final snap = await MemberStatusService.load(members);
      if (mounted) setState(() => _snap = snap);
    } catch (_) {
      // La lista sigue con lo que haya en memoria.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isAdmin;
    final showNoTrainer = isOwner && !auth.isIndependent;
    final members = context
        .watch<UserProvider>()
        .users
        .where((u) => u.role == 'user')
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final q = foldText(_query);
    final searched = q.isEmpty
        ? members
        : members
            .where((u) =>
                foldText(u.name).contains(q) || foldText(u.email).contains(q))
            .toList();
    final filters = MembersFilter.values
        .where((f) => f != MembersFilter.noTrainer || showNoTrainer)
        .toList();
    int countOf(MembersFilter f) =>
        searched.where((u) => f.matches(u, _snap.status[u.id])).length;
    final list =
        searched.where((u) => _filter.matches(u, _snap.status[u.id])).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invite-members',
        onPressed: () => startInviteFlow(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Invitar',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: '${members.length}',
                              style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1)),
                            TextSpan(
                              text: members.length == 1 ? '  socio' : '  socios',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                      // Dueño que también entrena socios: acceso a sus chats
                      if (isOwner &&
                          members.any((u) => u.trainerId == auth.currentUser?.id))
                        ValueListenableBuilder<int>(
                          valueListenable: ChatService.unread,
                          builder: (_, n, __) => IconButton(
                            tooltip: 'Chats',
                            onPressed: () => context.push('/chats'),
                            icon: Badge(
                              isLabelVisible: n > 0,
                              label: Text(n > 9 ? '9+' : '$n'),
                              backgroundColor: AppColors.primary,
                              textColor: AppColors.onPrimary,
                              child: Icon(Icons.chat_bubble_outline,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      const TopActions(),
                      PopupMenuButton<String>(
                        tooltip: 'Más',
                        icon: Icon(Icons.more_vert,
                            color: AppColors.textPrimary),
                        onSelected: (v) => context.push(v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: '/admin/users',
                              child: Text('Alta manual y roles')),
                          if (isOwner)
                            const PopupMenuItem(
                                value: '/admin/memberships',
                                child: Text('Historial de membresías')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o correo',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.inputFill,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final f in filters)
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
                            label: Text('${f.label}  ${countOf(f)}'),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_loading && members.isEmpty)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    noMembers: members.isEmpty,
                    filter: _filter,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => _MemberRow(
                      member: list[i],
                      status: _snap.status[list[i].id],
                      canCharge: isOwner,
                      onChanged: _reload,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final User member;
  final MemberStatus? status;
  final bool canCharge;
  final VoidCallback onChanged;
  const _MemberRow({
    required this.member,
    required this.status,
    required this.canCharge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = status;
    final light = s == null
        ? AppColors.textSecondary
        : memberLightColor(s.light);
    final days = s?.daysSinceLast(DateTime.now());
    final attendance = s == null
        ? ''
        : days == null
            ? (s.light == MemberLight.fresh
                ? 'Nuevo · aún no entrena'
                : 'Nunca ha entrenado')
            : days == 0
                ? 'Entrenó hoy'
                : 'Hace $days días';
    final ms = member.membershipStatus;
    final msColor = membershipColor(ms);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: light, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 14, right: 4),
        onTap: () async {
          final st = s ??
              MemberStatus.compute(
                  userId: member.id,
                  plannedPerWeek: 0,
                  sessions: const [],
                  now: DateTime.now(),
                  joinedAt: member.createdAt);
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MemberHubScreen(member: member, status: st)));
          onChanged();
        },
        title: Text(member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        subtitle: Text.rich(
          TextSpan(children: [
            if (ms != MembershipStatus.none)
              TextSpan(
                  text: Membership.label(member.membershipEnd),
                  style: TextStyle(
                      color: msColor, fontWeight: FontWeight.w600)),
            if (ms != MembershipStatus.none && attendance.isNotEmpty)
              const TextSpan(text: '  ·  '),
            TextSpan(text: attendance),
          ]),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: canCharge
            ? IconButton(
                tooltip: 'Registrar pago de ${member.name}',
                icon: Icon(Icons.payments_outlined,
                    color: ms == MembershipStatus.active
                        ? AppColors.textSecondary
                        : AppColors.primaryText),
                onPressed: () async {
                  await showRenewMembershipDialog(context, member);
                  onChanged();
                },
              )
            : Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool noMembers;
  final MembersFilter filter;
  const _EmptyState({required this.noMembers, required this.filter});

  @override
  Widget build(BuildContext context) {
    final (title, body) = noMembers
        ? (
            'La sala está vacía',
            'Toca Invitar y manda el enlace por WhatsApp, o muestra el QR en recepción.'
          )
        : switch (filter) {
            MembersFilter.expired => ('Nadie vencido', 'Todas las membresías están al día.'),
            MembersFilter.expiring => ('Nada por vencer', 'Ninguna membresía vence esta semana.'),
            MembersFilter.absent => ('Todos vienen', 'Nadie lleva 7 días o más sin entrenar.'),
            MembersFilter.noTrainer => ('Todos tienen entrenador', 'Cada socio ya tiene a alguien asignado.'),
            _ => ('Sin resultados', 'Prueba con otro nombre o filtro.'),
          };
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 120),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
