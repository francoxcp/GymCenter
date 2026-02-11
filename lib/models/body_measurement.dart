class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thighs;
  final String? photoUrl;
  final String? notes;

  BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.photoUrl,
    this.notes,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      biceps: json['biceps']?.toDouble(),
      thighs: json['thighs']?.toDouble(),
      photoUrl: json['photo_url'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'photo_url': photoUrl,
      'notes': notes,
    };

    // Solo incluir id si no está vacío (para updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    double? height,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thighs,
    String? photoUrl,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      biceps: biceps ?? this.biceps,
      thighs: thighs ?? this.thighs,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
    );
  }
}
