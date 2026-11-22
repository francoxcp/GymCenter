import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Copia local del perfil alimentario: el plan se muestra aunque no haya
/// conexión al guardar el cuestionario.
class NutritionPrefs {
  NutritionPrefs._();

  static String _key(String userId) => 'nutrition_profile_$userId';

  static Future<void> save(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
}
