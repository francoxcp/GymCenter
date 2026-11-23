import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

/// Servicio para gestionar la subida y compresión de archivos multimedia
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buckets de Supabase Storage
  static const String profilePhotosBucket = 'profile-photos';
  static const String exerciseVideosBucket = 'exercise-videos';
  // Límites de tamaño
  static const int _maxVideoBytes = 50 * 1024 * 1024; // 50 MB

  // Extensiones de video permitidas
  static const _allowedVideoExtensions = {'.mp4', '.mov', '.avi', '.webm'};

  /// Comprime una imagen manteniendo calidad óptima
  ///
  /// [imageFile] - Archivo de imagen a comprimir
  /// [quality] - Calidad de compresión (0-100), default 85
  /// [maxWidth] - Ancho máximo en píxeles, default 1080
  /// [maxHeight] - Alto máximo en píxeles, default 1080
  Future<Uint8List?> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        // Imagen comprimida exitosamente
      }

      return result;
    } catch (e) {
      // Error al comprimir imagen: log seguro, sin datos sensibles
      return null;
    }
  }

  /// Comprime una imagen desde bytes (para web)
  Future<Uint8List?> compressImageBytes(
    Uint8List imageBytes, {
    int quality = 85,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    // En web, flutter_image_compress necesita librerías JS extra. El
    // selector de imágenes (image_picker) ya redimensiona a 1080 px y
    // aplica calidad 85 en el navegador, así que se usan los bytes tal cual.
    if (kIsWeb) return imageBytes;
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      return result;
    } catch (e) {
      debugPrint('Error al comprimir imagen: $e');
      return null;
    }
  }

  /// Sube un video de ejercicio con metadata
  ///
  /// [videoFile] - Archivo de video
  /// [videoBytes] - Bytes de video (para web)
  /// [exerciseId] - ID del ejercicio
  /// [trainerId] - ID del entrenador que sube el video
  /// Returns URL pública del video
  Future<String?> uploadExerciseVideo({
    required String exerciseId,
    required String trainerId,
    File? videoFile,
    Uint8List? videoBytes,
    String? originalFileName,
  }) async {
    try {
      Uint8List videoData;

      if (kIsWeb && videoBytes != null) {
        videoData = videoBytes;
      } else if (videoFile != null) {
        videoData = await videoFile.readAsBytes();
      } else {
        throw Exception('Must provide videoFile or videoBytes');
      }

      // Para videos grandes, mostrar progreso
      final videoSize = videoData.length;

      // Validar tamaño
      if (videoSize > _maxVideoBytes) {
        throw Exception('Video exceeds maximum size of 50 MB');
      }

      // Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension =
          originalFileName != null ? path.extension(originalFileName) : '.mp4';

      // Validar extensión permitida
      if (!_allowedVideoExtensions.contains(extension.toLowerCase())) {
        throw Exception('Video format not allowed: $extension');
      }

      // Validar contenido real del archivo (magic bytes)
      if (!_isValidVideoContent(videoData)) {
        throw Exception('File content does not match a valid video format');
      }

      final fileName = 'exercise_$exerciseId${'_'}$timestamp$extension';

      // Subir video a Supabase Storage
      await _supabase.storage
          .from(exerciseVideosBucket)
          .uploadBinary(fileName, videoData,
              fileOptions: FileOptions(
                contentType: _getVideoMimeType(extension),
                upsert: false,
              ));

      // Obtener URL pública
      final publicUrl =
          _supabase.storage.from(exerciseVideosBucket).getPublicUrl(fileName);

      // Guardar metadata en base de datos
      await _saveVideoMetadata(
        exerciseId: exerciseId,
        trainerId: trainerId,
        videoUrl: publicUrl,
        fileName: fileName,
        sizeBytes: videoSize,
      );

      return publicUrl;
    } catch (e) {
      // Error al subir video: log seguro, sin datos sensibles
      return null;
    }
  }

  /// Obtiene el MIME type según la extensión del video
  String _getVideoMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  /// Guarda metadata del video en la base de datos

  /// Valida que los bytes del archivo correspondan a un formato de video real.
  /// Comprueba magic bytes de MP4/MOV, WebM y AVI.
  bool _isValidVideoContent(Uint8List data) {
    if (data.length < 12) return false;

    // MP4/MOV: byte 4-7 = "ftyp"
    if (data[4] == 0x66 &&
        data[5] == 0x74 &&
        data[6] == 0x79 &&
        data[7] == 0x70) {
      return true;
    }

    // WebM/MKV: starts with 0x1A 0x45 0xDF 0xA3
    if (data[0] == 0x1A &&
        data[1] == 0x45 &&
        data[2] == 0xDF &&
        data[3] == 0xA3) {
      return true;
    }

    // AVI: starts with "RIFF" and contains "AVI "
    if (data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data.length > 11 &&
        data[8] == 0x41 &&
        data[9] == 0x56 &&
        data[10] == 0x49 &&
        data[11] == 0x20) {
      return true;
    }

    return false;
  }

  Future<void> _saveVideoMetadata({
    required String exerciseId,
    required String trainerId,
    required String videoUrl,
    required String fileName,
    required int sizeBytes,
  }) async {
    try {
      // Actualizar el ejercicio con la URL del video
      await _supabase.from('exercises').update({
        'video_url': videoUrl,
        'video_metadata': {
          'file_name': fileName,
          'size_bytes': sizeBytes,
          'uploaded_by': trainerId,
          'uploaded_at': DateTime.now().toIso8601String(),
        }
      }).eq('id', exerciseId);
    } catch (e) {
      debugPrint('Error al guardar metadata: $e');
    }
  }

}
