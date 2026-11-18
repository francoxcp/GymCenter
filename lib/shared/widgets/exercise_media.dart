import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'video_player_widget.dart';

/// true si la URL es una animación o imagen (GIF de la biblioteca)
/// en lugar de un video.
bool isImageMediaUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg');
}

/// Muestra la demostración de un ejercicio: GIF/imagen de la biblioteca
/// o video subido por el gimnasio.
class ExerciseMedia extends StatelessWidget {
  final String url;
  final bool autoPlay;
  final String? exerciseName;
  final String? thumbnailUrl;

  const ExerciseMedia({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.exerciseName,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (!isImageMediaUrl(url)) {
      return VideoPlayerWidget(
        videoUrl: url,
        autoPlay: autoPlay,
        muted: true,
        looping: true,
        exerciseName: exerciseName,
        thumbnailUrl: thumbnailUrl,
        showFullscreenButton: true,
      );
    }
    // Las animaciones de técnica suelen venir sobre fondo blanco:
    // se respeta ese fondo para que el dibujo se lea bien.
    return Semantics(
      image: true,
      label: exerciseName == null
          ? 'Demostración del ejercicio'
          : 'Demostración de $exerciseName',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Colors.white,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
            errorBuilder: (_, __, ___) => SizedBox(
              height: 120,
              child: Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: AppColors.textSecondary, size: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
