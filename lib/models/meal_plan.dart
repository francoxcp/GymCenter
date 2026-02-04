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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      calories: json['calories'],
      category: json['category'],
      iconType: json['iconType'],
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
