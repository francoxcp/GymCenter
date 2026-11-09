import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/activity_service.dart';
import '../../social/comments_sheet.dart';

/// Comentarios NUEVOS del entrenador/dueño sobre los entrenos del socio.
/// Los ya vistos no vuelven a aparecer; sin nuevos no ocupa espacio.
class TrainerCommentsCard extends StatefulWidget {
  const TrainerCommentsCard({super.key});

  @override
  State<TrainerCommentsCard> createState() => _TrainerCommentsCardState();
}

class _TrainerCommentsCardState extends State<TrainerCommentsCard> {
  List<SessionComment> _comments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  static const _kSeen = 'trainer_comments_seen_at';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_kSeen) ?? 0);
      final c = await ActivityService.recentCommentsForMe();
      if (mounted) {
        setState(() =>
            _comments = c.where((x) => x.createdAt.isAfter(seen)).toList());
      }
    } catch (_) {
      // sin conexión: la tarjeta simplemente no aparece
    }
  }

  /// Marca como vistos todos los comentarios mostrados.
  Future<void> _markSeen() async {
    if (_comments.isEmpty) return;
    final newest = _comments
        .map((c) => c.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSeen, newest.millisecondsSinceEpoch);
    if (mounted) setState(() => _comments = const []);
  }

  @override
  Widget build(BuildContext context) {
    if (_comments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primaryText.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Row(children: [
                Icon(Icons.chat_bubble, color: AppColors.primaryText, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Tu entrenador te escribió',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                TextButton(onPressed: _markSeen, child: const Text('Visto')),
              ]),
            ),
            const SizedBox(height: 6),
            for (final c in _comments)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await showCommentsSheet(
                    context,
                    sessionId: c.sessionId,
                    title: 'Comentarios del entreno',
                  );
                  // Abrir la conversación cuenta como leído
                  _markSeen();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14)),
                          Text('${c.authorName} · ${timeAgo(c.createdAt)}',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.reply,
                        color: AppColors.textSecondary, size: 20),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
