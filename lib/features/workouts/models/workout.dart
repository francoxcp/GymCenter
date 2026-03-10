import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final int duration; // en minutos
  final int exerciseCount;
  final String level; // Principiante, Intermedio, Avanzado
  final String imageUrl;
  final String? description;
  final String? createdBy; // ID del usuario que creó la rutina (null = admin)
  final String? category; // Pecho, Espalda, Pierna, Cardio, Funcional
  final List<Exercise> exercises;

  static const List<String> categories = [
    'Pecho',
    'Espalda',
    'Pierna',
    'Cardio',
    'Funcional',
  ];

  Workout({
    required this.id,
    required this.name,
    required this.duration,
    required this.exerciseCount,
    required this.level,
    required this.imageUrl,
    this.description,
    this.createdBy,
    this.category,
    this.exercises = const [],
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      exerciseCount:
          (json['exercise_count'] ?? json['exerciseCount'] ?? 0) as int,
      level: json['level'] as String? ?? 'Principiante',
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      description: json['description'] as String?,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String?,
      category: json['category'] as String?,
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
      'createdBy': createdBy,
      'category': category,
    };
  }
}
