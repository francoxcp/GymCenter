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

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    String? level,
    int? activeDays,
    int? completedWorkouts,
    String? assignedWorkoutId,
    String? assignedMealPlanId,
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
      assignedWorkoutId: assignedWorkoutId ?? this.assignedWorkoutId,
      assignedMealPlanId: assignedMealPlanId ?? this.assignedMealPlanId,
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
