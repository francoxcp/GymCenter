class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'admin' o 'user'
  final String level; // 'Principiante', 'Intermedio', 'Avanzado'
  final int activeDays;
  final int completedWorkouts;
  final String? assignedWorkoutId;
  final String? assignedMealPlanId;

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
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      level: json['level'] as String? ?? 'Principiante',
      activeDays: (json['active_days'] ?? json['activeDays'] ?? 0) as int,
      completedWorkouts:
          (json['completed_workouts'] ?? json['completedWorkouts'] ?? 0) as int,
      assignedWorkoutId:
          json['assigned_workout_id'] as String? ?? json['assignedWorkoutId'] as String?,
      assignedMealPlanId:
          json['assigned_meal_plan_id'] as String? ?? json['assignedMealPlanId'] as String?,
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
    };
  }
}
