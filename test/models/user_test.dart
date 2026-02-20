import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/auth/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('fromJson creates User instance correctly', () {
      final json = {
        'id': '1',
        'email': 'test@example.com',
        'name': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'role': 'user',
        'level': 'Intermedio',
        'activeDays': 5,
        'completedWorkouts': 10,
        'assignedWorkoutId': 'workout123',
        'assignedMealPlanId': 'meal456',
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.role, 'user');
      expect(user.level, 'Intermedio');
      expect(user.activeDays, 5);
      expect(user.completedWorkouts, 10);
      expect(user.assignedWorkoutId, 'workout123');
      expect(user.assignedMealPlanId, 'meal456');
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': '1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'user',
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.photoUrl, isNull);
      expect(user.level, 'Principiante'); // default
      expect(user.activeDays, 0); // default
      expect(user.completedWorkouts, 0); // default
      expect(user.assignedWorkoutId, isNull);
      expect(user.assignedMealPlanId, isNull);
    });

    test('toJson converts User to JSON correctly', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        role: 'admin',
        level: 'Avanzado',
        activeDays: 15,
        completedWorkouts: 25,
        assignedWorkoutId: 'workout789',
        assignedMealPlanId: 'meal012',
      );

      final json = user.toJson();

      expect(json['id'], '1');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['role'], 'admin');
      expect(json['level'], 'Avanzado');
      expect(json['activeDays'], 15);
      expect(json['completedWorkouts'], 25);
      expect(json['assignedWorkoutId'], 'workout789');
      expect(json['assignedMealPlanId'], 'meal012');
    });

    test('identifies admin user correctly', () {
      final adminUser = User(
        id: '1',
        email: 'admin@example.com',
        name: 'Admin User',
        role: 'admin',
      );

      final regularUser = User(
        id: '2',
        email: 'user@example.com',
        name: 'Regular User',
        role: 'user',
      );

      expect(adminUser.role, 'admin');
      expect(regularUser.role, 'user');
    });

    test('copyWith creates updated copy', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        level: 'Principiante',
        activeDays: 0,
        completedWorkouts: 0,
      );

      final updatedUser = user.copyWith(
        level: 'Intermedio',
        activeDays: 5,
        completedWorkouts: 10,
      );

      expect(updatedUser.id, '1');
      expect(updatedUser.email, 'test@example.com');
      expect(updatedUser.name, 'Test User');
      expect(updatedUser.level, 'Intermedio');
      expect(updatedUser.activeDays, 5);
      expect(updatedUser.completedWorkouts, 10);
    });

    test('creates User with optional parameters', () {
      final user = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
      );

      expect(user.id, '1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'user');
      expect(user.photoUrl, isNull);
      expect(user.level, 'Principiante');
      expect(user.activeDays, 0);
      expect(user.completedWorkouts, 0);
      expect(user.assignedWorkoutId, isNull);
      expect(user.assignedMealPlanId, isNull);
    });
  });
}
