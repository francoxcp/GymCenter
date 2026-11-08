import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../web/web_bridge.dart';
import '../widgets/app_snackbar.dart';

/// Copiar y compartir que funcionan en la PWA (iPhone/Android) y en nativo.
///
/// IMPORTANTE: llamar directamente desde el onPressed, sin `await` antes,
/// para que el navegador lo considere una acción del usuario.
class ShareHelper {
  ShareHelper._();

  /// Copia [text]. Si el navegador no lo permite, muestra el texto para
  /// copiarlo a mano (nunca dice "copiado" sin haberlo copiado).
  static Future<void> copy(BuildContext context, String text,
      {String okMessage = 'Copiado'}) async {
    bool ok;
    if (kIsWeb) {
      ok = await WebBridge.copyText(text);
    } else {
      try {
        await Clipboard.setData(ClipboardData(text: text));
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
    if (!context.mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      AppSnackbar.success(context, okMessage);
    } else {
      await _manualCopy(context, text);
    }
  }

  /// Abre WhatsApp con el mensaje listo para elegir el contacto.
  static void whatsapp(String text) {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (kIsWeb) {
      WebBridge.openUrl(url);
    } else {
      Share.share(text);
    }
  }

  /// Hoja de compartir del teléfono (WhatsApp, Telegram, SMS, correo…).
  /// Si el navegador no la tiene, abre WhatsApp.
  static Future<void> shareOther(String text) async {
    if (kIsWeb) {
      await WebBridge.shareText(text);
    } else {
      await Share.share(text);
    }
  }

  static Future<void> _manualCopy(BuildContext context, String text) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copia el texto'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Tu navegador no permitió copiar automáticamente. '
              'Mantén presionado el texto y elige Copiar.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SelectableText(text,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Listo')),
        ],
      ),
    );
  }
}
