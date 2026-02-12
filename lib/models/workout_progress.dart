class WorkoutProgress {
  final String id;
  final String userId;
  final String workoutId;
  final int exerciseIndex;
  final List<List<bool>> completedSets;
  final DateTime startedAt;
  final DateTime updatedAt;

  WorkoutProgress({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.exerciseIndex,
    required this.completedSets,
    required this.startedAt,
    required this.updatedAt,
  });

  factory WorkoutProgress.fromJson(Map<String, dynamic> json) {
    // Parsear completed_sets de JSONB a List<List<bool>>
    List<List<bool>> sets = [];
    if (json['completed_sets'] != null) {
      final setsJson = json['completed_sets'] as List;
      sets = setsJson.map((exerciseSets) {
        return (exerciseSets as List).map((set) => set as bool).toList();
      }).toList();
    }

    return WorkoutProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      workoutId: json['workout_id'] as String,
      exerciseIndex: json['exercise_index'] as int,
      completedSets: sets,
      startedAt: DateTime.parse(json['started_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_id': workoutId,
      'exercise_index': exerciseIndex,
      'completed_sets': completedSets,
      'started_at': startedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper para calcular progreso total
  double get progressPercentage {
    if (completedSets.isEmpty) return 0.0;

    int totalSets = 0;
    int completedCount = 0;

    for (var exerciseSets in completedSets) {
      totalSets += exerciseSets.length;
      completedCount += exerciseSets.where((s) => s).length;
    }

    return totalSets > 0 ? (completedCount / totalSets) * 100 : 0.0;
  }

  // Helper para saber cuánto tiempo ha pasado
  Duration get timeSinceUpdate {
    return DateTime.now().difference(updatedAt);
  }

  // Helper para saber si el progreso está expirado (>24 horas)
  bool get isExpired {
    return timeSinceUpdate.inHours >= 24;
  }
}
