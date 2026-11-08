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
  // Datos para entrenar sin conexión
  static const _exercisesKey = 'cached_exercises_v1'; // {workoutId: [..]}
  static const _setLogsKey = 'cached_set_logs_v1'; // {workoutId: [..]}
  static const _userKey = 'cached_user_v1';

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

  // ── Ejercicios por rutina ──────────────────────────────────────────────

  Future<Map<String, dynamic>> _readMap(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMap(String key, Map<String, dynamic> map) async {
    try {
      await _storage.write(key: key, value: jsonEncode(map));
    } catch (e) {
      debugPrint('OfflineCacheService: error guardando $key: $e');
    }
  }

  /// Guarda los ejercicios (filas de la tabla `exercises`) de varias rutinas.
  Future<void> saveExercises(Map<String, List<dynamic>> byWorkout) async {
    if (byWorkout.isEmpty) return;
    final map = await _readMap(_exercisesKey);
    map.addAll(byWorkout);
    await _writeMap(_exercisesKey, map);
  }

  Future<List<dynamic>?> loadExercises(String workoutId) async {
    final map = await _readMap(_exercisesKey);
    return map[workoutId] as List<dynamic>?;
  }

  // ── Historial de series (para sugerencias de peso sin conexión) ───────

  Future<void> saveSetLogs(String workoutId, List<dynamic> logs) async {
    final map = await _readMap(_setLogsKey);
    map[workoutId] = logs;
    await _writeMap(_setLogsKey, map);
  }

  Future<List<dynamic>?> loadSetLogs(String workoutId) async {
    final map = await _readMap(_setLogsKey);
    return map[workoutId] as List<dynamic>?;
  }

  // ── Perfil del usuario (para abrir la app sin conexión) ────────────────

  Future<void> saveUser(Map<String, dynamic> userRow) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(userRow));
    } catch (e) {
      debugPrint('OfflineCacheService: error guardando usuario: $e');
    }
  }

  Future<Map<String, dynamic>?> loadUser(String userId) async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) return null;
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return map['id'] == userId ? map : null;
    } catch (_) {
      return null;
    }
  }

  /// Elimina todos los datos cacheados (workouts + timestamps).
  /// Debe llamarse al cerrar sesión para evitar que un siguiente usuario
  /// vea datos del usuario anterior en un dispositivo compartido.
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _workoutsKey);
      await _storage.delete(key: _cachedAtKey);
      await _storage.delete(key: _exercisesKey);
      await _storage.delete(key: _setLogsKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('OfflineCacheService: error limpiando caché: $e');
    }
  }
}
