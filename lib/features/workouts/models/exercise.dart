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
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'].toString(),
      name: json['name'],
      description: json['instructions'] ?? json['description'],
      sets: json['sets'],
      reps: int.tryParse(json['reps'].toString()) ?? 12,
      restSeconds: json['rest_time'] ?? json['restSeconds'] ?? 60,
      videoUrl: json['video_url'] ?? json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      muscleGroup: json['muscle_group'] ?? json['muscleGroup'] ?? 'General',
      difficulty: json['difficulty'] ?? 'Intermedio',
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
    };
  }
}
