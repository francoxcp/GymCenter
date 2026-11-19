import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../widgets/exercise_library.dart';

/// Lee y guarda la biblioteca de ejercicios (tabla `exercise_library`).
/// Catálogo global de GYMLAB + ejercicios propios de la organización.
/// Si la tabla no existe o no hay conexión, usa el catálogo local.
class ExerciseLibraryService {
  ExerciseLibraryService._();
  static final instance = ExerciseLibraryService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<LibraryExercise>? _cache;
  DateTime? _cachedAt;
  static const _ttl = Duration(minutes: 10);

  /// Ejercicios disponibles. Los de la organización reemplazan a los
  /// globales con el mismo nombre (p. ej. con el video del gimnasio).
  Future<List<LibraryExercise>> load({bool force = false}) async {
    final fresh = _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _ttl;
    if (!force && fresh && _cache != null) return _cache!;
    try {
      final rows = await _client
          .from('exercise_library')
          .select(
              'id, org_id, name, muscle_group, default_sets, default_reps, default_rest, media_url, instructions')
          .order('name')
          .limit(3000);
      final byName = <String, LibraryExercise>{};
      for (final r in rows) {
        final e = LibraryExercise.fromRow(r);
        final key = normalizeExerciseName(e.name);
        final existing = byName[key];
        // La versión de la organización gana a la global
        if (existing == null || (r['org_id'] != null && !existing.isOwn)) {
          byName[key] = e;
        }
      }
      if (byName.isEmpty) return kExerciseLibrary;
      _cache = byName.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _cachedAt = DateTime.now();
      return _cache!;
    } catch (e) {
      debugPrint('ExerciseLibrary: usando catálogo local ($e)');
      return _cache ?? kExerciseLibrary;
    }
  }

  /// Guarda en la biblioteca de la organización un ejercicio con video
  /// propio, para reutilizarlo en otras rutinas. No falla si no se puede.
  Future<void> saveFromExercise(Exercise e) async {
    final url = e.videoUrl?.trim() ?? '';
    final name = e.name.trim();
    if (url.isEmpty || name.length < 2) return;
    try {
      final orgId = await _client.rpc('my_active_org_id');
      if (orgId == null) return;
      final existing = await _client
          .from('exercise_library')
          .select('id')
          .eq('org_id', orgId)
          .ilike('name', _escapeLike(name))
          .maybeSingle();
      final data = {
        'media_url': url,
        'muscle_group': e.muscleGroup,
        if ((e.description ?? '').trim().isNotEmpty)
          'instructions': e.description!.trim(),
      };
      if (existing != null) {
        await _client
            .from('exercise_library')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await _client.from('exercise_library').insert({
          ...data,
          'org_id': orgId,
          'name': name,
          'default_sets': e.sets.clamp(1, 20),
          'default_reps': e.reps.clamp(1, 200),
          'default_rest': e.restSeconds.clamp(0, 600),
          'source': 'upload',
        });
      }
      _cachedAt = null; // recargar en la próxima apertura
    } catch (err) {
      // Sin permiso (socio) o sin la migración aplicada: no es crítico
      debugPrint('ExerciseLibrary: no se guardó "$name" ($err)');
    }
  }

  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Minúsculas y sin tildes, para buscar y comparar nombres.
String normalizeExerciseName(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n');
