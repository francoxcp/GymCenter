import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/models/meal_plan.dart';

void main() {
  group('MealPlan Model Tests', () {
    test('fromJson creates MealPlan instance correctly', () {
      final json = {
        'id': '1',
        'name': 'Plan Mediterráneo',
        'description': 'Dieta saludable basada en alimentos frescos',
        'calories': 2000,
        'category': 'MEDITERRÁNEA',
        'iconType': 'mediterranean',
      };

      final mealPlan = MealPlan.fromJson(json);

      expect(mealPlan.id, '1');
      expect(mealPlan.name, 'Plan Mediterráneo');
      expect(
          mealPlan.description, 'Dieta saludable basada en alimentos frescos');
      expect(mealPlan.calories, 2000);
      expect(mealPlan.category, 'MEDITERRÁNEA');
      expect(mealPlan.iconType, 'mediterranean');
    });

    test('toJson converts MealPlan to JSON correctly', () {
      final mealPlan = MealPlan(
        id: '1',
        name: 'Plan Keto',
        description: 'Bajo en carbohidratos',
        calories: 1800,
        category: 'KETO',
        iconType: 'keto',
      );

      final json = mealPlan.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Plan Keto');
      expect(json['description'], 'Bajo en carbohidratos');
      expect(json['calories'], 1800);
      expect(json['category'], 'KETO');
      expect(json['iconType'], 'keto');
    });

    test('creates MealPlan with all required fields', () {
      final mealPlan = MealPlan(
        id: '1',
        name: 'Plan Vegano',
        description: 'Basado en plantas',
        calories: 2200,
        category: 'VEGANO',
        iconType: 'vegan',
      );

      expect(mealPlan.id, '1');
      expect(mealPlan.name, 'Plan Vegano');
      expect(mealPlan.description, 'Basado en plantas');
      expect(mealPlan.calories, 2200);
      expect(mealPlan.category, 'VEGANO');
      expect(mealPlan.iconType, 'vegan');
    });

    test('fromJson handles different category types', () {
      final categories = ['DÉFICIT', 'KETO', 'VEGANO', 'MEDITERRÁNEA', 'HIPER'];

      for (var category in categories) {
        final json = {
          'id': '1',
          'name': 'Test Plan',
          'description': 'Test description',
          'calories': 2000,
          'category': category,
          'iconType': 'test',
        };

        final mealPlan = MealPlan.fromJson(json);
        expect(mealPlan.category, category);
      }
    });

    test('fromJson parses calories as int', () {
      final json = {
        'id': '1',
        'name': 'Test Plan',
        'description': 'Test description',
        'calories': 2500,
        'category': 'KETO',
        'iconType': 'test',
      };

      final mealPlan = MealPlan.fromJson(json);
      expect(mealPlan.calories, isA<int>());
      expect(mealPlan.calories, 2500);
    });

    test('fromJson and toJson are reversible', () {
      final originalJson = {
        'id': '1',
        'name': 'Plan Original',
        'description': 'Descripción original',
        'calories': 1900,
        'category': 'MEDITERRÁNEA',
        'iconType': 'mediterranean',
      };

      final mealPlan = MealPlan.fromJson(originalJson);
      final newJson = mealPlan.toJson();

      expect(newJson['id'], originalJson['id']);
      expect(newJson['name'], originalJson['name']);
      expect(newJson['description'], originalJson['description']);
      expect(newJson['calories'], originalJson['calories']);
      expect(newJson['category'], originalJson['category']);
      expect(newJson['iconType'], originalJson['iconType']);
    });
  });
}
