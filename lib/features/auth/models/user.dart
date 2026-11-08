class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'admin' (dueño) | 'trainer' (entrenador) | 'user' (socio)
  final String level; // 'Principiante', 'Intermedio', 'Avanzado'
  final int activeDays;
  final int completedWorkouts;
  final String? assignedWorkoutId;
  final String? assignedMealPlanId;
  // Datos de fitness para cálculo preciso de calorías
  final int? age;          // años
  final double? weightKg;  // kg
  final int? heightCm;     // centimetros
  final String? sex;       // 'male' | 'female' | 'other'
  // Entrenador asignado (socios) y código para vincular socios (personal)
  final String? trainerId;
  final String? trainerCode;

  bool get isAdmin => role == 'admin';
  bool get isTrainer => role == 'trainer';
  /// Dueño o entrenador: accede al panel de gestión.
  bool get isStaff => isAdmin || isTrainer;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    this.level = 'Principiante',
    this.activeDays = 0,
    this.completedWorkouts = 0,
    this.assignedWorkoutId,
    this.assignedMealPlanId,
    this.age,
    this.weightKg,
    this.heightCm,
    this.sex,
    this.trainerId,
    this.trainerCode,
  });

  static const _sentinel = Object();

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    String? level,
    int? activeDays,
    int? completedWorkouts,
    Object? assignedWorkoutId = _sentinel,
    Object? assignedMealPlanId = _sentinel,
    Object? age = _sentinel,
    Object? weightKg = _sentinel,
    Object? heightCm = _sentinel,
    Object? sex = _sentinel,
    Object? trainerId = _sentinel,
    Object? trainerCode = _sentinel,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      level: level ?? this.level,
      activeDays: activeDays ?? this.activeDays,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
      assignedWorkoutId: assignedWorkoutId == _sentinel
          ? this.assignedWorkoutId
          : assignedWorkoutId as String?,
      assignedMealPlanId: assignedMealPlanId == _sentinel
          ? this.assignedMealPlanId
          : assignedMealPlanId as String?,
      age: age == _sentinel ? this.age : age as int?,
      weightKg: weightKg == _sentinel ? this.weightKg : weightKg as double?,
      heightCm: heightCm == _sentinel ? this.heightCm : heightCm as int?,
      sex: sex == _sentinel ? this.sex : sex as String?,
      trainerId:
          trainerId == _sentinel ? this.trainerId : trainerId as String?,
      trainerCode:
          trainerCode == _sentinel ? this.trainerCode : trainerCode as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      role: json['role'] ?? 'user',
      level: json['level'] ?? 'Principiante',
      activeDays: json['active_days'] ?? json['activeDays'] ?? 0,
      completedWorkouts:
          json['completed_workouts'] ?? json['completedWorkouts'] ?? 0,
      assignedWorkoutId: json['assigned_workout_id'],
      assignedMealPlanId: json['assigned_meal_plan_id'],
      age: json['age'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: json['height_cm'] as int?,
      sex: json['sex'] as String?,
      trainerId: json['trainer_id'] as String?,
      trainerCode: json['trainer_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'level': level,
      'activeDays': activeDays,
      'completedWorkouts': completedWorkouts,
      'assignedWorkoutId': assignedWorkoutId,
      'assignedMealPlanId': assignedMealPlanId,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'sex': sex,
      'trainer_id': trainerId,
      'trainer_code': trainerCode,
    };
  }
}
