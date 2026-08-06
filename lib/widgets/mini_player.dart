import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_app/providers/audio_provider.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:just_audio/just_audio.dart';
import 'package:market_app/widgets/now_playing_sheet.dart';
import 'dart:async';
import 'package:market_app/screens/music_screen.dart'; // For SpectrumVisualizer

class GlobalMiniPlayer extends ConsumerStatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  ConsumerState<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends ConsumerState<GlobalMiniPlayer> {
  Timer? _inactivityTimer;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        ref.read(audioProvider.notifier).audioPlayer.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AudioState>(audioProvider, (previous, current) {
      if (current.isPlaying) {
        _inactivityTimer?.cancel();
      } else if (previous?.isPlaying == true && !current.isPlaying) {
        _startInactivityTimer();
      }
    });

    // Handle initial state if it starts paused but loaded
    if (!audioState.isPlaying && 
        audioNotifier.audioPlayer.processingState != ProcessingState.idle && 
        (_inactivityTimer == null || !_inactivityTimer!.isActive)) {
      _startInactivityTimer();
    }

    // Do not show if there are no loaded music assets, player is stopped, or it has never started playing
    if (audioState.musicAssets.isEmpty || 
        audioNotifier.audioPlayer.processingState == ProcessingState.idle ||
        !audioState.hasStartedPlaying) {
      return const SizedBox.shrink();
    }

    final track = audioState.queueAssets.length > audioState.selectedIndex 
        ? audioState.queueAssets[audioState.selectedIndex] 
        : null;
        
    if (track == null) return const SizedBox.shrink();

    final trackName = track['name']?.replaceAll('.mp3', '') ?? 'Unknown Track';
    const _imagePattern = [1, 5, 2, 6, 3, 7, 4, 8];
    final int imageId = _imagePattern[audioState.selectedIndex % _imagePattern.length];

    return GestureDetector(
      onTap: () => NowPlayingSheet.show(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          // Swipe down to dismiss
          audioNotifier.audioPlayer.stop();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A).withOpacity(0.6) : const Color(0xFFE5E5E5).withOpacity(0.6),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1),
            ),
            child: Row(
              children: [
                // Track Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage('assets/music$imageId.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: audioState.isPlaying
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SpectrumVisualizer(
                          isPlaying: true,
                          color: Colors.white,
                          useSingleColor: true,
                          barCount: 4,
                          maxHeight: 20,
                          minHeight: 4,
                          barWidth: 3,
                        ),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                
                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<Duration>(
                        stream: audioNotifier.audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = audioNotifier.audioPlayer.duration ?? Duration.zero;
                          final progress = duration.inMilliseconds > 0 
                              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0;
                              
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 2,
                              backgroundColor: AppTheme.textSecondary(isDark).withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Play/Pause Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: audioState.isBuffering 
                      ? SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: AppTheme.textPrimary(isDark), strokeWidth: 2)
                        )
                      : Icon(
                          audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppTheme.textPrimary(isDark),
                          size: 28,
                        ),
                  onPressed: () => audioNotifier.togglePlayPause(),
                ),
                
                // Close/Stop Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary(isDark), size: 24),
                  onPressed: () => audioNotifier.audioPlayer.stop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
