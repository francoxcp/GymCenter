import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación biométrica (huella/Face ID).
///
/// Guarda la preferencia del usuario en SharedPreferences y envuelve
/// las llamadas a `local_auth` con manejo seguro de errores.
class BiometricService {
  BiometricService._();
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;

  static const _kBiometricEnabled = 'biometric_lock_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  /// Comprueba si el dispositivo soporta autenticación biométrica.
  Future<bool> isAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Devuelve los tipos de biometría disponibles (huella, Face ID, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Indica si el usuario habilitó el bloqueo biométrico.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Habilita o deshabilita el bloqueo biométrico.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }

  /// Solicita autenticación biométrica al usuario.
  /// Retorna `true` si el usuario se autentica exitosamente.
  Future<bool> authenticate({
    String reason = 'Autenticación requerida',
  }) async {
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
