import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

/// Servicio para gestionar la subida y compresión de archivos multimedia
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buckets de Supabase Storage
  static const String profilePhotosBucket = 'profile-photos';
  static const String exerciseVideosBucket = 'exercise-videos';
  static const String exerciseThumbnailsBucket = 'exercise-thumbnails';

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
        final originalSize = await imageFile.length();
        final compressedSize = result.length;
        final reduction = ((originalSize - compressedSize) / originalSize * 100)
            .toStringAsFixed(1);

        // ...existing code...
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
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      final originalSize = imageBytes.length;
      final compressedSize = result.length;
      final reduction = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);

      debugPrint(
          'Imagen comprimida: $originalSize bytes → $compressedSize bytes');
      debugPrint('Reducción: $reduction%');

      return result;
    } catch (e) {
      debugPrint('Error al comprimir imagen: $e');
      return null;
    }
  }

  /// Sube una foto de perfil a Supabase Storage
  ///
  /// [userId] - ID del usuario
  /// [imageFile] - Archivo de imagen (null para web, usar imageBytes)
  /// [imageBytes] - Bytes de imagen (para web)
  /// Returns URL pública de la imagen subida
  Future<String?> uploadProfilePhoto({
    required String userId,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      Uint8List? compressedData;

      // Comprimir según la plataforma
      if (kIsWeb && imageBytes != null) {
        compressedData = await compressImageBytes(imageBytes);
      } else if (imageFile != null) {
        compressedData = await compressImage(imageFile);
      }

      if (compressedData == null) {
        throw Exception('No se pudo comprimir la imagen');
      }

      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const extension = 'jpg';
      final fileName = '$userId/$timestamp.$extension';

      // Subir a Supabase Storage
      await _supabase.storage
          .from(profilePhotosBucket)
          .uploadBinary(fileName, compressedData,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ));

      // Obtener URL pública
      final publicUrl =
          _supabase.storage.from(profilePhotosBucket).getPublicUrl(fileName);

      // ...existing code...
      return publicUrl;
    } catch (e) {
      // Error al subir foto de perfil: log seguro, sin datos sensibles
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
        throw Exception('Debe proporcionar videoFile o videoBytes');
      }

      // Para videos grandes, mostrar progreso
      final videoSize = videoData.length;
      final sizeInMB = (videoSize / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('Subiendo video: $sizeInMB MB');

      // Generar nombre único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension =
          originalFileName != null ? path.extension(originalFileName) : '.mp4';
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

      // ...existing code...

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

      debugPrint('Metadata del video guardada');
    } catch (e) {
      debugPrint('Error al guardar metadata: $e');
    }
  }

  /// Elimina una foto de perfil anterior
  Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      final fileName = _extractFileNameFromUrl(photoUrl, profilePhotosBucket);
      if (fileName != null) {
        await _supabase.storage.from(profilePhotosBucket).remove([fileName]);
        debugPrint('Foto de perfil eliminada: $fileName');
      }
    } catch (e) {
      debugPrint('Error al eliminar foto: $e');
    }
  }

  /// Elimina un video de ejercicio
  Future<void> deleteExerciseVideo(String videoUrl) async {
    try {
      final fileName = _extractFileNameFromUrl(videoUrl, exerciseVideosBucket);
      if (fileName != null) {
        await _supabase.storage.from(exerciseVideosBucket).remove([fileName]);
        debugPrint('Video eliminado: $fileName');
      }
    } catch (e) {
      debugPrint('Error al eliminar video: $e');
    }
  }

  /// Extrae el nombre del archivo de una URL pública de Supabase
  String? _extractFileNameFromUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      debugPrint('Error al extraer nombre de archivo: $e');
      return null;
    }
  }

  /// Genera un hash MD5 de un archivo (para detectar duplicados)
  Future<String> generateFileHash(Uint8List fileBytes) async {
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }

  /// Valida el tamaño del archivo
  bool validateFileSize(int sizeBytes, {int maxSizeMB = 100}) {
    final sizeMB = sizeBytes / (1024 * 1024);
    return sizeMB <= maxSizeMB;
  }

  /// Valida el formato de imagen
  bool validateImageFormat(String fileName) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final extension = path.extension(fileName).toLowerCase();
    return validExtensions.contains(extension);
  }

  /// Valida el formato de video
  bool validateVideoFormat(String fileName) {
    final validExtensions = ['.mp4', '.mov', '.avi', '.webm'];
    final extension = path.extension(fileName).toLowerCase();
    return validExtensions.contains(extension);
  }
}
