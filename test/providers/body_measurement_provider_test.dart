import 'package:flutter_test/flutter_test.dart';
import 'package:chamos_fitness_center/features/progress/models/body_measurement.dart';

/// Tests for BodyMeasurementProvider pure logic.
/// We replicate the provider's methods here because the provider
/// accesses Supabase.instance.client at field-init time.

BodyMeasurement _measurement({
  required DateTime date,
  double? weight,
  double? height,
  double? waist,
}) {
  return BodyMeasurement(
    id: date.millisecondsSinceEpoch.toString(),
    userId: 'test-user',
    date: date,
    weight: weight,
    height: height,
    waist: waist,
  );
}

// Mirrors of provider methods
BodyMeasurement? _latestMeasurement(List<BodyMeasurement> m) {
  if (m.isEmpty) return null;
  return m.first;
}

double? _getWeightChange(List<BodyMeasurement> m) {
  if (m.length < 2) return null;
  final latest = m[0].weight;
  final previous = m[1].weight;
  if (latest == null || previous == null) return null;
  return latest - previous;
}

List<BodyMeasurement> _getMeasurementsByPeriod(
    List<BodyMeasurement> m, int days) {
  final cutoffDate = DateTime.now().subtract(Duration(days: days));
  return m.where((x) => x.date.isAfter(cutoffDate)).toList();
}

void main() {
  // ── latestMeasurement ──────────────────────────────────────────────────

  group('latestMeasurement', () {
    test('returns null when empty', () {
      expect(_latestMeasurement([]), isNull);
    });

    test('returns first element (sorted newest-first)', () {
      final measurements = [
        _measurement(date: DateTime(2024, 6, 15), weight: 80.0),
        _measurement(date: DateTime(2024, 6, 10), weight: 82.0),
      ];
      expect(_latestMeasurement(measurements)!.weight, 80.0);
    });
  });

  // ── getWeightChange() ──────────────────────────────────────────────────

  group('getWeightChange()', () {
    test('returns null when fewer than 2 measurements', () {
      expect(_getWeightChange([]), isNull);
      expect(
        _getWeightChange([
          _measurement(date: DateTime(2024, 6, 15), weight: 80.0),
        ]),
        isNull,
      );
    });

    test('returns null when weights are null', () {
      expect(
        _getWeightChange([
          _measurement(date: DateTime(2024, 6, 15)),
          _measurement(date: DateTime(2024, 6, 10)),
        ]),
        isNull,
      );
    });

    test('calculates positive change (gained weight)', () {
      expect(
        _getWeightChange([
          _measurement(date: DateTime(2024, 6, 15), weight: 82.0),
          _measurement(date: DateTime(2024, 6, 10), weight: 80.0),
        ]),
        2.0,
      );
    });

    test('calculates negative change (lost weight)', () {
      expect(
        _getWeightChange([
          _measurement(date: DateTime(2024, 6, 15), weight: 78.0),
          _measurement(date: DateTime(2024, 6, 10), weight: 80.0),
        ]),
        -2.0,
      );
    });

    test('returns 0 when weight unchanged', () {
      expect(
        _getWeightChange([
          _measurement(date: DateTime(2024, 6, 15), weight: 80.0),
          _measurement(date: DateTime(2024, 6, 10), weight: 80.0),
        ]),
        0.0,
      );
    });
  });

  // ── getMeasurementsByPeriod() ──────────────────────────────────────────

  group('getMeasurementsByPeriod()', () {
    test('returns empty when no measurements', () {
      expect(_getMeasurementsByPeriod([], 7), isEmpty);
    });

    test('filters by last 7 days', () {
      final now = DateTime.now();
      final measurements = [
        _measurement(date: now.subtract(const Duration(days: 1)), weight: 79.0),
        _measurement(date: now.subtract(const Duration(days: 5)), weight: 80.0),
        _measurement(
            date: now.subtract(const Duration(days: 10)), weight: 82.0),
      ];
      expect(_getMeasurementsByPeriod(measurements, 7).length, 2);
    });

    test('filters by last 30 days', () {
      final now = DateTime.now();
      final measurements = [
        _measurement(date: now.subtract(const Duration(days: 1)), weight: 79.0),
        _measurement(
            date: now.subtract(const Duration(days: 20)), weight: 80.0),
        _measurement(
            date: now.subtract(const Duration(days: 60)), weight: 82.0),
      ];
      expect(_getMeasurementsByPeriod(measurements, 30).length, 2);
    });

    test('returns all with large period', () {
      final measurements = [
        _measurement(date: DateTime(2024, 1, 1), weight: 85.0),
        _measurement(date: DateTime(2023, 6, 1), weight: 90.0),
      ];
      expect(_getMeasurementsByPeriod(measurements, 10000).length, 2);
    });
  });

  // ── BodyMeasurement effective fields (model tests) ─────────────────────

  group('BodyMeasurement effective fields', () {
    test('effectiveBicepsLeft prefers new field over legacy', () {
      final m = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: DateTime.now(),
        bicepsLeft: 35.0,
        biceps: 30.0,
      );
      expect(m.effectiveBicepsLeft, 35.0);
    });

    test('effectiveBicepsLeft falls back to legacy', () {
      final m = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: DateTime.now(),
        biceps: 30.0,
      );
      expect(m.effectiveBicepsLeft, 30.0);
    });

    test('effectiveThighRight prefers new field over legacy', () {
      final m = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: DateTime.now(),
        thighRight: 55.0,
        thighs: 50.0,
      );
      expect(m.effectiveThighRight, 55.0);
    });

    test('effectiveThighRight falls back to legacy', () {
      final m = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: DateTime.now(),
        thighs: 50.0,
      );
      expect(m.effectiveThighRight, 50.0);
    });

    test('all effective fields return null when no data', () {
      final m = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: DateTime.now(),
      );
      expect(m.effectiveBicepsLeft, isNull);
      expect(m.effectiveBicepsRight, isNull);
      expect(m.effectiveThighLeft, isNull);
      expect(m.effectiveThighRight, isNull);
    });
  });
}
