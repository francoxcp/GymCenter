class WorkoutSession {
  final String id;
  final String userId;
  final String workoutId;
  final DateTime date;
  final int durationMinutes;
  final List<ExerciseProgress> exercisesCompleted;
  final bool isCompleted;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.date,
    this.durationMinutes = 0,
    this.exercisesCompleted = const [],
    this.isCompleted = false,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      userId: json['userId'],
      workoutId: json['workoutId'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'] ?? 0,
      exercisesCompleted: (json['exercisesCompleted'] as List?)
              ?.map((e) => ExerciseProgress.fromJson(e))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'workoutId': workoutId,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'exercisesCompleted': exercisesCompleted.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }
}

class ExerciseProgress {
  final String exerciseId;
  final List<bool>
      setsCompleted; // cada elemento representa si se completó una serie
  final String? notes;

  ExerciseProgress({
    required this.exerciseId,
    required this.setsCompleted,
    this.notes,
  });

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      exerciseId: json['exerciseId'],
      setsCompleted: List<bool>.from(json['setsCompleted']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'setsCompleted': setsCompleted,
      'notes': notes,
    };
  }
}
