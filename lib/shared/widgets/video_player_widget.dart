import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import 'fullscreen_video_player.dart';

/// Widget para reproducir videos de ejercicios
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final double? aspectRatio;
  final String? exerciseName;
  final String? thumbnailUrl;
  final bool showFullscreenButton;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = true,
    this.aspectRatio,
    this.exerciseName,
    this.thumbnailUrl,
    this.showFullscreenButton = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'url_unavailable';
        });
        return;
      }

      // Non-blocking cache lookup � returns instantly if not cached.
      FileInfo? cacheInfo;
      try {
        cacheInfo =
            await DefaultCacheManager().getFileFromCache(widget.videoUrl);
      } catch (e) {
        debugPrint('Error checking video cache: $e');
      }

      if (cacheInfo != null) {
        // Cache hit ? play from disk instantly
        _controller = VideoPlayerController.file(cacheInfo.file);
      } else {
        // Cache miss ? stream from network immediately (no wait),
        // and download in background so next time it's instant.
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
        DefaultCacheManager().downloadFile(widget.videoUrl).ignore();
      }

      _controller.setLooping(widget.looping);

      await _controller.initialize();

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });

      if (widget.autoPlay) {
        _controller.play();
      }
    } catch (e) {
      debugPrint('Error al inicializar video: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'load_error';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppL10n.of(context);
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage == 'url_unavailable'
                    ? l10n.videoUrlUnavailable
                    : l10n.videoLoadError,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      // Show thumbnail as placeholder while the video initialises.
      // Falls back to a dark container with a spinner if no thumbnail.
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Thumbnail background
              if (widget.thumbnailUrl != null &&
                  widget.thumbnailUrl!.isNotEmpty)
                Image.network(
                  widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              // Dark overlay
              Container(color: Colors.black54),
              // Spinner + label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loadingVideo,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: widget.aspectRatio ?? _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),

            // Play/Pause overlay
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 0.8,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bot�n de pantalla completa
            if (widget.showFullscreenButton)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullscreenVideoPlayer(
                          videoUrl: widget.videoUrl,
                          exerciseName: widget.exerciseName ?? 'Video',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Progress bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
              ),
            ),

            // Controls overlay
            Positioned(
              bottom: 40,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final position = value.position;
                    final duration = value.duration;

                    return Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Widget simple para mostrar un preview del video (sin controles completos)
class VideoThumbnailWidget extends StatelessWidget {
  final String videoUrl;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    if (videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ??
          () {
            // Mostrar video en fullscreen
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    VideoPlayerWidget(
                      videoUrl: videoUrl,
                      autoPlay: true,
                    ),
                  ],
                ),
              ),
            );
          },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 48,
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.watchVideo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
