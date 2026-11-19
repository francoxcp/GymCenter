import '../../../core/utils/weight_units.dart';

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
  /// Peso sugerido en [weightUnit] (0 = sin peso / peso corporal).
  final double weight;
  /// Unidad en que se carga este ejercicio (mancuernas en lbs, máquinas en kg).
  final WeightUnit weightUnit;
  /// Ejercicios consecutivos con el mismo valor forman una superserie.
  /// En ellos `sets` son las rondas y `restSeconds` el descanso por ronda.
  final String? supersetGroup;
  /// Tipo de grupo: 'superset' (sin descanso entre ejercicios) o
  /// 'functional' (circuito con descanso corto entre ejercicios).
  /// null en un grupo = superserie (lo creado antes de los funcionales).
  final String? groupKind;
  /// Descanso entre ejercicios dentro de un grupo funcional (segundos).
  final int groupRestSeconds;
  /// Si > 0, el ejercicio se hace por tiempo (p. ej. 40 s) y no por reps.
  final int durationSeconds;

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
    this.weightUnit = WeightUnit.lbs,
    this.supersetGroup,
    this.groupKind,
    this.groupRestSeconds = 0,
    this.durationSeconds = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final unit = WeightUnit.parse(json['weight_unit'] ?? json['weightUnit']);
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
      // En la BD el peso sugerido se guarda en kg (columna weight_kg) y se
      // muestra en la unidad del ejercicio. 'weight' (ya en esa unidad; lbs
      // en cachés antiguas sin 'weightUnit') viene de la caché local.
      weight: json['weight_kg'] != null
          ? (unit.fromKg((json['weight_kg'] as num).toDouble()) * 10).round() /
              10
          : ((json['weight'] ?? 0) as num).toDouble(),
      weightUnit: unit,
      supersetGroup: _nonEmpty(json['superset_group'] ?? json['supersetGroup']),
      groupKind: _nonEmpty(json['group_kind'] ?? json['groupKind']),
      groupRestSeconds:
          ((json['group_rest_seconds'] ?? json['groupRestSeconds']) as num?)
                  ?.toInt() ??
              0,
      durationSeconds:
          ((json['duration_seconds'] ?? json['durationSeconds']) as num?)
                  ?.toInt() ??
              0,
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
      'weightUnit': weightUnit.name,
      'supersetGroup': supersetGroup,
      'groupKind': groupKind,
      'groupRestSeconds': groupRestSeconds,
      'durationSeconds': durationSeconds,
    };
  }

  /// Ejercicio por tiempo (p. ej. plancha 40 s) en lugar de repeticiones.
  bool get isTimed => durationSeconds > 0;

  /// Dentro de un grupo funcional (circuito).
  bool get isFunctional => inSuperset && groupKind == 'functional';

  /// "15 reps" o "40 s".
  String get amountLabel => isTimed ? '$durationSeconds s' : '$reps reps';

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
    WeightUnit? weightUnit,
    String? supersetGroup,
    bool clearSuperset = false,
    String? groupKind,
    int? groupRestSeconds,
    int? durationSeconds,
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
      weightUnit: weightUnit ?? this.weightUnit,
      supersetGroup:
          clearSuperset ? null : (supersetGroup ?? this.supersetGroup),
      // Al salir de un grupo se limpian sus ajustes
      groupKind: clearSuperset ? null : (groupKind ?? this.groupKind),
      groupRestSeconds:
          clearSuperset ? 0 : (groupRestSeconds ?? this.groupRestSeconds),
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  /// Peso sugerido en kg (0 = sin peso).
  double get weightKg => weight > 0 ? weightUnit.toKg(weight) : 0;

  /// Peso sugerido convertido a kg para la columna `weight_kg` (null = sin peso).
  double? get weightKgForDb =>
      weight > 0 ? double.parse(weightKg.toStringAsFixed(2)) : null;

  /// "45 kg" / "20 lbs", o null sin peso.
  String? get weightLabel => weight > 0 ? weightUnit.format(weight) : null;
}
