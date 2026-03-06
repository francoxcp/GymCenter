import 'package:flutter/material.dart';
import 'create_meal_plan_screen.dart';
import 'edit_meal_plan_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/meal_plan_provider.dart';
import '../../../shared/widgets/filter_chip_button.dart';

class MealPlanListScreen extends StatefulWidget {
  const MealPlanListScreen({super.key});

  @override
  State<MealPlanListScreen> createState() => _MealPlanListScreenState();
}

class _MealPlanListScreenState extends State<MealPlanListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carga lazy: se dispara al abrir la pantalla por primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealPlanProvider>(context, listen: false).loadMealPlans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForType(String iconType) {
    switch (iconType) {
      case 'fork':
        return Icons.restaurant;
      case 'leaf':
        return Icons.eco;
      case 'burger':
        return Icons.lunch_dining;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.restaurant_menu;
    }
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
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
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

              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  'EN DESARROLLO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        text: 'Comidas por día: desayuno, almuerzo, merienda y cena'),
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

  // ignore: unused_element — reservado para futura implementación
  Widget _buildAdminContent(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, mealPlanProvider, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMINISTRACIÓN',
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChipButton(
                      label: 'TODOS',
                      isSelected: mealPlanProvider.selectedFilter == 'TODOS',
                      onTap: () => mealPlanProvider.setFilter('TODOS'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'KETO',
                      isSelected: mealPlanProvider.selectedFilter == 'KETO',
                      onTap: () => mealPlanProvider.setFilter('KETO'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'VEGANO',
                      isSelected: mealPlanProvider.selectedFilter == 'VEGANO',
                      onTap: () => mealPlanProvider.setFilter('VEGANO'),
                    ),
                    const SizedBox(width: 8),
                    FilterChipButton(
                      label: 'HIPER',
                      isSelected: mealPlanProvider.selectedFilter == 'HIPER',
                      onTap: () => mealPlanProvider.setFilter('HIPER'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Meal Plan List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      mealPlanProvider.loadMealPlans(forceRefresh: true),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mealPlanProvider.filteredMealPlans.length,
                    itemBuilder: (context, index) {
                      final plan =
                          mealPlanProvider.filteredMealPlans[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () =>
                              context.push('/meal-plan-detail/${plan.id}'),
                          child: _MealPlanCard(
                            name: plan.name,
                            description: plan.description,
                            calories: plan.calories,
                            icon: _getIconForType(plan.iconType),
                            isAdmin: true,
                            onEdit: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditMealPlanScreen(mealPlan: plan),
                                ),
                              );
                              if (result == true) {
                                mealPlanProvider.loadMealPlans(
                                    forceRefresh: true);
                              }
                            },
                            onDelete: () async {
                              final shouldDelete =
                                  await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  title: const Text(
                                    '¿Eliminar plan?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    '¿Estás seguro de eliminar "${plan.name}"? Esta acción no se puede deshacer.',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(
                                            color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldDelete == true) {
                                try {
                                  await mealPlanProvider
                                      .deleteMealPlan(plan.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Plan eliminado correctamente'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al eliminar: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider =
                  Provider.of<MealPlanProvider>(context, listen: false);
              final result = await navigator.push(
                MaterialPageRoute(
                  builder: (context) => const CreateMealPlanScreen(),
                ),
              );
              if (result == true) {
                await provider.loadMealPlans(forceRefresh: true);
              }
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.black, size: 32),
          ),
        );
      },
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

class _MealPlanCard extends StatelessWidget {
  final String name;
  final String description;
  final int calories;
  final IconData icon;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MealPlanCard({
    required this.name,
    required this.description,
    required this.calories,
    required this.icon,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  onEdit!();
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Editar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
