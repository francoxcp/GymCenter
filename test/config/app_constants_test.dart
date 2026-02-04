import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/config/app_constants.dart';

void main() {
  group('AppConstants Tests', () {
    group('App Info', () {
      test('has correct app name', () {
        expect(AppConstants.appName, 'Chamos Fitness Center');
      });

      test('has correct app version', () {
        expect(AppConstants.appVersion, '1.0.0');
      });
    });

    group('Routes', () {
      test('has all required routes', () {
        expect(AppConstants.loginRoute, '/login');
        expect(AppConstants.registerRoute, '/register');
        expect(AppConstants.homeRoute, '/home');
        expect(AppConstants.adminRoute, '/admin');
        expect(AppConstants.workoutsRoute, '/workouts');
        expect(AppConstants.profileRoute, '/profile');
      });
    });

    group('User Roles', () {
      test('has correct role constants', () {
        expect(AppConstants.adminRole, 'admin');
        expect(AppConstants.userRole, 'user');
      });
    });

    group('Training Levels', () {
      test('has all training levels', () {
        expect(AppConstants.beginnerLevel, 'Principiante');
        expect(AppConstants.intermediateLevel, 'Intermedio');
        expect(AppConstants.advancedLevel, 'Avanzado');
      });
    });

    group('Filters', () {
      test('has filter constants', () {
        expect(AppConstants.filterAll, 'Todos');
        expect(AppConstants.filterAllMeals, 'TODOS');
      });
    });

    group('Meal Plan Categories', () {
      test('has all meal plan categories', () {
        expect(AppConstants.categoryDeficit, 'DÉFICIT');
        expect(AppConstants.categoryKeto, 'KETO');
        expect(AppConstants.categoryVegan, 'VEGANO');
        expect(AppConstants.categoryMediterranean, 'MEDITERRÁNEA');
        expect(AppConstants.categoryHyper, 'HIPER');
      });
    });

    group('Timeouts', () {
      test('has correct timeout durations', () {
        expect(AppConstants.defaultTimeout, const Duration(seconds: 30));
        expect(
            AppConstants.userCreationDelay, const Duration(milliseconds: 500));
      });
    });

    group('Error Messages', () {
      test('has all error messages', () {
        expect(AppConstants.errorLoadingUsers, 'Error al cargar usuarios');
        expect(AppConstants.errorLoadingWorkouts, 'Error al cargar rutinas');
        expect(AppConstants.errorLoadingMealPlans,
            'Error al cargar planes de comida');
        expect(AppConstants.errorAssigning, 'Error al asignar');
      });
    });

    group('Success Messages', () {
      test('has success messages', () {
        expect(AppConstants.successAssigned, 'Asignado correctamente');
      });
    });

    group('Supabase Configuration', () {
      test('has Supabase config keys', () {
        expect(AppConstants.envFileName, '.env');
        expect(AppConstants.supabaseUrlKey, 'SUPABASE_URL');
        expect(AppConstants.supabaseAnonKeyKey, 'SUPABASE_ANON_KEY');
      });
    });

    group('Database Tables', () {
      test('has all table names', () {
        expect(AppConstants.usersTable, 'users');
        expect(AppConstants.workoutsTable, 'workouts');
        expect(AppConstants.exercisesTable, 'exercises');
        expect(AppConstants.mealPlansTable, 'meal_plans');
        expect(AppConstants.workoutSessionsTable, 'workout_sessions');
      });
    });

    group('Query Fields', () {
      test('has query field constants', () {
        expect(AppConstants.createdAtField, 'created_at');
        expect(AppConstants.orderIndexField, 'order_index');
      });
    });

    group('Default Values', () {
      test('has all default values', () {
        expect(AppConstants.defaultRestSeconds, 60);
        expect(AppConstants.defaultCalories, 0);
        expect(AppConstants.defaultActiveDays, 0);
        expect(AppConstants.defaultCompletedWorkouts, 0);
      });
    });
  });
}
