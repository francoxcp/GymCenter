import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';

class CreateMealPlanScreen extends StatefulWidget {
  const CreateMealPlanScreen({super.key});

  @override
  State<CreateMealPlanScreen> createState() => _CreateMealPlanScreenState();
}

class _CreateMealPlanScreenState extends State<CreateMealPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController(text: '2000');

  String _selectedType = 'masa_muscular';
  final List<Map<String, dynamic>> _meals = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _addMeal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddMealDialog(
        onAdd: (meal) {
          setState(() {
            _meals.add(meal);
          });
        },
      ),
    );
  }

  void _removeMeal(int index) {
    setState(() {
      _meals.removeAt(index);
    });
  }

  Future<void> _saveMealPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una comida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mealPlan = MealPlan(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 2000,
        category: _selectedType,
        iconType: 'restaurant',
      );

      final mealPlanProvider =
          Provider.of<MealPlanProvider>(context, listen: false);
      await mealPlanProvider.addMealPlan(mealPlan, meals: _meals);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan alimenticio creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear plan: $e'),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // Si hay comidas o texto escrito, confirmar antes de salir
        final hasContent = _meals.isNotEmpty ||
            _nameController.text.trim().isNotEmpty ||
            _descriptionController.text.trim().isNotEmpty ||
            _caloriesController.text != '2000';

        if (!hasContent) {
          // No hay cambios, permitir salir
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          return;
        }

        // Confirmar si quiere salir sin guardar
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Descartar cambios?'),
            content: const Text(
              '¿Estás seguro de que quieres salir sin guardar el plan alimenticio?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Salir'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo Plan Alimenticio'),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveMealPlan,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plan',
                  hintText: 'Ej: Definición Pro - Keto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe los objetivos de este plan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Tipo
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de plan',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'masa_muscular', child: Text('Masa muscular')),
                  DropdownMenuItem(
                      value: 'definicion', child: Text('Definición')),
                  DropdownMenuItem(
                      value: 'mantenimiento', child: Text('Mantenimiento')),
                  DropdownMenuItem(
                      value: 'perdida_peso', child: Text('Pérdida de peso')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Calorías
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calorías totales diarias',
                  suffixText: 'kcal',
                  border: OutlineInputBorder(),
                  helperText: 'Total de calorías del plan completo',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (int.tryParse(value) == null) return 'Inválido';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Comidas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addMeal,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
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
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 48,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No hay comidas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Agrega comidas para crear el plan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_meals.length, (index) {
                  final meal = _meals[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppColors.cardBackground,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(
                          _getMealIcon(meal['time'] as String),
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(meal['name'] as String),
                      subtitle: Text(
                        '${meal['time']} • ${meal['calories']} kcal',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeMeal(index),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(String time) {
    switch (time) {
      case 'Desayuno':
        return Icons.free_breakfast;
      case 'Media mañana':
        return Icons.coffee;
      case 'Almuerzo':
        return Icons.lunch_dining;
      case 'Merienda':
        return Icons.cookie;
      case 'Cena':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }
}

class _AddMealDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddMealDialog({required this.onAdd});

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedTime = 'Desayuno';

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final meal = {
      'name': _nameController.text.trim(),
      'time': _selectedTime,
      'calories': int.parse(_caloriesController.text),
      'description': _descriptionController.text.trim(),
    };

    widget.onAdd(meal);
    Navigator.pop(context);
  }

  Future<void> _handleCancel() async {
    // Verificar si hay datos escritos
    final hasContent = _nameController.text.trim().isNotEmpty ||
        _caloriesController.text.isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _selectedTime != 'Desayuno';

    if (!hasContent) {
      // No hay cambios, cerrar directamente
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Preguntar si desea descartar la comida
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar comida?'),
        content: const Text(
          '¿Estás seguro de que quieres salir sin agregar esta comida?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Comida'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la comida',
                  hintText: 'Ej: Avena con frutas',
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: const InputDecoration(labelText: 'Momento del día'),
                items: const [
                  DropdownMenuItem(value: 'Desayuno', child: Text('Desayuno')),
                  DropdownMenuItem(
                      value: 'Media mañana', child: Text('Media mañana')),
                  DropdownMenuItem(value: 'Almuerzo', child: Text('Almuerzo')),
                  DropdownMenuItem(value: 'Merienda', child: Text('Merienda')),
                  DropdownMenuItem(value: 'Cena', child: Text('Cena')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTime = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calorías',
                  suffixText: 'kcal',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (int.tryParse(value) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ingredientes, preparación...',
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleCancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
