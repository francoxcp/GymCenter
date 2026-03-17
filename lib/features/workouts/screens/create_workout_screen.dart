import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newCategoryController = TextEditingController();

  static const _kAddCategory = '＋ Nueva categoría';
  static const _kNoCategory = 'Sin categoría';
  static const _kPrefsKey = 'custom_workout_categories';

  String _selectedLevel = AppConstants.beginnerLevel;
  String? _selectedCategory;
  List<String> _categories = List.from(Workout.categories);
  final List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_kPrefsKey) ?? [];
    if (custom.isNotEmpty && mounted) {
      setState(() {
        _categories = [...Workout.categories, ...custom];
      });
    }
  }

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final custom =
        _categories.where((c) => !Workout.categories.contains(c)).toList();
    await prefs.setStringList(_kPrefsKey, custom);
  }

  void _showAddCategoryDialog() {
    _newCategoryController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: _newCategoryController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Ej: Hombros, HIIT, Funcional...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirmAddCategory(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _confirmAddCategory(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmAddCategory(BuildContext ctx) {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;
    final normalized = name[0].toUpperCase() + name.substring(1);
    if (!_categories.contains(normalized)) {
      setState(() {
        _categories.add(normalized);
        _selectedCategory = normalized;
      });
      _saveCustomCategories();
    } else {
      setState(() => _selectedCategory = normalized);
    }
    Navigator.pop(ctx);
  }

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Gestionar categorías'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Las categorías predeterminadas no se pueden eliminar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ..._categories.map((cat) {
                  final isDefault = Workout.categories.contains(cat);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(cat),
                    trailing: isDefault
                        ? const Icon(Icons.lock_outline,
                            size: 16, color: AppColors.textSecondary)
                        : IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _categories.remove(cat);
                                if (_selectedCategory == cat) {
                                  _selectedCategory = null;
                                }
                              });
                              setDialogState(() {});
                              _saveCustomCategories();
                            },
                          ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddExerciseDialog(
        isAdmin: authProvider.isAdmin,
        onAdd: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
        },
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ejercicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtener el userId actual
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.id;

      // Calcular duración estimada (5 minutos por ejercicio)
      final estimatedDuration = _exercises.length * 5;

      final workout = Workout(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        level: _selectedLevel,
        category:
            _selectedCategory == 'Sin categoría' ? null : _selectedCategory,
        duration: estimatedDuration,
        exerciseCount: _exercises.length,
        imageUrl: '',
        createdBy: currentUserId,
        exercises: _exercises,
      );

      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.addWorkout(workout, userId: currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina creada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error al crear rutina: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo crear la rutina. Intenta de nuevo.'),
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

        // Si hay ejercicios o texto escrito, confirmar antes de salir
        final hasContent = _exercises.isNotEmpty ||
            _nameController.text.trim().isNotEmpty ||
            _descriptionController.text.trim().isNotEmpty;

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
              '¿Estás seguro de que quieres salir sin guardar la rutina?',
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
          title: const Text('Nueva rutina'),
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
                onPressed: _saveWorkout,
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
                  labelText: 'Nombre de la rutina',
                  hintText: 'Ej: Fuerza',
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
                  hintText: 'Describe los objetivos de esta rutina...',
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

              // Nivel
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  AppConstants.beginnerLevel,
                  AppConstants.intermediateLevel,
                  AppConstants.advancedLevel,
                ]
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLevel = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Categoría
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      items: [
                        ..._categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                        const DropdownMenuItem(
                          value: _kNoCategory,
                          child: Text('Sin categoría'),
                        ),
                        const DropdownMenuItem(
                          value: _kAddCategory,
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Nueva categoría',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == _kAddCategory) {
                          setState(() {});
                          _showAddCategoryDialog();
                        } else if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value == _kAddCategory) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      onPressed: _showManageCategoriesDialog,
                      icon: const Icon(Icons.tune),
                      tooltip: 'Gestionar categorías',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ejercicios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ejercicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
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

              if (_exercises.isEmpty)
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
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No hay ejercicios',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Agrega ejercicios para crear la rutina',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_exercises.length, (index) {
                  final exercise = _exercises[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppColors.cardBackground,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.sets} series × ${exercise.reps} reps',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeExercise(index),
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
}

