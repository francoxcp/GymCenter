import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/navigation/safe_pop.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/user_provider.dart';
import '../widgets/membership_card.dart';

/// Membresías de los socios agrupadas por estado. El dueño registra pagos
/// con un toque; el entrenador solo consulta.
class MembershipsScreen extends StatefulWidget {
  const MembershipsScreen({super.key});

  @override
  State<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends State<MembershipsScreen> {
  MembershipStatus _tab = MembershipStatus.expiring;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<UserProvider>().loadUsers());
  }

  static const _labels = {
    MembershipStatus.expiring: 'Por vencer',
    MembershipStatus.expired: 'Vencidas',
    MembershipStatus.none: 'Sin registrar',
    MembershipStatus.active: 'Al día',
  };

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    final provider = context.watch<UserProvider>();
    final members = provider.users.where((u) => u.role == 'user').toList();
    final groups = {
      for (final s in _labels.keys)
        s: members.where((u) => u.membershipStatus == s).toList()
          ..sort((a, b) => (a.membershipEnd ?? DateTime(2100))
              .compareTo(b.membershipEnd ?? DateTime(2100))),
    };
    final list = groups[_tab]!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Atrás',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/admin'),
        ),
        title: const Text('Membresías'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadUsers,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _labels.entries)
                  ChoiceChip(
                    label: Text('${e.value} (${groups[e.key]!.length})'),
                    selected: _tab == e.key,
                    selectedColor: membershipColor(e.key),
                    labelStyle: TextStyle(
                        color: _tab == e.key ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _tab = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.isLoading && members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  switch (_tab) {
                    MembershipStatus.expiring =>
                      'Nadie vence en los próximos 7 días 🎉',
                    MembershipStatus.expired => 'No hay membresías vencidas.',
                    MembershipStatus.none =>
                      'Todos los socios tienen membresía registrada.',
                    MembershipStatus.active => 'Aún no hay socios al día.',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              for (final u in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: CircleAvatar(
                      backgroundColor:
                          membershipColor(u.membershipStatus).withValues(alpha: 0.2),
                      child: Icon(Icons.card_membership,
                          color: membershipColor(u.membershipStatus)),
                    ),
                    title: Text(u.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      u.membershipEnd == null
                          ? 'Sin membresía'
                          : '${u.membershipPlan ?? ''} · ${Membership.label(u.membershipEnd)} (${fmtDate(u.membershipEnd!)})',
                      style: TextStyle(
                          color: membershipColor(u.membershipStatus)),
                    ),
                    trailing: isOwner
                        ? const Icon(Icons.payments_outlined,
                            color: AppColors.primary)
                        : null,
                    onTap: isOwner
                        ? () => showRenewMembershipDialog(context, u)
                        : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Aviso para el socio cuando su membresía está por vencer o vencida.
class MyMembershipBanner extends StatelessWidget {
  const MyMembershipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    if (me == null || me.isStaff) return const SizedBox.shrink();
    final s = me.membershipStatus;
    if (s != MembershipStatus.expiring && s != MembershipStatus.expired) {
      return const SizedBox.shrink();
    }
    final color = membershipColor(s);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(children: [
          Icon(Icons.card_membership, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s == MembershipStatus.expired
                  ? 'Tu membresía venció. Renueva en recepción para seguir entrenando.'
                  : 'Tu membresía: ${Membership.label(me.membershipEnd).toLowerCase()}. Renueva en recepción.',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Alerta en el panel del dueño: membresías por vencer y vencidas.
class MembershipsAlertCard extends StatelessWidget {
  const MembershipsAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().currentUser?.isAdmin ?? false;
    if (!isOwner) return const SizedBox.shrink();
    final members =
        context.watch<UserProvider>().users.where((u) => u.role == 'user');
    final expiring = members
        .where((u) => u.membershipStatus == MembershipStatus.expiring)
        .length;
    final expired = members
        .where((u) => u.membershipStatus == MembershipStatus.expired)
        .length;
    if (expiring == 0 && expired == 0) return const SizedBox.shrink();
    final color = expired > 0
        ? membershipColor(MembershipStatus.expired)
        : membershipColor(MembershipStatus.expiring);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => GoRouter.of(context).push('/admin/memberships'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  [
                    if (expiring > 0)
                      '$expiring por vencer esta semana',
                    if (expired > 0) '$expired vencida${expired == 1 ? '' : 's'}',
                  ].join(' · '),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ]),
          ),
        ),
      ),
    );
  }
}
