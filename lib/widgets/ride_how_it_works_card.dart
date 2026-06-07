import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' as math;

class RideHowItWorksCard extends StatefulWidget {
  const RideHowItWorksCard({super.key});

  @override
  State<RideHowItWorksCard> createState() => _RideHowItWorksCardState();
}

class _RideHowItWorksCardState extends State<RideHowItWorksCard> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  bool _isPlaying = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset('assets/1775883478401171421y0pemdar-voicemaker.in-speech.mp3');
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (_isPlaying) _isExpanded = true; // Auto-expand when playing
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.blue.shade50, Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.05),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 14, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    "HOW IT WORKS",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.blueAccent,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isExpanded)
                               Padding(
                                 padding: const EdgeInsets.only(left: 8.0),
                                 child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent.withOpacity(0.5), size: 18),
                               ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // Prevent toggle expansion when clicking play
                            _togglePlayback();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    AnimatedClipRect(
                      open: _isExpanded,
                      horizontalAnimation: false,
                      verticalAnimation: true,
                      alignment: Alignment.topCenter,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            "Suppose you are going to talcher road but you are alone but there must be other person going to same place from other hostels, so you can create a ride or you can join a ride and persons going to same destination can join your ride so you can split the cost.",
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isPlaying)
                            Row(
                              children: [
                                Text(
                                  "Listening guide...",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 20,
                                  child: Row(
                                    children: List.generate(5, (index) {
                                      return _MusicVisualizerBar(
                                        controller: _animationController,
                                        index: index,
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.volume_up_outlined, size: 16, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  "Tap play for audio guide",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Tap to minimize",
                                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.blueAccent.withOpacity(0.5)),
                                ),
                                Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Colors.blueAccent.withOpacity(0.5)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedClipRect extends StatefulWidget {
  @override
  _AnimatedClipRectState createState() => _AnimatedClipRectState();

  final Widget child;
  final bool open;
  final bool horizontalAnimation;
  final bool verticalAnimation;
  final Alignment alignment;
  final Duration duration;
  final Curve curve;

  AnimatedClipRect({
    required this.child,
    required this.open,
    this.horizontalAnimation = true,
    this.verticalAnimation = true,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.linear,
  });
}

class _AnimatedClipRectState extends State<AnimatedClipRect> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    _animationController = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _animationController, curve: widget.curve);
    if (widget.open) {
      _animationController.value = 1.0;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    widget.open ? _animationController.forward() : _animationController.reverse();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: widget.alignment,
            heightFactor: widget.verticalAnimation ? _animation.value : 1.0,
            widthFactor: widget.horizontalAnimation ? _animation.value : 1.0,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _MusicVisualizerBar extends StatelessWidget {
  final AnimationController controller;
  final int index;

  const _MusicVisualizerBar({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = controller.value + (index * 0.2);
        if (value > 1.0) value -= 1.0;
        
        // Create an oscillating height effect
        double height = 4 + (math.sin(value * 2 * math.pi).abs() * 12);
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
