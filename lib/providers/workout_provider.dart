import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../config/supabase_config.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  String _selectedFilter = 'Todos';
  bool _isLoading = false;
  DateTime? _lastFetch;

  List<Workout> get workouts => _workouts;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  WorkoutProvider() {
    loadWorkouts();
  }

  // Cache por 5 minutos
  bool get _shouldRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!).inMinutes > 5;
  }

  Future<void> loadWorkouts({bool forceRefresh = false}) async {
    if (!forceRefresh && !_shouldRefresh && _workouts.isNotEmpty) {
      return; // Usar caché
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Obtener rutinas con sus ejercicios
      final response = await SupabaseConfig.client
          .from('workouts')
          .select('*, exercises(*)')
          .order('created_at', ascending: false);

      _workouts = (response as List).map((json) {
        // Parsear ejercicios si existen
        final exercisesJson = json['exercises'] as List?;
        List<Exercise> exercises = [];
        if (exercisesJson != null) {
          exercises = exercisesJson.map((e) => Exercise.fromJson(e)).toList();
          exercises.sort((a, b) => a.id.compareTo(b.id));
        }

        return Workout(
          id: json['id'],
          name: json['name'],
          duration: json['duration'],
          exerciseCount: json['exercise_count'] ?? 0,
          level: json['level'] ?? 'Principiante',
          imageUrl: json['image_url'] ?? '',
          description: json['description'],
          exercises: exercises,
        );
      }).toList();

      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading workouts: $e');
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<Workout> get filteredWorkouts {
    if (_selectedFilter == 'Todos') {
      return _workouts;
    }
    return _workouts.where((w) => w.level == _selectedFilter).toList();
  }

  Future<void> addWorkout(Workout workout) async {
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
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);
      }

      await loadWorkouts();
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
                })
            .toList();

        await SupabaseConfig.client.from('exercises').insert(exercisesData);
      }

      await loadWorkouts(forceRefresh: true);
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

      await loadWorkouts(forceRefresh: true);
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
