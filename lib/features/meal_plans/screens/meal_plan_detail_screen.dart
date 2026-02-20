import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/meal_plan.dart';

class MealPlanDetailScreen extends StatelessWidget {
  final String mealPlanId;

  const MealPlanDetailScreen({
    super.key,
    required this.mealPlanId,
  });

  @override
  Widget build(BuildContext context) {
    // Usando datos de ejemplo - conectar con MealPlanProvider para datos reales
    final mealPlan = _getExampleMealPlan();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(mealPlan.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con info general
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIconForType(mealPlan.iconType),
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mealPlan.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mealPlan.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoCard('Calorías', '${mealPlan.calories}',
                          Icons.local_fire_department),
                      _buildInfoCard('Proteínas', '150g', Icons.egg),
                      _buildInfoCard('Carbos', '200g', Icons.rice_bowl),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de comidas del día
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan del Día',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMealCard(
                    'Desayuno',
                    '7:00 AM',
                    Icons.wb_sunny_outlined,
                    Colors.orange,
                    [
                      'Avena con frutas (300 cal)',
                      '2 huevos revueltos (140 cal)',
                      'Café con leche (60 cal)',
                    ],
                  ),
                  _buildMealCard(
                    'Media Mañana',
                    '10:00 AM',
                    Icons.coffee,
                    Colors.brown,
                    [
                      'Yogurt griego (120 cal)',
                      'Almendras (80 cal)',
                    ],
                  ),
                  _buildMealCard(
                    'Almuerzo',
                    '1:00 PM',
                    Icons.restaurant,
                    Colors.green,
                    [
                      'Pechuga de pollo a la plancha (200 cal)',
                      'Arroz integral (150 cal)',
                      'Ensalada verde (50 cal)',
                      'Agua de limón (0 cal)',
                    ],
                  ),
                  _buildMealCard(
                    'Merienda',
                    '4:00 PM',
                    Icons.lunch_dining,
                    Colors.purple,
                    [
                      'Batido de proteína (150 cal)',
                      'Plátano (90 cal)',
                    ],
                  ),
                  _buildMealCard(
                    'Cena',
                    '7:00 PM',
                    Icons.dinner_dining,
                    Colors.blue,
                    [
                      'Salmón a la plancha (250 cal)',
                      'Vegetales al vapor (80 cal)',
                      'Batata asada (120 cal)',
                    ],
                  ),
                ],
              ),
            ),

            // Consejos
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Consejos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Bebe al menos 2 litros de agua al día'),
                    _buildTip(
                        'Puedes ajustar las porciones según tu peso y objetivo'),
                    _buildTip(
                        'Prepara las comidas con anticipación para ahorrar tiempo'),
                    _buildTip('Evita alimentos procesados y azúcares añadidos'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    String title,
    String time,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppColors.primary, fontSize: 16),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String iconType) {
    switch (iconType) {
      case 'fork':
        return Icons.restaurant;
      case 'leaf':
        return Icons.eco;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.restaurant;
    }
  }

  MealPlan _getExampleMealPlan() {
    return MealPlan(
      id: mealPlanId,
      name: 'Plan Balanceado 2000 Cal',
      description: 'Nutrición equilibrada para mantener tu peso ideal',
      calories: 2000,
      category: 'Mantenimiento',
      iconType: 'fork',
    );
  }
}
