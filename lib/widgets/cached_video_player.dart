import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const CachedVideoPlayer({super.key, required this.url, this.autoPlay = false});

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      if (!mounted) return;

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      if (widget.autoPlay) {
        await _controller!.play();
        await _controller!.setLooping(true);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          Text("Video Load Error", style: TextStyle(color: Colors.red, fontSize: 10)),
        ],
      ));
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          _VideoControls(controller: _controller!),
        ],
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black26,
          child: Center(
            child: IconButton(
              icon: Icon(
                widget.controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 50,
              ),
              onPressed: () {
                setState(() {
                  widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
