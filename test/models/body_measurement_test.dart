import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/progress/models/body_measurement.dart';

void main() {
  group('BodyMeasurement Model Tests', () {
    test('fromJson creates BodyMeasurement instance correctly', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'date': '2024-01-15T10:30:00.000Z',
        'weight': 75.5,
        'height': 180.0,
        'chest': 100.0,
        'waist': 85.0,
        'hips': 95.0,
        'biceps': 35.0,
        'thighs': 55.0,
        'photo_url': 'https://example.com/photo.jpg',
        'notes': 'Medición regular',
      };

      final measurement = BodyMeasurement.fromJson(json);

      expect(measurement.id, '1');
      expect(measurement.userId, 'user123');
      expect(measurement.date.year, 2024);
      expect(measurement.date.month, 1);
      expect(measurement.date.day, 15);
      expect(measurement.weight, 75.5);
      expect(measurement.height, 180.0);
      expect(measurement.chest, 100.0);
      expect(measurement.waist, 85.0);
      expect(measurement.hips, 95.0);
      expect(measurement.biceps, 35.0);
      expect(measurement.thighs, 55.0);
      expect(measurement.photoUrl, 'https://example.com/photo.jpg');
      expect(measurement.notes, 'Medición regular');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'date': '2024-01-15T10:30:00.000Z',
      };

      final measurement = BodyMeasurement.fromJson(json);

      expect(measurement.id, '1');
      expect(measurement.userId, 'user123');
      expect(measurement.weight, isNull);
      expect(measurement.height, isNull);
      expect(measurement.chest, isNull);
      expect(measurement.waist, isNull);
      expect(measurement.hips, isNull);
      expect(measurement.biceps, isNull);
      expect(measurement.thighs, isNull);
      expect(measurement.photoUrl, isNull);
      expect(measurement.notes, isNull);
    });

    test('toJson converts BodyMeasurement to JSON correctly', () {
      final measurement = BodyMeasurement(
        id: '1',
        userId: 'user123',
        date: DateTime(2024, 1, 15, 10, 30),
        weight: 75.5,
        height: 180.0,
        chest: 100.0,
        waist: 85.0,
        hips: 95.0,
        biceps: 35.0,
        thighs: 55.0,
        photoUrl: 'https://example.com/photo.jpg',
        notes: 'Medición regular',
      );

      final json = measurement.toJson();

      expect(json['id'], '1');
      expect(json['user_id'], 'user123');
      expect(json['date'], isNotEmpty);
      expect(json['weight'], 75.5);
      expect(json['height'], 180.0);
      expect(json['chest'], 100.0);
      expect(json['waist'], 85.0);
      expect(json['hips'], 95.0);
      expect(json['biceps'], 35.0);
      expect(json['thighs'], 55.0);
      expect(json['photo_url'], 'https://example.com/photo.jpg');
      expect(json['notes'], 'Medición regular');
    });

    test('fromJson parses numeric values correctly from JSON', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'date': '2024-01-15T10:30:00.000Z',
        'weight': 75,
        'height': 180,
        'chest': 100,
      };

      final measurement = BodyMeasurement.fromJson(json);

      expect(measurement.weight, 75.0);
      expect(measurement.height, 180.0);
      expect(measurement.chest, 100.0);
    });

    test('creates BodyMeasurement with only required fields', () {
      final measurement = BodyMeasurement(
        id: '1',
        userId: 'user123',
        date: DateTime.now(),
      );

      expect(measurement.id, '1');
      expect(measurement.userId, 'user123');
      expect(measurement.weight, isNull);
      expect(measurement.height, isNull);
      expect(measurement.chest, isNull);
      expect(measurement.waist, isNull);
      expect(measurement.hips, isNull);
      expect(measurement.biceps, isNull);
      expect(measurement.thighs, isNull);
    });

    test('handles ISO8601 date format correctly', () {
      final json = {
        'id': '1',
        'user_id': 'user123',
        'date': '2024-01-15T10:30:00.000Z',
      };

      final measurement = BodyMeasurement.fromJson(json);

      expect(measurement.date.year, 2024);
      expect(measurement.date.month, 1);
      expect(measurement.date.day, 15);
      expect(measurement.date.hour, 10);
      expect(measurement.date.minute, 30);
    });
  });
}
