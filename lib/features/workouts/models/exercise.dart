class Exercise {
  final String id;
  final String name;
  final String? description;
  final int sets; // series
  final int reps; // repeticiones
  final int restSeconds; // descanso entre series
  final String? videoUrl;
  final String? thumbnailUrl;
  final String muscleGroup; // grupo muscular
  final String difficulty;
  final double weight; // peso sugerido en kg (0 = sin peso / peso corporal)

  Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.sets,
    required this.reps,
    this.restSeconds = 60,
    this.videoUrl,
    this.thumbnailUrl,
    required this.muscleGroup,
    this.difficulty = 'Intermedio',
    this.weight = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['instructions'] as String? ?? json['description'] as String?,
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      reps: int.tryParse(json['reps'].toString()) ?? 12,
      restSeconds:
          (json['rest_time'] ?? json['restSeconds'] ?? 60) as int,
      videoUrl: json['video_url'] as String? ?? json['videoUrl'] as String?,
      thumbnailUrl:
          json['thumbnail_url'] as String? ?? json['thumbnailUrl'] as String?,
      muscleGroup:
          json['muscle_group'] as String? ?? json['muscleGroup'] as String? ?? 'General',
      difficulty: json['difficulty'] as String? ?? 'Intermedio',
      weight: ((json['weight'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'muscleGroup': muscleGroup,
      'difficulty': difficulty,
      'weight': weight,
    };
  }
}
