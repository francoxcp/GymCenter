import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/meal_plan_provider.dart';

class MealPlanListScreen extends StatefulWidget {
  const MealPlanListScreen({super.key});

  @override
  State<MealPlanListScreen> createState() => _MealPlanListScreenState();
}

class _MealPlanListScreenState extends State<MealPlanListScreen> {
  @override
  void initState() {
    super.initState();
    // Carga lazy: se dispara al abrir la pantalla por primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealPlanProvider>(context, listen: false).loadMealPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHAMOS FITNESS CENTER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Planes de alimentación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              const Text(
                'Próximamente',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              const Text(
                'Los planes de alimentación estarán disponibles en una próxima actualización. Podrás ver tu plan semanal o mensual con las comidas de cada día, tal como te lo indica tu nutricionista.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),

              // Qué vendrá
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lo que vendrá:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    _FeatureItem(
                        icon: Icons.calendar_month,
                        text: 'Plan semanal y mensual (4 semanas)'),
                    SizedBox(height: 8),
                    _FeatureItem(
                        icon: Icons.wb_sunny_outlined,
                        text:
                            'Comidas por día: desayuno, almuerzo, merienda y cena'),
                    SizedBox(height: 8),
                    _FeatureItem(
                        icon: Icons.person_outline,
                        text: 'Asignado por tu nutricionista cada mes'),
                    SizedBox(height: 8),
                    _FeatureItem(
                        icon: Icons.auto_awesome,
                        text: 'Se actualiza automáticamente cada semana'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para la lista de features del "Próximamente"
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
