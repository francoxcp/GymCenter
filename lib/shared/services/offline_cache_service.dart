import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para cachear datos de workouts localmente.
/// Permite que la app funcione sin conexión mostrando la última rutina guardada.
class OfflineCacheService {
  static const _workoutsKey = 'cached_workouts_v1';
  static const _cachedAtKey = 'workouts_cached_at_v1';

  /// Guarda la lista de workouts (como JSON crudo de Supabase) en SharedPreferences.
  Future<void> saveWorkouts(List<dynamic> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_workoutsKey, jsonEncode(workouts));
      await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('OfflineCacheService: error guardando workouts: $e');
    }
  }

  /// Carga los workouts cacheados. Devuelve null si no hay caché.
  Future<List<dynamic>?> loadWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_workoutsKey);
      if (json == null) return null;
      return jsonDecode(json) as List<dynamic>;
    } catch (e) {
      debugPrint('OfflineCacheService: error leyendo workouts en caché: $e');
      return null;
    }
  }

  /// Devuelve true si hay workouts cacheados disponibles.
  Future<bool> hasCachedWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_workoutsKey);
  }

  /// Devuelve la fecha/hora en que se guardó el caché, o null.
  Future<DateTime?> cachedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_cachedAtKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Elimina todos los datos cacheados (workouts + timestamps).
  /// Debe llamarse al cerrar sesión para evitar que un siguiente usuario
  /// vea datos del usuario anterior en un dispositivo compartido.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_workoutsKey);
      await prefs.remove(_cachedAtKey);
    } catch (e) {
      debugPrint('OfflineCacheService: error limpiando caché: $e');
    }
  }
}
