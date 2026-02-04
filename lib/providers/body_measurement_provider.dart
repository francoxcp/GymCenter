import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/body_measurement.dart';

class BodyMeasurementProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<BodyMeasurement> _measurements = [];
  bool _isLoading = false;
  String? _error;

  List<BodyMeasurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BodyMeasurement? get latestMeasurement {
    if (_measurements.isEmpty) return null;
    return _measurements.first;
  }

  /// Cargar todas las medidas del usuario actual
  Future<void> loadMeasurements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false);

      _measurements = (response as List)
          .map((json) => BodyMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Error al cargar medidas: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agregar nueva medida
  Future<bool> addMeasurement(BodyMeasurement measurement) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final newMeasurement = measurement.copyWith(userId: userId);

      final response = await _supabase
          .from('body_measurements')
          .insert(newMeasurement.toJson())
          .select()
          .single();

      final created = BodyMeasurement.fromJson(response);
      _measurements.insert(0, created);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al guardar medida: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Eliminar medida
  Future<bool> deleteMeasurement(String measurementId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase
          .from('body_measurements')
          .delete()
          .eq('id', measurementId);

      _measurements.removeWhere((m) => m.id == measurementId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar medida: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener cambio de peso (kg) desde la última medida
  double? getWeightChange() {
    if (_measurements.length < 2) return null;

    final latest = _measurements[0].weight;
    final previous = _measurements[1].weight;

    if (latest == null || previous == null) return null;
    return latest - previous;
  }

  /// Obtener todas las medidas de un periodo (últimos N días)
  List<BodyMeasurement> getMeasurementsByPeriod(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _measurements.where((m) => m.date.isAfter(cutoffDate)).toList();
  }
}
