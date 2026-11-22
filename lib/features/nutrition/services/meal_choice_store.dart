import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nutrition_profile.dart';

/// Comida que abre la pantalla según la hora: la siguiente que existe en el
/// plan del socio.
MealSlot defaultSlot(DateTime now, List<MealSlot> slots) {
  final h = now.hour;
  final wanted = h < 10
      ? MealSlot.breakfast
      : h < 12
          ? MealSlot.snackAm
          : h < 15
              ? MealSlot.lunch
              : h < 18
                  ? MealSlot.snackPm
                  : MealSlot.dinner;
  for (final s in slots) {
    if (s.index >= wanted.index) return s;
  }
  return slots.last;
}

/// Lo que el socio eligió hoy en cada comida. Solo en el dispositivo; se
/// reinicia cada día.
class MealChoiceStore {
  MealChoiceStore._();

  static String _key(String userId, DateTime d) =>
      'meal_choice_${userId}_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Map<MealSlot, String>> today(String userId,
      {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, now ?? DateTime.now()));
    if (raw == null) return {};
    try {
      final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return {
        for (final e in map.entries)
          for (final s in MealSlot.values)
            if (s.name == e.key) s: '${e.value}',
      };
    } catch (_) {
      return {};
    }
  }

  /// Guarda (o con [optionId] nulo, quita) la elección de una comida.
  static Future<void> choose(String userId, MealSlot slot, String? optionId,
      {DateTime? now}) async {
    final d = now ?? DateTime.now();
    final current = await today(userId, now: d);
    if (optionId == null) {
      current.remove(slot);
    } else {
      current[slot] = optionId;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId, d),
        jsonEncode({for (final e in current.entries) e.key.name: e.value}));
  }
}
