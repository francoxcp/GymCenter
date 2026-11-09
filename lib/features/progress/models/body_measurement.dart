/// Una medición corporal. Peso en kg, % de grasa y circunferencias en cm.
class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? bodyFat;
  final double? neck;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? bicepsLeft;
  final double? bicepsRight;
  final double? forearm;
  final double? thighLeft;
  final double? thighRight;
  final double? calf;
  final String? photoUrl;
  final String? notes;

  /// Quién la registró (el socio o su entrenador).
  final String? recordedBy;

  BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.bodyFat,
    this.neck,
    this.chest,
    this.waist,
    this.hips,
    this.bicepsLeft,
    this.bicepsRight,
    this.forearm,
    this.thighLeft,
    this.thighRight,
    this.calf,
    this.photoUrl,
    this.notes,
    this.recordedBy,
  });

  static double? _d(dynamic v) => (v as num?)?.toDouble();

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      weight: _d(json['weight']),
      bodyFat: _d(json['body_fat']),
      neck: _d(json['neck']),
      chest: _d(json['chest']),
      waist: _d(json['waist']),
      hips: _d(json['hips']),
      bicepsLeft: _d(json['biceps_left']),
      bicepsRight: _d(json['biceps_right']),
      forearm: _d(json['forearm']),
      thighLeft: _d(json['thigh_left']),
      thighRight: _d(json['thigh_right']),
      calf: _d(json['calf']),
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'body_fat': bodyFat,
      'neck': neck,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps_left': bicepsLeft,
      'biceps_right': bicepsRight,
      'forearm': forearm,
      'thigh_left': thighLeft,
      'thigh_right': thighRight,
      'calf': calf,
      'photo_url': photoUrl,
      'notes': notes,
      'recorded_by': recordedBy,
    };
    if (id.isNotEmpty) json['id'] = id;
    return json;
  }

  BodyMeasurement copyWith({String? id, String? userId, String? recordedBy}) =>
      BodyMeasurement(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date,
        weight: weight,
        bodyFat: bodyFat,
        neck: neck,
        chest: chest,
        waist: waist,
        hips: hips,
        bicepsLeft: bicepsLeft,
        bicepsRight: bicepsRight,
        forearm: forearm,
        thighLeft: thighLeft,
        thighRight: thighRight,
        calf: calf,
        photoUrl: photoUrl,
        notes: notes,
        recordedBy: recordedBy ?? this.recordedBy,
      );

  double? valueOf(MeasureField f) => switch (f) {
        MeasureField.weight => weight,
        MeasureField.bodyFat => bodyFat,
        MeasureField.neck => neck,
        MeasureField.chest => chest,
        MeasureField.waist => waist,
        MeasureField.hips => hips,
        MeasureField.bicepsLeft => bicepsLeft,
        MeasureField.bicepsRight => bicepsRight,
        MeasureField.forearm => forearm,
        MeasureField.thighLeft => thighLeft,
        MeasureField.thighRight => thighRight,
        MeasureField.calf => calf,
      };

  /// Construye una medición desde los valores del formulario.
  static BodyMeasurement fromValues({
    String id = '',
    required String userId,
    required DateTime date,
    required Map<MeasureField, double?> values,
    String? notes,
    String? recordedBy,
  }) =>
      BodyMeasurement(
        id: id,
        userId: userId,
        date: date,
        weight: values[MeasureField.weight],
        bodyFat: values[MeasureField.bodyFat],
        neck: values[MeasureField.neck],
        chest: values[MeasureField.chest],
        waist: values[MeasureField.waist],
        hips: values[MeasureField.hips],
        bicepsLeft: values[MeasureField.bicepsLeft],
        bicepsRight: values[MeasureField.bicepsRight],
        forearm: values[MeasureField.forearm],
        thighLeft: values[MeasureField.thighLeft],
        thighRight: values[MeasureField.thighRight],
        calf: values[MeasureField.calf],
        notes: notes,
        recordedBy: recordedBy,
      );

  bool get isEmpty => MeasureField.values.every((f) => valueOf(f) == null);
}

/// Medidas que se registran, agrupadas como se toman en el gimnasio.
enum MeasureField {
  weight('Peso', 'kg', 'Cuerpo', 20, 300),
  bodyFat('% grasa', '%', 'Cuerpo', 2, 70),
  neck('Cuello', 'cm', 'Tronco', 20, 70),
  chest('Pecho', 'cm', 'Tronco', 50, 200),
  waist('Cintura', 'cm', 'Tronco', 40, 200),
  hips('Cadera', 'cm', 'Tronco', 50, 200),
  bicepsLeft('Bíceps izq.', 'cm', 'Brazos', 15, 70),
  bicepsRight('Bíceps der.', 'cm', 'Brazos', 15, 70),
  forearm('Antebrazo', 'cm', 'Brazos', 15, 60),
  thighLeft('Muslo izq.', 'cm', 'Piernas', 30, 100),
  thighRight('Muslo der.', 'cm', 'Piernas', 30, 100),
  calf('Pantorrilla', 'cm', 'Piernas', 20, 70);

  final String label;
  final String unit;
  final String group;
  final double min;
  final double max;
  const MeasureField(this.label, this.unit, this.group, this.min, this.max);

  /// En cintura, cadera y % grasa bajar es progreso; en el resto, depende
  /// del objetivo, así que solo se muestra el cambio sin juzgarlo.
  bool get lowerIsBetter =>
      this == MeasureField.waist || this == MeasureField.bodyFat;

  static List<String> get groups =>
      MeasureField.values.map((f) => f.group).toSet().toList();
}
