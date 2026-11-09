import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/share_helper.dart';
import '../../../shared/widgets/top_actions.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../organization/widgets/invite_flow.dart';
import '../../profile/providers/user_provider.dart';
import '../../social/activity_service.dart';
import '../../chat/chat_service.dart';
import '../../social/comments_sheet.dart';
import '../models/member_status.dart';
import '../services/member_status_service.dart';
import 'member_hub_screen.dart';

const quickReplies = ['¡Buen trabajo!', 'Sube peso la próxima', 'Cuida la técnica'];

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre'
];
const _weekdays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
];

/// "Hoy" del entrenador: quién entrenó (con respuesta rápida), quién falta
/// y el total de la semana.
class TrainerTodayScreen extends StatefulWidget {
  const TrainerTodayScreen({super.key});

  @override
  State<TrainerTodayScreen> createState() => _TrainerTodayScreenState();
}

class _TrainerTodayScreenState extends State<TrainerTodayScreen> {
  MembersSnapshot _snap = MembersSnapshot.empty;
  List<FeedItem> _today = [];
  final Set<String> _replied = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final up = context.read<UserProvider>();
    setState(() => _loading = true);
    try {
      await up.loadUsers();
      final members = up.users.where((u) => u.role == 'user').toList();
      final results = await Future.wait([
        MemberStatusService.load(members),
        ActivityService.loadFeed(limit: 40),
      ]);
      final now = DateTime.now();
      final feed = (results[1] as List<FeedItem>).where((f) {
        final d = f.completedAt.toLocal();
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).toList();
      if (!mounted) return;
      setState(() {
        _snap = results[0] as MembersSnapshot;
        _today = feed;
      });
    } catch (_) {
      // Se muestra lo que haya.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Socio que entrena conmigo → la respuesta va a nuestro chat (con la
  /// referencia al entreno). Si no es mío, queda como comentario del entreno.
  bool _isMine(FeedItem f) {
    final me = context.read<AuthProvider>().currentUser?.id;
    final members = context.read<UserProvider>().users.where((u) => u.id == f.userId);
    return me != null && members.isNotEmpty && members.first.trainerId == me;
  }

  Future<void> _reply(FeedItem f, String text) async {
    try {
      if (_isMine(f)) {
        await ChatService.send(
          memberId: f.userId,
          trainerId: context.read<AuthProvider>().currentUser!.id,
          body: text,
          sessionId: f.sessionId,
        );
      } else {
        await ActivityService.addComment(f.sessionId, text);
      }
      if (!mounted) return;
      setState(() => _replied.add(f.sessionId));
      ShareHelper.showToast(context, 'Enviado a ${f.userName.split(' ').first}');
    } catch (_) {
      if (mounted) ShareHelper.showToast(context, 'No se pudo enviar');
    }
  }

  void _openConversation(FeedItem f) {
    if (_isMine(f)) {
      context.push('/chats/${f.userId}');
    } else {
      showCommentsSheet(context,
          sessionId: f.sessionId, title: f.userName, showQuickReplies: true);
    }
  }

  void _openMember(User u) {
    final s = _snap.status[u.id] ??
        MemberStatus.compute(
            userId: u.id, plannedPerWeek: 0, sessions: const [], now: DateTime.now());
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => MemberHubScreen(member: u, status: s)))
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final first = (auth.currentUser?.name ?? '').split(' ').first;
    final members = context
        .watch<UserProvider>()
        .users
        .where((u) => u.role == 'user')
        .toList();
    final byId = {for (final m in members) m.id: m};
    final absent = members
        .where((u) => _snap.status[u.id]?.light == MemberLight.red)
        .toList()
      ..sort((a, b) {
        final da = _snap.status[a.id]?.daysSinceLast(DateTime.now()) ?? 9999;
        final db = _snap.status[b.id]?.daysSinceLast(DateTime.now()) ?? 9999;
        return db.compareTo(da);
      });
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_weekdays[now.weekday - 1]} ${now.day} de ${_months[now.month - 1]}'
                          .toUpperCase(),
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2),
                    ),
                  ),
                  const TopActions(),
                ],
              ),
              Text(first.isEmpty ? 'Hoy' : 'Hoy, $first',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _BigStat(value: '${_snap.trainedToday.length}', label: 'entrenaron\nhoy', accent: true),
                  _BigStat(value: '${absent.length}', label: 'sin venir\n7+ días'),
                  _BigStat(value: '${_snap.sessionsThisWeek}', label: 'entrenos\nesta semana'),
                ],
              ),
              const SizedBox(height: 28),
              _SectionTitle('ENTRENARON HOY',
                  trailing: TextButton(
                      onPressed: () => context.push('/admin/activity'),
                      child: const Text('Ver actividad'))),
              if (_loading && _today.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()))
              else if (_today.isEmpty)
                _Hint(members.isEmpty
                    ? 'Aún no tienes socios. Invítalos con un enlace o un QR.'
                    : 'Nadie ha entrenado todavía. Cuando terminen una rutina aparecen aquí para que les respondas.')
              else
                for (final f in _today)
                  _TrainedCard(
                    item: f,
                    replied: _replied.contains(f.sessionId),
                    onReply: (t) => _reply(f, t),
                    onMore: () => _openConversation(f),
                    onOpen: byId[f.userId] == null
                        ? null
                        : () => _openMember(byId[f.userId]!),
                  ),
              if (members.isEmpty && !_loading) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => startInviteFlow(context),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Invitar socios',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
              if (absent.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionTitle('LES TOCA UN MENSAJE',
                    trailing: TextButton(
                        onPressed: () => context.go('/admin/members?f=sin-venir'),
                        child: const Text('Ver todos'))),
                for (final u in absent.take(6))
                  _AbsentRow(
                    member: u,
                    days: _snap.status[u.id]?.daysSinceLast(now),
                    onOpen: () => _openMember(u),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  const _BigStat({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: accent ? AppColors.primaryText : AppColors.textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.25)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
      );
}

class _TrainedCard extends StatelessWidget {
  final FeedItem item;
  final bool replied;
  final ValueChanged<String> onReply;
  final VoidCallback onMore;
  final VoidCallback? onOpen;
  const _TrainedCard({
    required this.item,
    required this.replied,
    required this.onReply,
    required this.onMore,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.completedAt.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName,
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('${item.workoutName} · $hh:$mm',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (item.volumeKg > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${item.volumeKg.round()} kg',
                        style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (replied)
            Row(children: [
              Icon(Icons.check, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text('Respondido',
                  style: TextStyle(color: AppColors.success, fontSize: 13)),
              const Spacer(),
              TextButton(onPressed: onMore, child: const Text('Ver chat')),
            ])
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in quickReplies)
                  ActionChip(
                    label: Text(r, style: const TextStyle(fontSize: 12)),
                    onPressed: () => onReply(r),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit, size: 14),
                  label: Text(
                      item.commentCount > 0
                          ? 'Escribir (${item.commentCount})'
                          : 'Escribir',
                      style: const TextStyle(fontSize: 12)),
                  onPressed: onMore,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AbsentRow extends StatelessWidget {
  final User member;
  final int? days;
  final VoidCallback onOpen;
  const _AbsentRow({required this.member, required this.days, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final first = member.name.split(' ').first;
    final hasPhone = (member.phone ?? '').isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onOpen,
      title: Text(member.name,
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      subtitle: Text(days == null ? 'Nunca ha entrenado' : 'Hace $days días',
          style: TextStyle(color: AppColors.error, fontSize: 12)),
      trailing: hasPhone
          ? IconButton(
              tooltip: 'Escribir a $first por WhatsApp',
              icon: Icon(Icons.chat_outlined, color: AppColors.primaryText),
              onPressed: () => ShareHelper.whatsappTo(member.phone!,
                  'Hola $first, ¿todo bien? Te esperamos en el gym esta semana.'),
            )
          : Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
