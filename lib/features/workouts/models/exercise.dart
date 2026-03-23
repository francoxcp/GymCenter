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
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['instructions'] ?? json['description'],
      sets: json['sets'] as int? ?? 3,
      reps: int.tryParse(json['reps'].toString()) ?? 12,
      restSeconds: json['rest_time'] ?? json['restSeconds'] ?? 60,
      videoUrl: json['video_url'] ?? json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      muscleGroup: json['muscle_group'] ?? json['muscleGroup'] ?? 'General',
      difficulty: json['difficulty'] ?? 'Intermedio',
      weight: (json['weight'] ?? 0).toDouble(),
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
