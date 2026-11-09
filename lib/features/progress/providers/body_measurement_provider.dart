import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/body_measurement.dart';

/// Medidas de un socio. Sin [memberId] son las del usuario actual; el
/// entrenador crea una instancia con el id de su socio.
class BodyMeasurementProvider with ChangeNotifier {
  BodyMeasurementProvider({this.memberId});

  final String? memberId;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<BodyMeasurement> _measurements = [];
  bool _isLoading = false;
  String? _error;

  /// Más reciente primero.
  List<BodyMeasurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _targetId => memberId ?? _supabase.auth.currentUser?.id;

  BodyMeasurement? get latestMeasurement =>
      _measurements.isEmpty ? null : _measurements.first;

  /// Último valor registrado de una medida (no todas se toman siempre).
  double? latestOf(MeasureField f) {
    for (final m in _measurements) {
      final v = m.valueOf(f);
      if (v != null) return v;
    }
    return null;
  }

  /// Cambio entre el último valor y el anterior de esa medida.
  double? changeOf(MeasureField f) {
    final values = [
      for (final m in _measurements)
        if (m.valueOf(f) != null) m.valueOf(f)!
    ];
    if (values.length < 2) return null;
    return values[0] - values[1];
  }

  /// Cambio desde la primera medición.
  double? totalChangeOf(MeasureField f) {
    final values = [
      for (final m in _measurements)
        if (m.valueOf(f) != null) m.valueOf(f)!
    ];
    if (values.length < 2) return null;
    return values.first - values.last;
  }

  /// Mediciones de los últimos [days] días.
  List<BodyMeasurement> getMeasurementsByPeriod(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _measurements.where((m) => m.date.isAfter(cutoff)).toList();
  }

  Future<void> loadMeasurements() async {
    final id = _targetId;
    if (id == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _supabase
          .from('body_measurements')
          .select()
          .eq('user_id', id)
          .order('date', ascending: false);
      _measurements = (response as List)
          .map((j) => BodyMeasurement.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      _error = 'No se pudieron cargar las medidas';
      debugPrint('Error al cargar medidas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guarda una medición nueva o corrige una existente.
  Future<bool> saveMeasurement(BodyMeasurement m) async {
    final id = _targetId;
    final me = _supabase.auth.currentUser?.id;
    if (id == null || me == null) return false;
    _error = null;
    try {
      final data = m.copyWith(userId: id, recordedBy: m.id.isEmpty ? me : null).toJson();
      final row = m.id.isEmpty
          ? await _supabase.from('body_measurements').insert(data).select().single()
          : await _supabase
              .from('body_measurements')
              .update(data..remove('recorded_by'))
              .eq('id', m.id)
              .select()
              .single();
      final saved = BodyMeasurement.fromJson(row);
      _measurements = [
        saved,
        ..._measurements.where((x) => x.id != saved.id),
      ]..sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la medición';
      debugPrint('Error al guardar medida: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMeasurement(String id) async {
    try {
      await _supabase.from('body_measurements').delete().eq('id', id);
      _measurements = _measurements.where((m) => m.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al borrar medida: $e');
      return false;
    }
  }
}
