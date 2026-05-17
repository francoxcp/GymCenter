import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para cachear datos de workouts localmente con cifrado AES.
/// Usa flutter_secure_storage (Android Keystore / iOS Keychain) para que los
/// datos no sean legibles en texto plano aunque el dispositivo esté rooteado.
class OfflineCacheService {
  static const _workoutsKey = 'cached_workouts_v1';
  static const _cachedAtKey = 'workouts_cached_at_v1';
  static const _cacheTtlDays = 7;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Guarda la lista de workouts (como JSON cifrado) en almacenamiento seguro.
  Future<void> saveWorkouts(List<dynamic> workouts) async {
    try {
      await _storage.write(key: _workoutsKey, value: jsonEncode(workouts));
      await _storage.write(
          key: _cachedAtKey, value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('OfflineCacheService: error guardando workouts: $e');
    }
  }

  /// Carga los workouts cacheados. Devuelve null si no hay caché o si expiró.
  Future<List<dynamic>?> loadWorkouts() async {
    try {
      // Verificar TTL: si el caché tiene más de 7 días, descartarlo
      final cachedTime = await cachedAt();
      if (cachedTime != null &&
          DateTime.now().difference(cachedTime).inDays >= _cacheTtlDays) {
        await clearCache();
        return null;
      }
      final json = await _storage.read(key: _workoutsKey);
      if (json == null) return null;
      return jsonDecode(json) as List<dynamic>;
    } catch (e) {
      debugPrint('OfflineCacheService: error leyendo workouts en caché: $e');
      return null;
    }
  }

  /// Devuelve true si hay workouts cacheados disponibles.
  Future<bool> hasCachedWorkouts() async {
    final value = await _storage.read(key: _workoutsKey);
    return value != null;
  }

  /// Devuelve la fecha/hora en que se guardó el caché, o null.
  Future<DateTime?> cachedAt() async {
    final str = await _storage.read(key: _cachedAtKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Elimina todos los datos cacheados (workouts + timestamps).
  /// Debe llamarse al cerrar sesión para evitar que un siguiente usuario
  /// vea datos del usuario anterior en un dispositivo compartido.
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _workoutsKey);
      await _storage.delete(key: _cachedAtKey);
    } catch (e) {
      debugPrint('OfflineCacheService: error limpiando caché: $e');
    }
  }
}
