class UserGoal {
  final String id;
  final String userId;
  final String goalType; // 'weight', 'calories', 'workouts'
  final String title;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calcular porcentaje de progreso (0-100)
  double get progressPercentage {
    if (targetValue == 0) return 0;
    final progress = (currentValue / targetValue * 100).clamp(0, 100);
    return progress.toDouble();
  }

  // Verificar si la meta está completada
  bool get isCompleted => currentValue >= targetValue;

  // Verificar si la meta está vencida
  bool get isExpired => DateTime.now().isAfter(endDate);

  // Días restantes
  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  // Valor restante para completar
  double get remainingValue {
    final remaining = targetValue - currentValue;
    return remaining > 0 ? remaining : 0;
  }

  // Obtener icono según tipo
  String get icon {
    switch (goalType) {
      case 'weight':
        return '⚖️';
      case 'calories':
        return '🔥';
      case 'workouts':
        return '💪';
      default:
        return '🎯';
    }
  }

  // Obtener unidad según tipo
  String get unit {
    switch (goalType) {
      case 'weight':
        return 'kg';
      case 'calories':
        return 'kcal';
      case 'workouts':
        return 'días';
      default:
        return '';
    }
  }

  // Mensaje motivacional según progreso
  String get motivationalMessage {
    if (isCompleted) return '¡Meta completada! 🎉';
    if (isExpired) return 'Meta vencida';

    if (progressPercentage >= 90) return '¡Casi lo logras! 💯';
    if (progressPercentage >= 75) return '¡Excelente ritmo! 🔥';
    if (progressPercentage >= 50) return '¡Vas bien! 💪';
    if (progressPercentage >= 25) return '¡Buen comienzo! 👍';
    return '¡Tú puedes! 🚀';
  }

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      title: json['title'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'title': title,
      'target_value': targetValue,
      'current_value': currentValue,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserGoal copyWith({
    String? id,
    String? userId,
    String? goalType,
    String? title,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      title: title ?? this.title,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
