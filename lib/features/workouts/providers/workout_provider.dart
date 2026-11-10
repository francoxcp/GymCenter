import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/superset.dart';
import '../../../config/supabase_config.dart';
import '../../../shared/services/offline_cache_service.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  String _selectedFilter = 'Todos';
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  DateTime? _lastFetch;

  // Guardar parámetros del usuario para recargas automáticas
  String? _currentUserId;
  bool _isAdmin = false;

  String _searchQuery = '';

  List<Workout> get workouts => _workouts;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  /// true si los workouts se cargaron desde caché local (sin conexión)
  bool get isOffline => _isOffline;

  /// Mensaje de error de la última carga, null si no hubo error
  String? get errorMessage => _errorMessage;

  /// Limpia todos los datos en memoria. Llamar al cerrar sesión para
  /// evitar que otro usuario vea datos del usuario anterior.
  void clearData() {
    _workouts = [];
    _lastFetch = null;
    _currentUserId = null;
    _isAdmin = false;
    _errorMessage = null;
    notifyListeners();
  }

  // No cargar automáticamente en el constructor
  // El componente que use este provider debe llamar loadWorkouts() con los parámetros correctos

  // Cache por 5 minutos
  bool get _shouldRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!).inMinutes > 5;
  }

  /// Parses a raw list from Supabase or local cache into [Workout] objects.
  /// Also handles legacy cached data that may include exercises.
  List<Workout> _parseWorkoutList(List<dynamic> data) {
    return data.map<Workout>((json) {
      final exercisesJson = json['exercises'] as List?;
      List<Exercise> exercises = [];
      if (exercisesJson != null) {
        exercises = exercisesJson
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
        exercises.sort((a, b) => a.id.compareTo(b.id));
      }
      return Workout(
        id: json['id'],
        name: json['name'],
        duration: json['duration'],
        exerciseCount: json['exercise_count'] ?? json['exerciseCount'] ?? 0,
        imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
        description: json['description'],
        createdBy: json['created_by'] ?? json['createdBy'],
        category: json['category'],
        exercises: exercises,
      );
    }).toList();
  }

  Future<void> loadWorkouts({
    bool forceRefresh = false,
    String? userId,
    bool isAdmin = false,
  }) async {
    _currentUserId = userId;
    _isAdmin = isAdmin;

    // Memory cache is still valid — nothing to do
    if (!forceRefresh && !_shouldRefresh && _workouts.isNotEmpty) {
      return;
    }

    // ── Stale-while-revalidate ────────────────────────────────────────────────
    // If we already have data in memory (just stale), we'll refresh silently
    // in background without showing a loading spinner.
    // If we have nothing in memory, try loading the disk cache first so the
    // list appears instantly, then refresh in background.
    final hasInMemoryData = _workouts.isNotEmpty;
    var showedDiskCache = false;

    if (!hasInMemoryData && !forceRefresh) {
      try {
        final cached = await OfflineCacheService().loadWorkouts();
        if (cached != null && cached.isNotEmpty) {
          _workouts = _parseWorkoutList(cached);
          showedDiskCache = true;
          notifyListeners(); // instant display — no spinner
        }
      } catch (e) {
        debugPrint('Error loading disk cache: $e');
      }
    }

    // Only show the loading spinner when we have absolutely nothing to display
    if (!hasInMemoryData && !showedDiskCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Fetch only workout metadata (no exercises) — significantly smaller payload
      final response = await SupabaseConfig.client
          .from('workouts')
          .select('*')
          .order('created_at', ascending: false);

      // Preserve already-loaded exercises so a background refresh doesn't
      // clear them for workouts the user has already opened
      final Map<String, List<Exercise>> existingExercises = {
        for (final w in _workouts)
          if (w.exercises.isNotEmpty) w.id: w.exercises,
      };

      _workouts = _parseWorkoutList(response as List).map((w) {
        // Preferir snapshot; si está vacío, revisar el estado ACTUAL de _workouts
        // porque ensureExercisesLoaded pudo haberlo actualizado mientras este
        // fetch de Supabase estaba en vuelo (condición de carrera).
        final snapshotEx = existingExercises[w.id];
        final currentEx = _workouts
            .firstWhere((cw) => cw.id == w.id, orElse: () => w)
            .exercises;
        final kept = (snapshotEx != null && snapshotEx.isNotEmpty)
            ? snapshotEx
            : currentEx.isNotEmpty
                ? currentEx
                : null;
        if (kept != null && kept.isNotEmpty) {
          return Workout(
            id: w.id,
            name: w.name,
            duration: w.duration,
            exerciseCount: w.exerciseCount,
            imageUrl: w.imageUrl,
            description: w.description,
            createdBy: w.createdBy,
            category: w.category,
            exercises: kept,
          );
        }
        return w;
      }).toList();

      await OfflineCacheService().saveWorkouts(response as List);
      // Descargar en segundo plano los ejercicios de todas las rutinas para
      // poder entrenar sin conexión.
      unawaited(_prefetchExercises());

      _lastFetch = DateTime.now();
      _isOffline = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Network error — keep whatever we already have (stale memory or disk cache)
      _errorMessage = 'server_connection_failed';
      if (_workouts.isEmpty) {
        try {
          final cached = await OfflineCacheService().loadWorkouts();
          if (cached != null && cached.isNotEmpty) {
            _workouts = _parseWorkoutList(cached);
            _isOffline = true;
            debugPrint('📦 Workouts cargados desde caché local (modo offline)');
          }
        } catch (e) {
          debugPrint('Error loading offline cache: $e');
        }
      } else {
        _isOffline = true;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads exercises for [workoutId] from Supabase.
  /// Skips the fetch if exercises are already in memory to avoid
  /// overwriting valid cached data with an empty network response.
  /// Called when entering workout detail or starting a workout session.
  Future<void> ensureExercisesLoaded(String workoutId) async {
    final idx = _workouts.indexWhere((w) => w.id == workoutId);
    if (idx == -1) return;

    // Si ya hay ejercicios en memoria, no es necesario volver a buscarlos
    if (_workouts[idx].exercises.isNotEmpty) return;

    try {
      List<dynamic> rows;
      try {
        rows = await SupabaseConfig.client
            .from('exercises')
            .select('*')
            .eq('workout_id', workoutId)
            .order('order_index', ascending: true);
        unawaited(OfflineCacheService().saveExercises({workoutId: rows}));
      } catch (e) {
        // Sin conexión: usar la copia guardada en el dispositivo
        final cached = await OfflineCacheService().loadExercises(workoutId);
        if (cached == null) rethrow;
        rows = cached;
        _isOffline = true;
      }

      final exercises = rows
          .map((e) => Exercise.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      if (exercises.isEmpty) return;
      // La lista pudo cambiar mientras se esperaba la respuesta
      final idxNow = _workouts.indexWhere((w) => w.id == workoutId);
      if (idxNow == -1) return;

      final w = _workouts[idxNow];
      _workouts[idxNow] = Workout(
        id: w.id,
        name: w.name,
        duration: w.duration,
        exerciseCount: w.exerciseCount,
        imageUrl: w.imageUrl,
        description: w.description,
        createdBy: w.createdBy,
        category: w.category,
        exercises: exercises,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading exercises for workout $workoutId: $e');
    }
  }

  /// Descarga y guarda en caché los ejercicios de todas las rutinas
  /// visibles, en una sola consulta.
  Future<void> _prefetchExercises() async {
    final ids = _workouts.map((w) => w.id).toList();
    if (ids.isEmpty) return;
    try {
      final rows = await SupabaseConfig.client
          .from('exercises')
          .select('*')
          .inFilter('workout_id', ids)
          .order('order_index', ascending: true);
      final byWorkout = <String, List<dynamic>>{};
      for (final r in rows as List) {
        final wid = (r as Map)['workout_id']?.toString();
        if (wid == null) continue;
        byWorkout.putIfAbsent(wid, () => []).add(r);
      }
      await OfflineCacheService().saveExercises(byWorkout);
    } catch (e) {
      debugPrint('Prefetch de ejercicios falló (se reintentará): $e');
    }
  }

  /// Categorías (objetivos) que tienen al menos una rutina, para filtrar.
  List<String> get categoriesInUse {
    final set = {
      for (final w in _workouts)
        if ((w.category ?? '').isNotEmpty) w.category!
    };
    return set.toList()..sort();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Workout> get filteredWorkouts {
    var list = _selectedFilter == 'Todos'
        ? _workouts
        : _workouts.where((w) => w.category == _selectedFilter).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((w) => w.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  Future<void> addWorkout(Workout workout, {String? userId}) async {
    if (_isOffline) {
      throw Exception('offline_create');
    }
    try {
      // Insertar rutina
      final workoutData = await SupabaseConfig.client
          .from('workouts')
          .insert({
            'name': workout.name,
            'duration': workout.duration,
            'exercise_count': workout.exercises.length,
            'image_url': workout.imageUrl,
            'description': workout.description,
            'created_by': userId,
            'category': workout.category,
          })
          .select()
          .single();

      final workoutId = workoutData['id'] as String;

      // Insertar ejercicios y recuperarlos con sus IDs generados por la BD
      List<Exercise> freshExercises = [];
      if (workout.exercises.isNotEmpty) {
        final exercisesData = normalizeSupersets(workout.exercises)
            .asMap()
            .entries
            .map((entry) => {
                  'workout_id': workoutId,
                  'name': entry.value.name,
                  'sets': entry.value.sets,
                  'reps': entry.value.reps.toString(),
                  'rest_time': entry.value.restSeconds,
                  'muscle_group': entry.value.muscleGroup,
                  'instructions': entry.value.description,
                  'order_index': entry.key,
                  'video_url': entry.value.videoUrl,
                  // Peso sugerido por el entrenador (antes no se guardaba)
                  'weight_kg': entry.value.weightKgForDb,
                  'superset_group': entry.value.supersetGroup,
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);

        // Leer ejercicios recién insertados (con IDs de la BD)
        final freshEx = await SupabaseConfig.client
            .from('exercises')
            .select('*')
            .eq('workout_id', workoutId)
            .order('order_index', ascending: true);
        freshExercises = (freshEx as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Agregar la rutina nueva directamente a memoria (sin loadWorkouts)
      final newWorkout = Workout(
        id: workoutId,
        name: workout.name,
        duration: workout.duration,
        exerciseCount: freshExercises.length,
        imageUrl: workout.imageUrl,
        description: workout.description,
        createdBy: userId,
        category: workout.category,
        exercises: freshExercises,
      );
      _workouts.insert(0, newWorkout);
      _lastFetch = DateTime.now(); // Reiniciar TTL
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding workout: $e');
      rethrow;
    }
  }

  Workout? getWorkoutById(String workoutId) {
    try {
      return _workouts.firstWhere((w) => w.id == workoutId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateWorkout(String workoutId, Workout workout) async {
    if (_isOffline) {
      throw Exception('offline_edit');
    }
    try {
      // Guardar IDs de ejercicios anteriores ANTES de cualquier modificación.
      // Así, si el insert posterior falla, los ejercicios siguen existiendo en la BD.
      final currentIdx = _workouts.indexWhere((w) => w.id == workoutId);
      final oldExerciseIds = currentIdx != -1
          ? _workouts[currentIdx]
              .exercises
              .map((e) => e.id)
              .where((id) => id.isNotEmpty)
              .toList()
          : <String>[];

      // Actualizar metadatos de la rutina
      await SupabaseConfig.client.from('workouts').update({
        'name': workout.name,
        'duration': workout.duration,
        'exercise_count': workout.exercises.length,
        'image_url': workout.imageUrl,
        'description': workout.description,
      }).eq('id', workoutId);

      // Insertar nuevos ejercicios PRIMERO.
      // Si este paso falla, los ejercicios anteriores siguen en la BD (no se pierden).
      if (workout.exercises.isNotEmpty) {
        final exercisesData = normalizeSupersets(workout.exercises)
            .asMap()
            .entries
            .map((entry) => {
                  'workout_id': workoutId,
                  'name': entry.value.name,
                  'sets': entry.value.sets,
                  'reps': entry.value.reps.toString(),
                  'rest_time': entry.value.restSeconds,
                  'muscle_group': entry.value.muscleGroup,
                  'instructions': entry.value.description,
                  'order_index': entry.key,
                  'video_url': entry.value.videoUrl,
                  // Peso sugerido por el entrenador (antes no se guardaba)
                  'weight_kg': entry.value.weightKgForDb,
                  'superset_group': entry.value.supersetGroup,
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);
      }

      // Eliminar ejercicios anteriores por sus IDs específicos,
      // SOLO después de que los nuevos se insertaron correctamente.
      if (oldExerciseIds.isNotEmpty) {
        await SupabaseConfig.client
            .from('exercises')
            .delete()
            .filter('id', 'in', '("${oldExerciseIds.join('","')}")');
      }

      // Leer ejercicios recién insertados desde Supabase (con IDs de la BD)
      final freshEx = await SupabaseConfig.client
          .from('exercises')
          .select('*')
          .eq('workout_id', workoutId)
          .order('order_index', ascending: true);
      final freshExercises = (freshEx as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      // Actualizar memoria directamente: sin loadWorkouts, sin condiciones de carrera
      final idx = _workouts.indexWhere((w) => w.id == workoutId);
      if (idx != -1) {
        final w = _workouts[idx];
        _workouts[idx] = Workout(
          id: w.id,
          name: workout.name,
          duration: workout.duration,
          exerciseCount: freshExercises.length,
          imageUrl: workout.imageUrl,
          description: workout.description,
          createdBy: w.createdBy,
          category: w.category,
          exercises: freshExercises,
        );
      }
      _lastFetch = DateTime.now(); // Reiniciar TTL
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating workout: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    if (_isOffline) {
      throw Exception('offline_delete');
    }
    try {
      // Eliminar ejercicios primero (CASCADE debe hacerlo automático, pero por si acaso)
      await SupabaseConfig.client
          .from('exercises')
          .delete()
          .eq('workout_id', workoutId);

      // Eliminar rutina
      await SupabaseConfig.client.from('workouts').delete().eq('id', workoutId);

      await loadWorkouts(
        forceRefresh: true,
        userId: _currentUserId,
        isAdmin: _isAdmin,
      );
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      rethrow;
    }
  }

}
