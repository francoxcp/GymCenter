import 'package:flutter/material.dart';
import 'create_meal_plan_screen.dart';
import 'edit_meal_plan_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/filter_chip_button.dart';

class MealPlanListScreen extends StatefulWidget {
  const MealPlanListScreen({super.key});

  @override
  State<MealPlanListScreen> createState() => _MealPlanListScreenState();
}

class _MealPlanListScreenState extends State<MealPlanListScreen> {
  final _searchController = TextEditingController();

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
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

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
              'Planes de Alimentación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, mealPlanProvider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar plan por nombre...',
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
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mealPlanProvider.filteredMealPlans.length,
                  itemBuilder: (context, index) {
                    final plan = mealPlanProvider.filteredMealPlans[index];
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
                          isAdmin: isAdmin,
                          onEdit: isAdmin
                              ? () async {
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
                                }
                              : null,
                          onDelete: isAdmin
                              ? () async {
                                  final shouldDelete = await showDialog<bool>(
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
                                            content:
                                                Text('Error al eliminar: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // New Plan Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'NUEVO PLAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final mealPlanProvider =
              Provider.of<MealPlanProvider>(context, listen: false);

          final result = await navigator.push(
            MaterialPageRoute(
              builder: (context) => const CreateMealPlanScreen(),
            ),
          );

          if (result == true) {
            await mealPlanProvider.loadMealPlans(forceRefresh: true);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 32,
        ),
      ),
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
