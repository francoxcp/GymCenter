import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';

/// Video del ejercicio "en grande": pantalla negra, pellizcar o doble toque
/// para acercar, cámara lenta para ver la técnica y barra para adelantar.
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String exerciseName;

  /// Continúa desde donde iba el video pequeño.
  final Duration startAt;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
    this.startAt = Duration.zero,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  final _zoom = TransformationController();
  bool _ready = false;
  bool _error = false;
  bool _slow = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      FileInfo? cached;
      if (!kIsWeb) {
        try {
          cached = await DefaultCacheManager().getFileFromCache(widget.videoUrl);
        } catch (_) {}
      }
      final c = cached != null
          ? VideoPlayerController.file(cached.file)
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = c;
      await c.setLooping(true);
      await c.initialize();
      // Silenciado: así el navegador deja reproducir solo (y es un video
      // de técnica, el audio no aporta).
      await c.setVolume(0);
      if (widget.startAt > Duration.zero && widget.startAt < c.value.duration) {
        await c.seekTo(widget.startAt);
      }
      await c.play();
      if (!mounted) return;
      setState(() => _ready = true);
      _autoHide();
    } catch (e) {
      debugPrint('Error al abrir video en grande: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  void _autoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
      _showControls = true;
    });
    if (c.value.isPlaying) _autoHide();
  }

  void _toggleSlow() {
    final c = _controller;
    if (c == null) return;
    setState(() => _slow = !_slow);
    c.setPlaybackSpeed(_slow ? 0.5 : 1.0);
  }

  void _doubleTapZoom() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    _zoom.value = zoomed
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(2.0, 2.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _error
                  ? Center(
                      child: Text(l10n.videoLoadError,
                          style: const TextStyle(color: Colors.white70)),
                    )
                  : !_ready || c == null
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : GestureDetector(
                          onTap: () =>
                              setState(() => _showControls = !_showControls),
                          onDoubleTap: _doubleTapZoom,
                          child: InteractiveViewer(
                            transformationController: _zoom,
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: c.value.aspectRatio,
                                child: VideoPlayer(c),
                              ),
                            ),
                          ),
                        ),
            ),
            // Barra superior: cerrar + nombre
            AnimatedOpacity(
              opacity: _showControls || !_ready ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(widget.exerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            // Controles inferiores
            if (_ready && c != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            c,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            colors: VideoProgressColors(
                              playedColor: AppColors.primary,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.filled(
                                tooltip: c.value.isPlaying ? 'Pausar' : 'Reproducir',
                                iconSize: 32,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                ),
                                onPressed: _togglePlay,
                                icon: Icon(c.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: const Text('Cámara lenta'),
                                selected: _slow,
                                showCheckmark: false,
                                onSelected: (_) => _toggleSlow(),
                              ),
                              const Spacer(),
                              const Text('Pellizca para acercar',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
