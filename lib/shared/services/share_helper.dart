import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../web/web_bridge.dart';

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
      // Aviso por encima de hojas y diálogos (un SnackBar quedaría oculto
      // detrás de la hoja de invitación y parecería que no copió).
      showToast(context, okMessage);
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

  /// Abre el chat de WhatsApp con un número concreto (solo dígitos; si no
  /// trae código de país se asume el de Costa Rica, 506).
  static void whatsappTo(String phone, [String text = '']) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 8) digits = '506$digits';
    final q = text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}';
    final url = 'https://wa.me/$digits$q';
    if (kIsWeb) {
      WebBridge.openUrl(url);
    } else {
      Share.share(text.isEmpty ? '+$digits' : text);
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

  /// Mensaje breve sobre todo lo demás (también sobre hojas modales).
  static void showToast(BuildContext context, String message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 24,
        right: 24,
        top: MediaQuery.of(ctx).padding.top + 16,
        child: IgnorePointer(
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F7A3A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(message,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (entry.mounted) entry.remove();
    });
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
