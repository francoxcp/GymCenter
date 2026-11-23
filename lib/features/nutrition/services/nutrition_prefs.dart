import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/models/user.dart';

/// Copia local del perfil alimentario: el plan se muestra aunque no haya
/// conexión al guardar el cuestionario, y se reintenta subir después.
class NutritionPrefs {
  NutritionPrefs._();

  static String _key(String userId) => 'nutrition_profile_$userId';

  /// Guarda las respuestas. [pending]: aún no llegaron al servidor.
  static Future<void> save(String userId, Map<String, dynamic> data,
      {bool pending = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(userId),
        jsonEncode({
          ...data,
          'saved_at': DateTime.now().toIso8601String(),
          '_pending': pending,
        }));
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

  static Future<bool> isPending(String userId) async =>
      (await load(userId))?['_pending'] == true;

  static Future<void> markSynced(String userId) async {
    final data = await load(userId);
    if (data == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode({...data, '_pending': false}));
  }
}

/// Columnas de `users` que guarda el cuestionario.
const kNutritionColumns = [
  'weight_kg',
  'height_cm',
  'age',
  'sex',
  'goal',
  'activity_level',
  'food_avoid',
  'meals_per_day',
];

/// Aplica la copia local al usuario sin tocar ningún otro dato.
User applyNutritionPrefs(User u, Map<String, dynamic> local) => u.copyWith(
      weightKg: local.containsKey('weight_kg')
          ? (local['weight_kg'] as num?)?.toDouble()
          : u.weightKg,
      heightCm: local.containsKey('height_cm')
          ? (local['height_cm'] as num?)?.toInt()
          : u.heightCm,
      age: local.containsKey('age') ? (local['age'] as num?)?.toInt() : u.age,
      sex: local.containsKey('sex') ? local['sex'] as String? : u.sex,
      goal: local.containsKey('goal') ? local['goal'] as String? : u.goal,
      activityLevel: local.containsKey('activity_level')
          ? local['activity_level'] as String?
          : u.activityLevel,
      foodAvoid: local['food_avoid'] is List
          ? [for (final v in local['food_avoid'] as List) '$v']
          : u.foodAvoid,
      mealsPerDay: local.containsKey('meals_per_day')
          ? (local['meals_per_day'] as num?)?.toInt()
          : u.mealsPerDay,
    );

/// Peso para el plan: la medida más reciente, salvo que el socio haya
/// corregido su peso en el cuestionario después de esa medida.
double? effectiveWeight({
  double? measuredKg,
  DateTime? measuredAt,
  Map<String, dynamic>? local,
  double? userKg,
}) {
  final localKg = (local?['weight_kg'] as num?)?.toDouble();
  final savedAt = DateTime.tryParse('${local?['saved_at'] ?? ''}');
  if (localKg != null &&
      savedAt != null &&
      (measuredAt == null || savedAt.isAfter(measuredAt))) {
    return localKg;
  }
  return measuredKg ?? localKg ?? userKg;
}
