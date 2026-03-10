class MealPlan {
  final String id;
  final String name;
  final String description;
  final int calories;
  final String category;
  final String iconType;

  MealPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.calories,
    required this.category,
    required this.iconType,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      iconType: json['iconType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calories': calories,
      'category': category,
      'iconType': iconType,
    };
  }
}
