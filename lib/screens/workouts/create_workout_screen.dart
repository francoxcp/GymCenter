import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedLevel = AppConstants.beginnerLevel;
  final List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExercise() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddExerciseDialog(
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
      // Calcular duración estimada (5 minutos por ejercicio)
      final estimatedDuration = _exercises.length * 5;

      final workout = Workout(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        level: _selectedLevel,
        duration: estimatedDuration,
        exerciseCount: _exercises.length,
        imageUrl: '',
        exercises: _exercises,
      );

      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);
      await workoutProvider.addWorkout(workout);

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
          title: const Text('Nueva Rutina'),
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
                hintText: 'Ej: Hipertrofia Nivel 3',
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
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
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

  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '12');
  final _restController = TextEditingController(text: '60');

  String _selectedMuscleGroup = 'pecho';
  String _selectedEquipment = 'barra';

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
      description: 'Equipo: $_selectedEquipment',
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

    if (shouldPop == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                DropdownButtonFormField<String>(
                  value: _selectedMuscleGroup,
                  decoration:
                      const InputDecoration(labelText: 'Grupo muscular'),
                  items: const [
                    DropdownMenuItem(value: 'pecho', child: Text('Pecho')),
                    DropdownMenuItem(value: 'espalda', child: Text('Espalda')),
                    DropdownMenuItem(value: 'piernas', child: Text('Piernas')),
                    DropdownMenuItem(value: 'hombros', child: Text('Hombros')),
                    DropdownMenuItem(value: 'brazos', child: Text('Brazos')),
                    DropdownMenuItem(value: 'abdomen', child: Text('Abdomen')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMuscleGroup = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedEquipment,
                  decoration: const InputDecoration(labelText: 'Equipo'),
                  items: const [
                    DropdownMenuItem(value: 'barra', child: Text('Barra')),
                    DropdownMenuItem(
                        value: 'mancuernas', child: Text('Mancuernas')),
                    DropdownMenuItem(value: 'maquina', child: Text('Máquina')),
                    DropdownMenuItem(
                        value: 'peso_corporal', child: Text('Peso corporal')),
                    DropdownMenuItem(value: 'bandas', child: Text('Bandas')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEquipment = value);
                    }
                  },
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Video upload section
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
                    label: const Text('Seleccionar Video'),
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
                        label: Text(
                            _isUploadingVideo ? 'Subiendo...' : 'Subir Video'),
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
