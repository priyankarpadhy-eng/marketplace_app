import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:market_app/providers/audio_provider.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/screens/music_screen.dart'; // To get SpectrumVisualizer

class NowPlayingSheet extends ConsumerWidget {
  const NowPlayingSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NowPlayingSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    // Get current track details
    String trackName = 'Unknown';
    String url = '';
    if (audioState.queueAssets.isNotEmpty && audioState.selectedIndex >= 0 && audioState.selectedIndex < audioState.queueAssets.length) {
      final track = audioState.queueAssets[audioState.selectedIndex];
      trackName = track['name']?.replaceAll('.mp3', '') ?? 'Unknown';
      url = track['url'] ?? '';
    }

    final isLoved = audioState.lovedTrackUrls.contains(url);
    final isDownloaded = audioState.downloadedTrackUrls.contains(url);
    
    // Aesthetic colors based on the design request (no generic red/blue as per global rules, using deliberate palette)
    final sheetBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5); // warm/cool neutral tint
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF171717);
    final textSecondaryColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF737373);
    final accentColor = const Color(0xFFDC2626); // specifically requested red play button

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Handle pill
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  'Now Playing',
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isLoved ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: isLoved ? accentColor : textColor,
                    size: 24,
                  ),
                  onPressed: () => audioNotifier.toggleLoved(url),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Circular Art Graphic with Draggable Progress Boundary
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              child: CircularAudioProgress(
                player: audioNotifier.audioPlayer,
                accentColor: accentColor,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E5E5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dark inner circle for spectrum visibility
                      Container(
                        margin: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF171717),
                        ),
                      ),
                      // The bouncing SpectrumVisualizer
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: ClipOval(
                          child: Align(
                            alignment: Alignment.center,
                            child: RepaintBoundary(
                              child: SpectrumVisualizer(
                                isPlaying: audioState.isPlaying,
                                color: accentColor,
                                barCount: 14,
                                maxHeight: 80,
                                minHeight: 8,
                                barWidth: 6,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Inner spinning record effect ring
                      Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Track Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  trackName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.04,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Market Music',
                  style: GoogleFonts.outfit(
                    color: textSecondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Faux Waveform Progress Bar (Draggable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _LinearWaveformProgress(
              player: audioNotifier.audioPlayer,
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
            ),
          ),

          const SizedBox(height: 32),

          // Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Download
                audioState.downloadProgress[url] != null
                  ? SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                        value: audioState.downloadProgress[url], 
                        color: accentColor, 
                        strokeWidth: 2.5
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        isDownloaded ? Icons.offline_pin_rounded : Icons.download_rounded, 
                        color: isDownloaded ? Colors.green : textSecondaryColor, 
                        size: 24
                      ),
                      onPressed: () => audioNotifier.downloadTrack(url, trackName),
                    ),
                
                // Previous
                IconButton(
                  icon: Icon(Icons.skip_previous_rounded, color: textColor, size: 36),
                  onPressed: () => audioNotifier.playPrevious(),
                ),

                // Play / Pause (Red Circle)
                GestureDetector(
                  onTap: () => audioNotifier.togglePlayPause(),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: audioState.isBuffering
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Icon(
                              audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                    ),
                  ),
                ),

                // Next
                IconButton(
                  icon: Icon(Icons.skip_next_rounded, color: textColor, size: 36),
                  onPressed: () => audioNotifier.playNext(),
                ),

                // Loop
                IconButton(
                  icon: Icon(
                    audioState.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: audioState.loopMode != LoopMode.off ? textColor : textSecondaryColor,
                    size: 24,
                  ),
                  onPressed: () => audioNotifier.toggleLoopMode(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 64),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// ----------------------------------------------------------------------
// Circular Audio Progress Component
// ----------------------------------------------------------------------
class CircularAudioProgress extends StatefulWidget {
  final AudioPlayer player;
  final Widget child;
  final Color accentColor;
  final Color backgroundColor;

  const CircularAudioProgress({
    super.key,
    required this.player,
    required this.child,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  State<CircularAudioProgress> createState() => _CircularAudioProgressState();
}

class _CircularAudioProgressState extends State<CircularAudioProgress> {
  double? _dragProgress;

  void _updateDragProgress(Offset localPosition, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final center = box.size.center(Offset.zero);
    final angle = math.atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
    var p = (angle + math.pi / 2) / (2 * math.pi);
    if (p < 0) p += 1.0;
    setState(() => _dragProgress = p.clamp(0.0, 1.0));
  }

  void _seekToProgress(double durationMs) {
    if (_dragProgress != null) {
      final seekMs = (durationMs * _dragProgress!).clamp(0, durationMs).toInt();
      widget.player.seek(Duration(milliseconds: seekMs));
      setState(() => _dragProgress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? Duration.zero;
        final streamProgress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;
        final progress = _dragProgress ?? streamProgress;

        return RepaintBoundary(
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: progress,
              color: widget.accentColor,
              backgroundColor: widget.backgroundColor,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw background ring
    canvas.drawCircle(center, radius, bgPaint);

    // Draw active progress arc
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}

class _LinearWaveformProgress extends StatefulWidget {
  final AudioPlayer player;
  final Color textColor;
  final Color textSecondaryColor;

  const _LinearWaveformProgress({
    required this.player,
    required this.textColor,
    required this.textSecondaryColor,
  });

  @override
  State<_LinearWaveformProgress> createState() => _LinearWaveformProgressState();
}

class _LinearWaveformProgressState extends State<_LinearWaveformProgress> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? Duration.zero;
        final streamProgress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;
        final progressPercent = _dragProgress ?? streamProgress;

        return Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                _formatDuration(Duration(milliseconds: (duration.inMilliseconds * progressPercent).round())),
                style: GoogleFonts.outfit(
                  color: widget.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 32,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barCount = 40;
                    final spacing = 2.0;
                    final availableWidth = constraints.maxWidth;
                    final barWidth = (availableWidth - (spacing * (barCount - 1))) / barCount;
                    
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) => _updateProgress(details.localPosition.dx, availableWidth),
                      onPanUpdate: (details) => _updateProgress(details.localPosition.dx, availableWidth),
                      onPanEnd: (details) {
                        if (_dragProgress != null) {
                          final seekMs = (duration.inMilliseconds * _dragProgress!).clamp(0, duration.inMilliseconds).toInt();
                          widget.player.seek(Duration(milliseconds: seekMs));
                          setState(() => _dragProgress = null);
                        }
                      },
                      onPanCancel: () => setState(() => _dragProgress = null),
                      onTapDown: (details) {
                        _updateProgress(details.localPosition.dx, availableWidth);
                        if (_dragProgress != null) {
                          final seekMs = (duration.inMilliseconds * _dragProgress!).clamp(0, duration.inMilliseconds).toInt();
                          widget.player.seek(Duration(milliseconds: seekMs));
                          setState(() => _dragProgress = null);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(barCount, (index) {
                          final isActive = (index / barCount) <= progressPercent;
                          final heightSeed = math.sin(index * 0.5) * 10 + math.cos(index * 0.2) * 8 + 14;
                          final barHeight = heightSeed.clamp(4.0, 32.0);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: barWidth.clamp(1.0, 4.0),
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isActive ? widget.textColor : widget.textSecondaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text(
                _formatDuration(duration),
                textAlign: TextAlign.right,
                style: GoogleFonts.outfit(
                  color: widget.textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateProgress(double dx, double width) {
    setState(() {
      _dragProgress = (dx / width).clamp(0.0, 1.0);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
