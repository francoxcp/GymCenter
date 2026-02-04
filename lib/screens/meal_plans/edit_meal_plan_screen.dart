import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../models/meal_plan.dart';
import '../../providers/meal_plan_provider.dart';

class EditMealPlanScreen extends StatefulWidget {
  final MealPlan mealPlan;

  const EditMealPlanScreen({super.key, required this.mealPlan});

  @override
  State<EditMealPlanScreen> createState() => _EditMealPlanScreenState();
}

class _EditMealPlanScreenState extends State<EditMealPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();

  final List<Map<String, dynamic>> _meals = [];
  bool _isLoading = false;
  int _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.mealPlan.name;
    _descriptionController.text = widget.mealPlan.description;
    _caloriesController.text = widget.mealPlan.calories.toString();
    _totalCalories = widget.mealPlan.calories;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMIN PORTAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Editar Plan Alimenticio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Plan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calorías Totales',
                        border: OutlineInputBorder(),
                        suffixText: 'kcal',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _totalCalories = int.tryParse(value) ?? 0;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa las calorías';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'COMIDAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addMeal,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_meals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'No hay comidas. Toca "Agregar" para comenzar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._meals.asMap().entries.map((entry) {
                        final index = entry.key;
                        final meal = entry.value;
                        return _MealCard(
                          meal: meal,
                          onEdit: () => _editMeal(index),
                          onDelete: () => _removeMeal(index),
                        );
                      }),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calorías del Plan:',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$_totalCalories kcal',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveMealPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _addMeal() {
    _showMealDialog();
  }

  void _editMeal(int index) {
    _showMealDialog(meal: _meals[index], index: index);
  }

  void _removeMeal(int index) {
    setState(() {
      _meals.removeAt(index);
    });
  }

  void _showMealDialog({Map<String, dynamic>? meal, int? index}) {
    final nameController = TextEditingController(text: meal?['name'] ?? '');
    final caloriesController =
        TextEditingController(text: meal?['calories']?.toString() ?? '');
    final descController =
        TextEditingController(text: meal?['description'] ?? '');
    String mealTime = meal?['time'] ?? 'Desayuno';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(meal == null ? 'Nueva Comida' : 'Editar Comida'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Calorías', suffixText: 'kcal'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: mealTime,
                decoration: const InputDecoration(labelText: 'Momento del Día'),
                items: [
                  'Desayuno',
                  'Media Mañana',
                  'Almuerzo',
                  'Merienda',
                  'Cena',
                  'Post-Entreno'
                ]
                    .map((time) =>
                        DropdownMenuItem(value: time, child: Text(time)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) mealTime = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newMeal = {
                'name': nameController.text,
                'calories': int.tryParse(caloriesController.text) ?? 0,
                'time': mealTime,
                'description': descController.text,
              };

              setState(() {
                if (index != null) {
                  _meals[index] = newMeal;
                } else {
                  _meals.add(newMeal);
                }
              });

              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMealPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);

    final updatedPlan = MealPlan(
      id: widget.mealPlan.id,
      name: _nameController.text,
      description: _descriptionController.text,
      calories: int.parse(_caloriesController.text),
      category: widget.mealPlan.category,
      iconType: widget.mealPlan.iconType,
    );

    try {
      await mealPlanProvider.updateMealPlan(
        widget.mealPlan.id,
        updatedPlan,
        meals: _meals.isNotEmpty ? _meals : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar "${widget.mealPlan.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _deleteMealPlan,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMealPlan() async {
    Navigator.pop(context); // Close dialog

    setState(() => _isLoading = true);

    final mealPlanProvider =
        Provider.of<MealPlanProvider>(context, listen: false);

    try {
      await mealPlanProvider.deleteMealPlan(widget.mealPlan.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: AppColors.primary),
        ),
        title: Text(
          meal['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${meal['calories'] ?? 0} kcal • ${meal['time'] ?? ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
