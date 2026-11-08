import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Protege pantallas sensibles contra capturas de pantalla y grabación.
///
/// En Android utiliza FLAG_SECURE vía MethodChannel.
/// En iOS y en web no hay API equivalente; la protección se omite.
class SecureScreenService {
  SecureScreenService._();

  static const _channel = MethodChannel('com.chamosfitness.app/security');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Activa FLAG_SECURE — la pantalla se ve negra en capturas y grabaciones.
  static Future<void> enable() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('enableSecureMode');
    } on MissingPluginException {
      // Plugin no disponible (tests)
    }
  }

  /// Desactiva FLAG_SECURE — permite capturas normalmente.
  static Future<void> disable() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('disableSecureMode');
    } on MissingPluginException {
      // Plugin no disponible (tests)
    }
  }
}
