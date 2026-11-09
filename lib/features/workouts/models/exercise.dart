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
  final double weight; // peso sugerido en lbs (0 = sin peso / peso corporal)
  /// Ejercicios consecutivos con el mismo valor forman una superserie.
  /// En ellos `sets` son las rondas y `restSeconds` el descanso por ronda.
  final String? supersetGroup;

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
    this.supersetGroup,
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
      // En la BD el peso sugerido se guarda en kg (columna weight_kg); la app
      // lo maneja en lbs. 'weight' (lbs) se usa en la caché local antigua.
      weight: json['weight_kg'] != null
          ? ((json['weight_kg'] as num).toDouble() * 2.20462 * 10).round() / 10
          : ((json['weight'] ?? 0) as num).toDouble(),
      supersetGroup: _nonEmpty(json['superset_group'] ?? json['supersetGroup']),
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
      'supersetGroup': supersetGroup,
    };
  }

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  bool get inSuperset => supersetGroup != null;

  /// Copia cambiando campos. `clearSuperset` saca el ejercicio de su grupo.
  Exercise copyWith({
    String? id,
    int? sets,
    int? reps,
    int? restSeconds,
    double? weight,
    String? supersetGroup,
    bool clearSuperset = false,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name,
      description: description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      muscleGroup: muscleGroup,
      difficulty: difficulty,
      weight: weight ?? this.weight,
      supersetGroup:
          clearSuperset ? null : (supersetGroup ?? this.supersetGroup),
    );
  }

  /// Peso sugerido convertido a kg para la columna `weight_kg` (null = sin peso).
  double? get weightKgForDb =>
      weight > 0 ? double.parse((weight / 2.20462).toStringAsFixed(2)) : null;
}
