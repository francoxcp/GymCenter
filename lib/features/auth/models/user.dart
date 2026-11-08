/// Estado de la membresía según su fecha de vencimiento.
enum MembershipStatus { none, active, expiring, expired }

class Membership {
  Membership._();

  /// Días de aviso antes del vencimiento.
  static const warnDays = 7;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días que faltan (0 = vence hoy, negativo = vencida). Null si no tiene.
  static int? daysLeft(DateTime? end, {DateTime? today}) {
    if (end == null) return null;
    return _day(end).difference(_day(today ?? DateTime.now())).inDays;
  }

  static MembershipStatus status(DateTime? end, {DateTime? today}) {
    final d = daysLeft(end, today: today);
    if (d == null) return MembershipStatus.none;
    if (d < 0) return MembershipStatus.expired;
    if (d <= warnDays) return MembershipStatus.expiring;
    return MembershipStatus.active;
  }

  /// Texto corto en español: "Vence hoy", "Vence en 3 días", "Vencida hace 2 días".
  static String label(DateTime? end, {DateTime? today}) {
    final d = daysLeft(end, today: today);
    if (d == null) return 'Sin membresía';
    if (d == 0) return 'Vence hoy';
    if (d == 1) return 'Vence mañana';
    if (d > 1) return 'Vence en $d días';
    if (d == -1) return 'Venció ayer';
    return 'Vencida hace ${-d} días';
  }
}

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
  // Membresía (la gestiona el dueño)
  final String? membershipPlan;
  final DateTime? membershipStart;
  final DateTime? membershipEnd;

  MembershipStatus get membershipStatus => Membership.status(membershipEnd);

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
    this.membershipPlan,
    this.membershipStart,
    this.membershipEnd,
  });

  static DateTime? _date(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  static String? _dateStr(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    Object? membershipPlan = _sentinel,
    Object? membershipStart = _sentinel,
    Object? membershipEnd = _sentinel,
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
      membershipPlan: membershipPlan == _sentinel
          ? this.membershipPlan
          : membershipPlan as String?,
      membershipStart: membershipStart == _sentinel
          ? this.membershipStart
          : membershipStart as DateTime?,
      membershipEnd: membershipEnd == _sentinel
          ? this.membershipEnd
          : membershipEnd as DateTime?,
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
      membershipPlan: json['membership_plan'] as String?,
      membershipStart: _date(json['membership_start']),
      membershipEnd: _date(json['membership_end']),
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
      'membership_plan': membershipPlan,
      'membership_start': _dateStr(membershipStart),
      'membership_end': _dateStr(membershipEnd),
    };
  }
}
