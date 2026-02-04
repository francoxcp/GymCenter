import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../config/theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../services/storage_service.dart';
import '../../providers/auth_provider.dart';

class UploadExerciseVideoScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const UploadExerciseVideoScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<UploadExerciseVideoScreen> createState() =>
      _UploadExerciseVideoScreenState();
}

class _UploadExerciseVideoScreenState extends State<UploadExerciseVideoScreen> {
  PlatformFile? _selectedVideo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Video de ${widget.exerciseName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎥 Subir Video del Ejercicio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'El video será comprimido automáticamente para optimizar el espacio y mantener la calidad.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Área de selección de video
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedVideo != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.video_file,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedVideo!.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatFileSize(_selectedVideo!.size),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Toca para seleccionar video',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Formatos: MP4, MOV, AVI, WebM',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Información del video
            if (_selectedVideo != null) ...[
              _buildInfoRow('Nombre', _selectedVideo!.name),
              _buildInfoRow('Tamaño', _formatFileSize(_selectedVideo!.size)),
              _buildInfoRow(
                'Formato',
                _selectedVideo!.extension?.toUpperCase() ?? 'Desconocido',
              ),
              const SizedBox(height: 24),
            ],

            // Barra de progreso
            if (_isUploading) ...[
              const Text(
                'Subiendo video...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.cardBackground,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // Botones de acción
            if (_selectedVideo != null && !_isUploading)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selectedVideo = null);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Cambiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: 'Subir Video',
                      onPressed: _uploadVideo,
                    ),
                  ),
                ],
              )
            else if (!_isUploading)
              PrimaryButton(
                text: 'Seleccionar Video',
                onPressed: _pickVideo,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validar tamaño (máximo 100MB)
        final storageService = StorageService();
        if (!storageService.validateFileSize(file.size, maxSizeMB: 100)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El video es demasiado grande (máximo 100MB)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _selectedVideo = file);
      }
    } catch (e) {
      debugPrint('Error al seleccionar video: $e');
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
    if (_selectedVideo == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final trainerId = authProvider.currentUser?.id;

      if (trainerId == null) {
        throw Exception('No hay sesión activa');
      }

      final storageService = StorageService();

      // Simular progreso mientras se sube
      _simulateProgress();

      String? videoUrl;
      if (kIsWeb && _selectedVideo!.bytes != null) {
        videoUrl = await storageService.uploadExerciseVideo(
          exerciseId: widget.exerciseId,
          trainerId: trainerId,
          videoBytes: _selectedVideo!.bytes,
          originalFileName: _selectedVideo!.name,
        );
      } else if (_selectedVideo!.path != null) {
        final file = File(_selectedVideo!.path!);
        videoUrl = await storageService.uploadExerciseVideo(
          exerciseId: widget.exerciseId,
          trainerId: trainerId,
          videoFile: file,
          originalFileName: _selectedVideo!.name,
        );
      }

      if (videoUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video subido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la pantalla anterior
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.pop(videoUrl);
          }
        });
      }
    } catch (e) {
      debugPrint('Error al subir video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _simulateProgress() {
    // Simular progreso de carga
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isUploading && mounted) {
        setState(() => _uploadProgress = 0.3);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isUploading && mounted) {
            setState(() => _uploadProgress = 0.6);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isUploading && mounted) {
                setState(() => _uploadProgress = 0.9);
              }
            });
          }
        });
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
