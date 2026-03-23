import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/app_snackbar.dart';
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
        title: Text(AppL10n.of(ctx).newCategory),
        content: TextField(
          controller: _newCategoryController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: AppL10n.of(ctx).categoryHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirmAddCategory(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppL10n.of(ctx).cancel),
          ),
          ElevatedButton(
            onPressed: () => _confirmAddCategory(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(AppL10n.of(ctx).addLabel),
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
          title: Text(AppL10n.of(ctx).manageCategories),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppL10n.of(ctx).defaultCategoriesInfo,
                  style: const TextStyle(
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
              child: Text(AppL10n.of(ctx).closeLabel),
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
      AppSnackbar.error(context, AppL10n.of(context).addAtLeastOneExercise);
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
        AppSnackbar.success(context, AppL10n.of(context).routineCreated);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error al crear rutina: $e');
      if (mounted) {
        AppSnackbar.error(context, AppL10n.of(context).couldNotCreateRoutine);
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
          builder: (context) {
            final l10n = AppL10n.of(context);
            return AlertDialog(
              title: Text(l10n.discardChangesTitle),
              content: Text(
                l10n.discardWorkoutBody,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.exitLabel),
                ),
              ],
            );
          },
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppL10n.of(context).newRoutine),
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
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: AppL10n.of(context).routineNameLabel,
                  hintText: AppL10n.of(context).routineNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppL10n.of(context).enterAName;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: AppL10n.of(context).descriptionLabel,
                  hintText: AppL10n.of(context).descriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppL10n.of(context).enterADescription;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Nivel
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: InputDecoration(
                  labelText: AppL10n.of(context).levelLabel,
                  border: const OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: AppL10n.of(context).categoryLabel,
                        border: const OutlineInputBorder(),
                      ),
                      hint: Text(AppL10n.of(context).selectACategory),
                      items: [
                        ..._categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                        DropdownMenuItem(
                          value: _kNoCategory,
                          child: Text(AppL10n.of(context).noCategory),
                        ),
                        DropdownMenuItem(
                          value: _kAddCategory,
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                AppL10n.of(context).newCategory,
                                style:
                                    const TextStyle(color: AppColors.primary),
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
                          return AppL10n.of(context).selectACategory;
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
                      tooltip: AppL10n.of(context).manageCategories,
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
                  Text(
                    AppL10n.of(context).exercisesSection,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: Text(AppL10n.of(context).addLabel),
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
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppL10n.of(context).noExercises,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppL10n.of(context).addExercisesHint,
                        style: const TextStyle(
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
                      title: Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        AppSnackbar.error(
            context, AppL10n.of(context).errorSelectingVideo(e.toString()));
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
          AppSnackbar.success(context, AppL10n.of(context).videoUploaded);
        }
      } else {
        throw Exception('No se pudo subir el video');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
            context, AppL10n.of(context).errorUploadingVideo(e.toString()));
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
      sets: int.tryParse(_setsController.text) ?? 3,
      reps: int.tryParse(_repsController.text) ?? 12,
      restSeconds: int.tryParse(_restController.text) ?? 60,
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
      builder: (context) {
        final l10n = AppL10n.of(context);
        return AlertDialog(
          title: Text(l10n.discardExerciseTitle),
          content: Text(
            l10n.discardExerciseBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.discardLabel),
            ),
          ],
        );
      },
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
        title: Text(AppL10n.of(context).addExerciseTitle),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppL10n.of(context).exerciseNameLabel,
                    hintText: AppL10n.of(context).exerciseNameHint,
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? AppL10n.of(context).requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        decoration: InputDecoration(
                            labelText: AppL10n.of(context).setsLabel),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppL10n.of(context).requiredField;
                          }
                          if (int.tryParse(value) == null) {
                            return AppL10n.of(context).invalidNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        decoration: InputDecoration(
                            labelText: AppL10n.of(context).repsLabel),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppL10n.of(context).requiredField;
                          }
                          if (int.tryParse(value) == null) {
                            return AppL10n.of(context).invalidNumber;
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
                  decoration: InputDecoration(
                    labelText: AppL10n.of(context).restSecondsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppL10n.of(context).requiredField;
                    }
                    if (int.tryParse(value) == null) {
                      return AppL10n.of(context).invalidNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: AppL10n.of(context).weightLbs,
                    hintText: AppL10n.of(context).weightLbsHint,
                    suffixText: 'kg',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return AppL10n.of(context).invalidNumber;
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
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppL10n.of(context).exerciseVideoOptional,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_videoFile == null && _videoUrl == null)
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.upload_file),
                      label: Text(AppL10n.of(context).selectVideo),
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
                              ? AppL10n.of(context).uploading
                              : AppL10n.of(context).uploadVideo),
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
                          Expanded(
                            child: Text(
                              AppL10n.of(context).videoUploadedOk,
                              style: const TextStyle(
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
            child: Text(AppL10n.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(AppL10n.of(context).addLabel),
          ),
        ],
      ),
    );
  }
}
