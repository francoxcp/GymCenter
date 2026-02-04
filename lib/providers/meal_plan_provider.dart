import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../config/supabase_config.dart';

class MealPlanProvider extends ChangeNotifier {
  List<MealPlan> _mealPlans = [];
  String _selectedFilter = 'TODOS';
  bool _isLoading = false;
  DateTime? _lastFetch;

  List<MealPlan> get mealPlans => _mealPlans;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  MealPlanProvider() {
    loadMealPlans();
  }

  // Cache por 10 minutos (los meal plans cambian menos frecuentemente)
  bool get _shouldRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!).inMinutes > 10;
  }

  Future<void> loadMealPlans({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldRefresh && _mealPlans.isNotEmpty) {
      return; // Usar caché
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('meal_plans')
          .select()
          .order('created_at', ascending: false);

      _mealPlans = (response as List).map((json) {
        return MealPlan(
          id: json['id'],
          name: json['name'],
          description: json['description'] ?? '',
          calories: json['calories'] ?? 0,
          category: _getCategoryFromCalories(json['calories'] ?? 0),
          iconType: _getIconFromName(json['name']),
        );
      }).toList();

      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading meal plans: $e');
    }
  }

  String _getCategoryFromCalories(int calories) {
    if (calories < 1600) return 'DÉFICIT';
    if (calories < 2100) return 'KETO';
    if (calories < 2600) return 'VEGANO';
    if (calories < 3000) return 'MEDITERRÁNEA';
    return 'HIPER';
  }

  String _getIconFromName(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('keto')) return 'fork';
    if (nameLower.contains('vega')) return 'leaf';
    if (nameLower.contains('mediterr')) return 'burger';
    if (nameLower.contains('proteína') || nameLower.contains('hiper')) {
      return 'dumbbell';
    }
    if (nameLower.contains('déficit') || nameLower.contains('deficit')) {
      return 'fire';
    }
    return 'fork';
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<MealPlan> get filteredMealPlans {
    if (_selectedFilter == 'TODOS') {
      return _mealPlans;
    }
    return _mealPlans.where((p) => p.category == _selectedFilter).toList();
  }

  Future<void> addMealPlan(MealPlan plan,
      {List<Map<String, dynamic>>? meals}) async {
    try {
      await SupabaseConfig.client.from('meal_plans').insert({
        'name': plan.name,
        'description': plan.description,
        'calories': plan.calories,
        'meals': meals, // Guardar las comidas como JSONB
      });

      await loadMealPlans(forceRefresh: true);
    } catch (e) {
      debugPrint('Error adding meal plan: $e');
      rethrow;
    }
  }

  Future<void> updateMealPlan(String planId, MealPlan plan,
      {List<Map<String, dynamic>>? meals}) async {
    try {
      await SupabaseConfig.client.from('meal_plans').update({
        'name': plan.name,
        'description': plan.description,
        'calories': plan.calories,
        'meals': meals,
      }).eq('id', planId);

      await loadMealPlans(forceRefresh: true);
    } catch (e) {
      debugPrint('Error updating meal plan: $e');
      rethrow;
    }
  }

  Future<void> deleteMealPlan(String planId) async {
    try {
      await SupabaseConfig.client.from('meal_plans').delete().eq('id', planId);

      await loadMealPlans(forceRefresh: true);
    } catch (e) {
      debugPrint('Error deleting meal plan: $e');
      rethrow;
    }
  }

  MealPlan? getMealPlanById(String planId) {
    try {
      return _mealPlans.firstWhere((p) => p.id == planId);
    } catch (e) {
      return null;
    }
  }
}