class _AddExerciseDialog extends StatefulWidget {
  final Function(Exercise) onAdd;
  final bool isAdmin;

  const _AddExerciseDialog({
    required this.onAdd,
    this.isAdmin = false,
  });

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '12');
  final _restController = TextEditingController(text: '60');
  final _weightController = TextEditingController(text: '');

  final String _selectedMuscleGroup = 'General';

  // Video handling
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  String? _videoUrl;
  bool _isUploadingVideo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // Máximo 1 minuto
      );

      if (video != null) {
        setState(() {
          _videoFile = video;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() => _isUploadingVideo = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '';

      final storageService = StorageService();

      String? uploadedUrl;

      if (kIsWeb) {
        final bytes = await _videoFile!.readAsBytes();
        uploadedUrl = await storageService.uploadExerciseVideo(
          exerciseId: DateTime.now().millisecondsSinceEpoch.toString(),
          trainerId: userId,
          videoBytes: bytes,
          originalFileName: _videoFile!.name,
        );
      } else {
        uploadedUrl = await storageService.uploadExerciseVideo(
          exerciseId: DateTime.now().millisecondsSinceEpoch.toString(),
          trainerId: userId,
          videoFile: File(_videoFile!.path),
          originalFileName: _videoFile!.name,
        );
      }

      if (uploadedUrl != null) {
        setState(() {
          _videoUrl = uploadedUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video subido exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('No se pudo subir el video');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingVideo = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
      id: '',
      name: _nameController.text.trim(),
      sets: int.parse(_setsController.text),
      reps: int.parse(_repsController.text),
      restSeconds: int.parse(_restController.text),
      muscleGroup: _selectedMuscleGroup,
      difficulty: 'Intermedio',
      description: null,
      weight: double.tryParse(_weightController.text.trim()) ?? 0,
      videoUrl: _videoUrl ?? '',
      thumbnailUrl: '',
    );

    widget.onAdd(exercise);
    Navigator.pop(context);
  }

  Future<void> _handleCancel() async {
    // Verificar si hay datos escritos
    final hasContent = _nameController.text.trim().isNotEmpty ||
        _setsController.text != '3' ||
        _repsController.text != '12' ||
        _restController.text != '60' ||
        _videoFile != null ||
        _videoUrl != null;

    if (!hasContent) {
      // No hay cambios, cerrar directamente
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Preguntar si desea descartar el ejercicio
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar ejercicio?'),
        content: const Text(
          '¿Estás seguro de que quieres salir sin agregar este ejercicio?',
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
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleCancel();
      },
      child: AlertDialog(
        title: const Text('Agregar Ejercicio'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del ejercicio',
                    hintText: 'Ej: Press de banca',
                  ),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        decoration: const InputDecoration(labelText: 'Series'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: const InputDecoration(labelText: 'Reps'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _restController,
                  decoration: const InputDecoration(
                    labelText: 'Descanso (segundos)',
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
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (lbs)',
                    hintText: 'Ej: 20  —  dejar vacío si es peso corporal',
                    suffixText: 'kg',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                    }
                    return null;
                  },
                ),

                // Video upload section - Solo para admins
                if (widget.isAdmin) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.videocam, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Video del ejercicio (opcional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_videoFile == null && _videoUrl == null)
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Seleccionar video'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    )
                  else if (_videoFile != null && _videoUrl == null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.video_file,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _videoFile!.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _videoFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isUploadingVideo ? null : _uploadVideo,
                          icon: _isUploadingVideo
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload),
                          label: Text(_isUploadingVideo
                              ? 'Subiendo...'
                              : 'Subir Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    )
                  else if (_videoUrl != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Video subido exitosamente',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _videoFile = null;
                                _videoUrl = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
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
      ),
    );
  }
}
