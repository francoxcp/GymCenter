import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../../../config/supabase_config.dart';
import '../../../shared/services/offline_cache_service.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  String _selectedFilter = 'Todos';
  bool _isLoading = false;
  bool _isOffline = false;
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
        level: json['level'] ?? 'Principiante',
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
      } catch (_) {}
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
        final kept = existingExercises[w.id];
        if (kept != null && kept.isNotEmpty) {
          return Workout(
            id: w.id,
            name: w.name,
            duration: w.duration,
            exerciseCount: w.exerciseCount,
            level: w.level,
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

      _lastFetch = DateTime.now();
      _isOffline = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Network error — keep whatever we already have (stale memory or disk cache)
      if (_workouts.isEmpty) {
        try {
          final cached = await OfflineCacheService().loadWorkouts();
          if (cached != null && cached.isNotEmpty) {
            _workouts = _parseWorkoutList(cached);
            _isOffline = true;
            debugPrint('📦 Workouts cargados desde caché local (modo offline)');
          }
        } catch (_) {}
      } else {
        _isOffline = true;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads exercises for [workoutId] on-demand if they are not yet in memory.
  /// Called before entering workout detail or starting a workout session.
  Future<void> ensureExercisesLoaded(String workoutId) async {
    final idx = _workouts.indexWhere((w) => w.id == workoutId);
    if (idx == -1 || idx >= _workouts.length) return;
    if (_workouts[idx].exercises.isNotEmpty) return; // already loaded

    try {
      final response = await SupabaseConfig.client
          .from('exercises')
          .select('*')
          .eq('workout_id', workoutId)
          .order('order_index', ascending: true);

      final exercises = (response as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      // Re-check index after async gap to guard against concurrent list changes
      final currentIdx = _workouts.indexWhere((w) => w.id == workoutId);
      if (currentIdx == -1 || currentIdx >= _workouts.length) return;

      final w = _workouts[currentIdx];
      _workouts[currentIdx] = Workout(
        id: w.id,
        name: w.name,
        duration: w.duration,
        exerciseCount: w.exerciseCount,
        level: w.level,
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
        : _workouts.where((w) => w.level == _selectedFilter).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((w) => w.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  Future<void> addWorkout(Workout workout, {String? userId}) async {
    try {
      // Insertar rutina
      final workoutData = await SupabaseConfig.client
          .from('workouts')
          .insert({
            'name': workout.name,
            'duration': workout.duration,
            'level': workout.level,
            'image_url': workout.imageUrl,
            'description': workout.description,
            'created_by': userId,
            'category': workout.category,
          })
          .select()
          .single();

      final workoutId = workoutData['id'];

      // Insertar ejercicios si existen
      if (workout.exercises.isNotEmpty) {
        final exercisesData = workout.exercises
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
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);
      }

      // Recargar rutinas con los parámetros del usuario actual
      await loadWorkouts(
        userId: _currentUserId,
        isAdmin: _isAdmin,
      );
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
    try {
      // Actualizar rutina
      await SupabaseConfig.client.from('workouts').update({
        'name': workout.name,
        'duration': workout.duration,
        'level': workout.level,
        'image_url': workout.imageUrl,
        'description': workout.description,
      }).eq('id', workoutId);

      // Eliminar ejercicios anteriores
      await SupabaseConfig.client
          .from('exercises')
          .delete()
          .eq('workout_id', workoutId);

      // Insertar ejercicios actualizados
      if (workout.exercises.isNotEmpty) {
        final exercisesData = workout.exercises
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
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);
      }

      await loadWorkouts(
        forceRefresh: true,
        userId: _currentUserId,
        isAdmin: _isAdmin,
      );
    } catch (e) {
      debugPrint('Error updating workout: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
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

  Future<Workout?> loadWorkoutWithExercises(String workoutId) async {
    try {
      final response = await SupabaseConfig.client
          .from('workouts')
          .select('*, exercises(*)')
          .eq('id', workoutId)
          .single();

      final exercisesJson = response['exercises'] as List?;
      List<Exercise> exercises = [];
      if (exercisesJson != null) {
        exercises = exercisesJson.map((e) => Exercise.fromJson(e)).toList();
        exercises.sort((a, b) => a.id.compareTo(b.id));
      }

      return Workout(
        id: response['id'],
        name: response['name'],
        duration: response['duration'],
        exerciseCount: response['exercise_count'] ?? 0,
        level: response['level'] ?? 'Principiante',
        imageUrl: response['image_url'] ?? '',
        description: response['description'],
        exercises: exercises,
      );
    } catch (e) {
      debugPrint('Error loading workout details: $e');
      return null;
    }
  }
}
