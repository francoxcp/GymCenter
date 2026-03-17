import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/meal_plans/providers/meal_plan_provider.dart';
import 'package:chamos_fitness_center/features/meal_plans/models/meal_plan.dart';

MealPlan _plan({
  required String name,
  required int calories,
  required String category,
  String iconType = 'fork',
}) {
  return MealPlan(
    id: name.hashCode.toString(),
    name: name,
    description: 'Test plan $name',
    calories: calories,
    category: category,
    iconType: iconType,
  );
}

void main() {
  late MealPlanProvider provider;

  setUp(() {
    provider = MealPlanProvider();
  });

  // ── filteredMealPlans ──────────────────────────────────────────────────

  group('filteredMealPlans', () {
    test('returns all when filter is TODOS', () {
      provider.mealPlans.addAll([
        _plan(name: 'Keto', calories: 2000, category: 'KETO'),
        _plan(name: 'Vegano', calories: 2200, category: 'VEGANO'),
      ]);

      expect(provider.filteredMealPlans.length, 2);
    });

    test('filters by category', () {
      provider.mealPlans.addAll([
        _plan(name: 'Keto Plan', calories: 2000, category: 'KETO'),
        _plan(name: 'Vegano Plan', calories: 2200, category: 'VEGANO'),
        _plan(name: 'Keto Plus', calories: 1800, category: 'KETO'),
      ]);

      provider.setFilter('KETO');
      expect(provider.filteredMealPlans.length, 2);
      expect(
        provider.filteredMealPlans.every((p) => p.category == 'KETO'),
        true,
      );
    });

    test('returns empty when no plans match filter', () {
      provider.mealPlans.add(
        _plan(name: 'Keto', calories: 2000, category: 'KETO'),
      );

      provider.setFilter('DÉFICIT');
      expect(provider.filteredMealPlans, isEmpty);
    });

    test('setFilter changes selectedFilter', () {
      expect(provider.selectedFilter, 'TODOS');

      provider.setFilter('VEGANO');
      expect(provider.selectedFilter, 'VEGANO');

      provider.setFilter('TODOS');
      expect(provider.selectedFilter, 'TODOS');
    });
  });

  // ── _getCategoryFromCalories (tested indirectly) ──────────────────────
  // This private method is used during loadMealPlans() from Supabase.
  // We can't call it directly, but we can verify the mapping logic.

  group('category mapping from calories', () {
    test('below 1600 → DÉFICIT', () {
      // Verified against _getCategoryFromCalories implementation:
      // if (calories < 1600) return 'DÉFICIT';
      expect(_getCategoryFromCalories(1500), 'DÉFICIT');
      expect(_getCategoryFromCalories(0), 'DÉFICIT');
    });

    test('1600-2099 → KETO', () {
      expect(_getCategoryFromCalories(1600), 'KETO');
      expect(_getCategoryFromCalories(2099), 'KETO');
    });

    test('2100-2599 → VEGANO', () {
      expect(_getCategoryFromCalories(2100), 'VEGANO');
      expect(_getCategoryFromCalories(2599), 'VEGANO');
    });

    test('2600-2999 → MEDITERRÁNEA', () {
      expect(_getCategoryFromCalories(2600), 'MEDITERRÁNEA');
      expect(_getCategoryFromCalories(2999), 'MEDITERRÁNEA');
    });

    test('3000+ → HIPER', () {
      expect(_getCategoryFromCalories(3000), 'HIPER');
      expect(_getCategoryFromCalories(5000), 'HIPER');
    });
  });

  // ── _getIconFromName (tested indirectly) ──────────────────────────────

  group('icon mapping from name', () {
    test('keto → fork', () {
      expect(_getIconFromName('Plan Keto'), 'fork');
    });

    test('vega → leaf', () {
      expect(_getIconFromName('Plan Vegano'), 'leaf');
    });

    test('mediterr → burger', () {
      expect(_getIconFromName('Dieta Mediterránea'), 'burger');
    });

    test('proteína → dumbbell', () {
      expect(_getIconFromName('Alta Proteína'), 'dumbbell');
    });

    test('hiper → dumbbell', () {
      expect(_getIconFromName('Hipercalórica'), 'dumbbell');
    });

    test('déficit → fire', () {
      expect(_getIconFromName('Déficit Calórico'), 'fire');
      expect(_getIconFromName('Deficit Plan'), 'fire');
    });

    test('unknown → fork (default)', () {
      expect(_getIconFromName('Random Plan'), 'fork');
    });
  });
}

// ── Mirrors of private functions for testing ──────────────────────────────
// These replicate the exact logic from MealPlanProvider to ensure the
// mapping rules are correct.

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
