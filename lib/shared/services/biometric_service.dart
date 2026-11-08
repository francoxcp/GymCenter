import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../web/web_bridge.dart';

/// Servicio de autenticación biométrica (huella/Face ID).
///
/// - Android/iOS: usa `local_auth`.
/// - Web (PWA): usa una passkey del dispositivo (WebAuthn) con verificación
///   de usuario obligatoria — Face ID / Touch ID en iPhone, huella o PIN en
///   Android. Es un bloqueo local de la app, igual que en móvil: la sesión
///   de Supabase sigue protegida por su propio token.
///
/// Guarda la preferencia del usuario en almacenamiento cifrado.
class BiometricService {
  BiometricService._();
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;

  static const _kBiometricEnabled = 'biometric_lock_enabled';
  static const _kPasskeyCredentialId = 'biometric_passkey_credential_id';
  // Perezoso: local_auth no tiene implementación web.
  late final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Comprueba si el dispositivo soporta autenticación biométrica.
  Future<bool> isAvailable() async {
    if (kIsWeb) return WebBridge.passkeyAvailable();
    if (!_isMobile) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Indica si el usuario habilitó el bloqueo biométrico.
  Future<bool> isEnabled() async {
    try {
      final value = await _secureStorage.read(key: _kBiometricEnabled);
      if (value != 'true') return false;
      if (kIsWeb) {
        // Sin passkey registrada no hay forma de desbloquear.
        final cred = await _secureStorage.read(key: _kPasskeyCredentialId);
        return cred != null && cred.isNotEmpty;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Activa el bloqueo verificando primero la identidad del usuario.
  /// En web registra una passkey nueva en el dispositivo.
  /// Devuelve `true` si quedó activado.
  Future<bool> enable({
    required String userId,
    required String userName,
    required String displayName,
    String reason = 'Verifica tu identidad para activar el bloqueo',
  }) async {
    if (kIsWeb) {
      final credentialId = await WebBridge.passkeyRegister(
        userId: userId,
        userName: userName,
        displayName: displayName,
      );
      if (credentialId.isEmpty) return false;
      await _secureStorage.write(
          key: _kPasskeyCredentialId, value: credentialId);
    } else {
      final ok = await authenticate(reason: reason);
      if (!ok) return false;
    }
    await _secureStorage.write(key: _kBiometricEnabled, value: 'true');
    return true;
  }

  /// Desactiva el bloqueo biométrico.
  Future<void> disable() async {
    await _secureStorage.write(key: _kBiometricEnabled, value: 'false');
    if (kIsWeb) await _secureStorage.delete(key: _kPasskeyCredentialId);
  }

  /// Compatibilidad con código existente.
  Future<void> setEnabled(bool value) async {
    if (!value) return disable();
    await _secureStorage.write(key: _kBiometricEnabled, value: 'true');
  }

  /// Solicita autenticación biométrica al usuario.
  /// Retorna `true` si el usuario se autentica exitosamente.
  Future<bool> authenticate({
    String reason = 'Autenticación requerida',
  }) async {
    if (kIsWeb) {
      final cred = await _secureStorage.read(key: _kPasskeyCredentialId);
      if (cred == null || cred.isEmpty) return false;
      return WebBridge.passkeyVerify(cred);
    }
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // permite PIN/patrón como fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
