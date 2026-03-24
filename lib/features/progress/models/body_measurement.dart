class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  // New per-side fields (new records)
  final double? bicepsLeft;
  final double? bicepsRight;
  final double? thighLeft;
  final double? thighRight;
  // Legacy single fields kept for old records
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
    this.bicepsLeft,
    this.bicepsRight,
    this.thighLeft,
    this.thighRight,
    this.biceps,
    this.thighs,
    this.photoUrl,
    this.notes,
  });

  /// Effective left bicep: new field → fallback to legacy value (Option B).
  double? get effectiveBicepsLeft => bicepsLeft ?? biceps;

  /// Effective right bicep: new field → fallback to legacy value (Option B).
  double? get effectiveBicepsRight => bicepsRight ?? biceps;

  /// Effective left thigh: new field → fallback to legacy value (Option B).
  double? get effectiveThighLeft => thighLeft ?? thighs;

  /// Effective right thigh: new field → fallback to legacy value (Option B).
  double? get effectiveThighRight => thighRight ?? thighs;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      bicepsLeft: (json['biceps_left'] as num?)?.toDouble(),
      bicepsRight: (json['biceps_right'] as num?)?.toDouble(),
      thighLeft: (json['thigh_left'] as num?)?.toDouble(),
      thighRight: (json['thigh_right'] as num?)?.toDouble(),
      // Legacy columns (old records)
      biceps: (json['biceps'] as num?)?.toDouble(),
      thighs: (json['thighs'] as num?)?.toDouble(),
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
      'biceps_left': bicepsLeft,
      'biceps_right': bicepsRight,
      'thigh_left': thighLeft,
      'thigh_right': thighRight,
      'photo_url': photoUrl,
      'notes': notes,
    };

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
    double? bicepsLeft,
    double? bicepsRight,
    double? thighLeft,
    double? thighRight,
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
      bicepsLeft: bicepsLeft ?? this.bicepsLeft,
      bicepsRight: bicepsRight ?? this.bicepsRight,
      thighLeft: thighLeft ?? this.thighLeft,
      thighRight: thighRight ?? this.thighRight,
      // Preserve legacy fields as-is
      biceps: biceps,
      thighs: thighs,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
    );
  }
}
