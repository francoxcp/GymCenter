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

/// Objetivos que se eligen al registrarse (mismos textos que la BD).
const kGoals = ['Perder peso', 'Ganar músculo', 'Mantener peso', 'Mejorar salud'];

class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role; // 'admin' (dueño) | 'trainer' (entrenador) | 'user' (socio)
  /// Objetivo que eligió al registrarse (Perder peso, Ganar músculo…).
  final String? goal;
  final int activeDays;
  final int completedWorkouts;
  final String? assignedWorkoutId;
  // Datos de fitness para cálculo preciso de calorías
  final int? age;          // años
  final double? weightKg;  // kg
  final int? heightCm;     // centimetros
  final String? sex;       // 'male' | 'female' | 'other'
  // Entrenador asignado (socios) y código para vincular socios (personal)
  final String? trainerId;
  final String? trainerCode;
  /// Organización (gimnasio o entrenador independiente) a la que pertenece.
  final String? orgId;
  // Membresía (la gestiona el dueño)
  final String? membershipPlan;
  final DateTime? membershipStart;
  final DateTime? membershipEnd;
  /// Teléfono para WhatsApp (opcional).
  final String? phone;
  final DateTime? createdAt;

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
    this.goal,
    this.activeDays = 0,
    this.completedWorkouts = 0,
    this.assignedWorkoutId,
    this.age,
    this.weightKg,
    this.heightCm,
    this.sex,
    this.trainerId,
    this.trainerCode,
    this.orgId,
    this.membershipPlan,
    this.membershipStart,
    this.membershipEnd,
    this.phone,
    this.createdAt,
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
    Object? goal = _sentinel,
    int? activeDays,
    int? completedWorkouts,
    Object? assignedWorkoutId = _sentinel,
    Object? age = _sentinel,
    Object? weightKg = _sentinel,
    Object? heightCm = _sentinel,
    Object? sex = _sentinel,
    Object? trainerId = _sentinel,
    Object? trainerCode = _sentinel,
    Object? membershipPlan = _sentinel,
    Object? membershipStart = _sentinel,
    Object? membershipEnd = _sentinel,
    Object? phone = _sentinel,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      goal: goal == _sentinel ? this.goal : goal as String?,
      activeDays: activeDays ?? this.activeDays,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
      assignedWorkoutId: assignedWorkoutId == _sentinel
          ? this.assignedWorkoutId
          : assignedWorkoutId as String?,
      age: age == _sentinel ? this.age : age as int?,
      weightKg: weightKg == _sentinel ? this.weightKg : weightKg as double?,
      heightCm: heightCm == _sentinel ? this.heightCm : heightCm as int?,
      sex: sex == _sentinel ? this.sex : sex as String?,
      trainerId:
          trainerId == _sentinel ? this.trainerId : trainerId as String?,
      trainerCode:
          trainerCode == _sentinel ? this.trainerCode : trainerCode as String?,
      orgId: orgId,
      membershipPlan: membershipPlan == _sentinel
          ? this.membershipPlan
          : membershipPlan as String?,
      membershipStart: membershipStart == _sentinel
          ? this.membershipStart
          : membershipStart as DateTime?,
      membershipEnd: membershipEnd == _sentinel
          ? this.membershipEnd
          : membershipEnd as DateTime?,
      phone: phone == _sentinel ? this.phone : phone as String?,
      createdAt: createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      role: json['role'] ?? 'user',
      goal: json['goal'] as String?,
      activeDays: json['active_days'] ?? json['activeDays'] ?? 0,
      completedWorkouts:
          json['completed_workouts'] ?? json['completedWorkouts'] ?? 0,
      assignedWorkoutId: json['assigned_workout_id'],
      age: json['age'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: json['height_cm'] as int?,
      sex: json['sex'] as String?,
      trainerId: json['trainer_id'] as String?,
      trainerCode: json['trainer_code'] as String?,
      orgId: json['org_id'] as String?,
      membershipPlan: json['membership_plan'] as String?,
      membershipStart: _date(json['membership_start']),
      membershipEnd: _date(json['membership_end']),
      phone: json['phone'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'goal': goal,
      'activeDays': activeDays,
      'completedWorkouts': completedWorkouts,
      'assignedWorkoutId': assignedWorkoutId,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'sex': sex,
      'trainer_id': trainerId,
      'trainer_code': trainerCode,
      'org_id': orgId,
      'membership_plan': membershipPlan,
      'membership_start': _dateStr(membershipStart),
      'membership_end': _dateStr(membershipEnd),
      'phone': phone,
    };
  }
}
