import 'dart:io';
import 'package:flutter/services.dart';

/// Protege pantallas sensibles contra capturas de pantalla y grabación.
///
/// En Android utiliza FLAG_SECURE vía MethodChannel.
/// En iOS no hay API pública equivalente; la protección se omite.
class SecureScreenService {
  SecureScreenService._();

  static const _channel = MethodChannel('com.chamosfitness.app/security');

  /// Activa FLAG_SECURE — la pantalla se ve negra en capturas y grabaciones.
  static Future<void> enable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecureMode');
    } on MissingPluginException {
      // Plugin no disponible (web, tests)
    }
  }

  /// Desactiva FLAG_SECURE — permite capturas normalmente.
  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecureMode');
    } on MissingPluginException {
      // Plugin no disponible (web, tests)
    }
  }
}
