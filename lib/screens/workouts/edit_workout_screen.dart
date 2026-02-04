import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme/app_theme.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';

class EditWorkoutScreen extends StatefulWidget {
  final Workout workout;

  const EditWorkoutScreen({super.key, required this.workout});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedLevel = 'Principiante';
  final List<Exercise> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.workout.name;
    _descriptionController.text = widget.workout.description ?? '';
    _durationController.text = widget.workout.duration.toString();
    _selectedLevel = widget.workout.level;
    _exercises.addAll(widget.workout.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
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
              'Editar Rutina',
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
                        labelText: 'Nombre de la Rutina',
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
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (minutos)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la duración';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Nivel',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Principiante', 'Intermedio', 'Avanzado']
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EJERCICIOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addExercise,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
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
                        ),
                        child: const Center(
                          child: Text(
                            'No hay ejercicios. Toca "Agregar" para comenzar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        return _ExerciseCard(
                          exercise: exercise,
                          onEdit: () => _editExercise(index),
                          onDelete: () => _removeExercise(index),
                        );
                      }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveWorkout,
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

  void _addExercise() {
    _showExerciseDialog();
  }

  void _editExercise(int index) {
    _showExerciseDialog(exercise: _exercises[index], index: index);
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _showExerciseDialog({Exercise? exercise, int? index}) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        exercise: exercise,
        onSave: (newExercise) {
          setState(() {
            if (index != null) {
              _exercises[index] = newExercise;
            } else {
              _exercises.add(newExercise);
            }
          });
        },
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    final updatedWorkout = Workout(
      id: widget.workout.id,
      name: _nameController.text,
      duration: int.parse(_durationController.text),
      exerciseCount: _exercises.length,
      level: _selectedLevel,
      imageUrl: widget.workout.imageUrl,
      description: _descriptionController.text,
      exercises: _exercises,
    );

    try {
      await workoutProvider.updateWorkout(widget.workout.id, updatedWorkout);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina actualizada correctamente'),
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
          '¿Estás seguro de eliminar "${widget.workout.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _deleteWorkout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkout() async {
    Navigator.pop(context); // Close dialog

    setState(() => _isLoading = true);

    final workoutProvider =
        Provider.of<WorkoutProvider>(context, listen: false);

    try {
      await workoutProvider.deleteWorkout(widget.workout.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina eliminada correctamente'),
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

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
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
          child: const Icon(Icons.fitness_center, color: AppColors.primary),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${exercise.sets} series × ${exercise.reps} reps • ${exercise.restSeconds}s',
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

// Diálogo para agregar/editar ejercicios con video
class _ExerciseDialog extends StatefulWidget {
  final Exercise? exercise;
  final Function(Exercise) onSave;

  const _ExerciseDialog({
    this.exercise,
    required this.onSave,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _descController;

  String _muscleGroup = 'Pecho';

  // Video handling
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  String? _videoUrl;
  bool _isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _setsController =
        TextEditingController(text: widget.exercise?.sets.toString() ?? '3');
    _repsController =
        TextEditingController(text: widget.exercise?.reps.toString() ?? '12');
    _restController = TextEditingController(
        text: widget.exercise?.restSeconds.toString() ?? '60');
    _descController =
        TextEditingController(text: widget.exercise?.description ?? '');
    _muscleGroup = widget.exercise?.muscleGroup ?? 'Pecho';
    _videoUrl = widget.exercise?.videoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        setState(() {
          _videoFile = video;
          _videoUrl = null; // Clear existing URL
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
          exerciseId: widget.exercise?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          trainerId: userId,
          videoBytes: bytes,
          originalFileName: _videoFile!.name,
        );
      } else {
        uploadedUrl = await storageService.uploadExerciseVideo(
          exerciseId: widget.exercise?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          trainerId: userId,
          videoFile: File(_videoFile!.path),
          originalFileName: _videoFile!.name,
        );
      }

      if (uploadedUrl != null) {
        setState(() {
          _videoUrl = uploadedUrl;
          _videoFile = null;
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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del ejercicio es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newExercise = Exercise(
      id: widget.exercise?.id ?? '',
      name: _nameController.text.trim(),
      sets: int.tryParse(_setsController.text) ?? 3,
      reps: int.tryParse(_repsController.text) ?? 12,
      restSeconds: int.tryParse(_restController.text) ?? 60,
      muscleGroup: _muscleGroup,
      description: _descController.text.trim(),
      videoUrl: _videoUrl ?? '',
    );

    widget.onSave(newExercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
          widget.exercise == null ? 'Nuevo Ejercicio' : 'Editar Ejercicio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Series'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Repeticiones'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Descanso (seg)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _muscleGroup,
              decoration: const InputDecoration(labelText: 'Grupo Muscular'),
              items: [
                'Pecho',
                'Espalda',
                'Piernas',
                'Hombros',
                'Brazos',
                'Abdomen',
                'Cardio'
              ]
                  .map((group) =>
                      DropdownMenuItem(value: group, child: Text(group)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _muscleGroup = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Video section
            const Row(
              children: [
                Icon(Icons.videocam, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Video del ejercicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_videoFile == null && (_videoUrl == null || _videoUrl!.isEmpty))
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.upload_file),
                label: const Text('Seleccionar Video'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              )
            else if (_videoFile != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.video_file,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _videoFile!.name,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
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
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload, size: 18),
                    label:
                        Text(_isUploadingVideo ? 'Subiendo...' : 'Subir Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              )
            else if (_videoUrl != null && _videoUrl!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Video disponible',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.edit, size: 18, color: Colors.blue),
                      onPressed: _pickVideo,
                    ),
                  ],
                ),
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
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
