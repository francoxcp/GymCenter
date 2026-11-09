import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/safe_pop.dart';
import '../../shared/services/share_helper.dart';
import '../../shared/widgets/top_actions.dart' show foldText;
import '../admin/models/member_status.dart';
import '../admin/screens/member_hub_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/notifications_screen.dart' show timeAgo;
import '../profile/providers/user_provider.dart';
import 'chat_service.dart';
import 'chat_thread.dart';

/// Pestaña Chat del socio: su conversación con el entrenador.
class MemberChatScreen extends StatefulWidget {
  const MemberChatScreen({super.key});

  @override
  State<MemberChatScreen> createState() => _MemberChatScreenState();
}

class _MemberChatScreenState extends State<MemberChatScreen> {
  String? _name;
  String? _phone;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().loadTrainerContact().then((c) {
      if (mounted) {
        setState(() {
          _name = c.name;
          _phone = c.phone;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final trainerId = me?.trainerId;
    final first = (_name ?? '').split(' ').first;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name ?? 'Tu entrenador',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            Text('Tu entrenador',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          if ((_phone ?? '').isNotEmpty)
            IconButton(
              tooltip: 'WhatsApp',
              icon: Icon(Icons.call_outlined, color: AppColors.textPrimary),
              onPressed: () => ShareHelper.whatsappTo(_phone!, 'Hola $first, '),
            ),
        ],
      ),
      body: me == null || trainerId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                    'Cuando tengas entrenador asignado podrás escribirle aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          : ChatThread(
              key: ValueKey(trainerId),
              memberId: me.id,
              trainerId: trainerId,
              meId: me.id,
              emptyHint: first.isEmpty
                  ? 'Escríbele a tu entrenador: dudas, molestias o cómo te fue.'
                  : 'Escríbele a $first: dudas, molestias o cómo te fue.',
            ),
    );
  }
}

/// Pestaña Chats del entrenador: una fila por socio.
class TrainerChatsScreen extends StatefulWidget {
  const TrainerChatsScreen({super.key});

  @override
  State<TrainerChatsScreen> createState() => _TrainerChatsScreenState();
}

class _TrainerChatsScreenState extends State<TrainerChatsScreen> {
  List<ChatSummary> _chats = [];
  bool _loading = true;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
    // Un mensaje nuevo cambia el contador → recargar la lista
    ChatService.unread.addListener(_load);
  }

  @override
  void dispose() {
    ChatService.unread.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await ChatService.myChats();
      if (mounted) setState(() => _chats = c);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = foldText(_q);
    final list =
        q.isEmpty ? _chats : _chats.where((c) => foldText(c.name).contains(q)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.popOrGo('/admin/members'),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text('Chats',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (_chats.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar socio',
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_chats.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                    'Aún no tienes socios asignados. Cuando el dueño te asigne socios, aparecen aquí para escribirles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
              )
            else
              for (final c in list) _ChatRow(chat: c, onBack: _load),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onBack;
  const _ChatRow({required this.chat, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = chat;
    final unread = c.unread > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () async {
        await context.push('/chats/${c.memberId}');
        onBack();
      },
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.cardBackground,
        backgroundImage: (c.photoUrl ?? '').isNotEmpty ? NetworkImage(c.photoUrl!) : null,
        child: (c.photoUrl ?? '').isNotEmpty
            ? null
            : Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      title: Text(c.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: unread ? FontWeight.w900 : FontWeight.w600)),
      subtitle: Text(
          c.lastBody == null
              ? 'Sin mensajes · toca para escribir'
              : '${c.lastFromMe ? 'Tú: ' : ''}${c.lastBody}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: unread ? AppColors.textPrimary : AppColors.textSecondary)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastAt != null)
            Text(timeAgo(c.lastAt!),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          if (unread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('${c.unread}',
                  style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Conversación del entrenador con un socio (pantalla completa).
class TrainerChatScreen extends StatelessWidget {
  final String memberId;
  const TrainerChatScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final members = context.watch<UserProvider>().users.where((u) => u.id == memberId);
    final member = members.isEmpty ? null : members.first;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/chats'),
        ),
        title: Text(member?.name ?? 'Chat',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          if (member != null)
            IconButton(
              tooltip: 'Ver ficha de ${member.name}',
              icon: Icon(Icons.person_outline, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MemberHubScreen(
                  member: member,
                  status: MemberStatus.compute(
                      userId: member.id,
                      plannedPerWeek: 0,
                      sessions: const [],
                      now: DateTime.now()),
                ),
              )),
            ),
        ],
      ),
      body: me == null
          ? const SizedBox.shrink()
          : member != null && member.trainerId != me.id
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Este socio no está asignado a ti.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ChatThread(
                  memberId: memberId,
                  trainerId: me.id,
                  meId: me.id,
                  showQuickReplies: true,
                  emptyHint:
                      'Escríbele a ${(member?.name ?? 'tu socio').split(' ').first}. Le llega un aviso al teléfono.',
                ),
    );
  }
}
