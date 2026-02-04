import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final int duration; // en minutos
  final int exerciseCount;
  final String level; // Principiante, Intermedio, Avanzado
  final String imageUrl;
  final String? description;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.name,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    required this.imageUrl,
    this.description,
    this.exercises = const [],
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      duration: json['duration'],
      exerciseCount: json['exerciseCount'],
      level: json['level'],
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'],
      exercises: (json['exercises'] as List?)
              ?.map((e) => Exercise.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'name': name,
      'duration': duration,
      'exerciseCount': exerciseCount,
      'level': level,
      'imageUrl': imageUrl,
    };
  }
}
