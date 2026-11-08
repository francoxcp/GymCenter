import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../social/activity_service.dart';
import '../../social/comments_sheet.dart';

/// Últimos comentarios del entrenador/dueño sobre los entrenos del socio.
/// No ocupa espacio si no hay ninguno.
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

  Future<void> _load() async {
    try {
      final c = await ActivityService.recentCommentsForMe();
      if (mounted) setState(() => _comments = c);
    } catch (_) {
      // sin conexión: la tarjeta simplemente no aparece
    }
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
              Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: const Row(children: [
                Icon(Icons.chat_bubble, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Tu entrenador te escribió',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 6),
            for (final c in _comments)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => showCommentsSheet(
                  context,
                  sessionId: c.sessionId,
                  title: 'Comentarios del entreno',
                  onChanged: _load,
                ),
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
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          Text('${c.authorName} · ${timeAgo(c.createdAt)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.reply,
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
