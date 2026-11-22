import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../chat_service.dart';

/// Acceso al chat con el entrenador desde la cabecera de Hoy, con el número
/// de mensajes sin leer.
class ChatHeaderButton extends StatelessWidget {
  const ChatHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ChatService.unread,
      builder: (context, n, _) => IconButton(
        tooltip: n > 0
            ? 'Chat con tu entrenador, $n sin leer'
            : 'Chat con tu entrenador',
        onPressed: () => context.push('/chat'),
        icon: Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          backgroundColor: AppColors.primary,
          textColor: AppColors.onPrimary,
          child: Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
