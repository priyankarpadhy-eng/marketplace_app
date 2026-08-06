import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:market_app/models/app_user.dart';
import 'package:market_app/services/github_storage_service.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/providers/audio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_app/widgets/now_playing_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:market_app/widgets/app_loader.dart';

class MusicScreen extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const MusicScreen({super.key, required this.currentUser});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollControllerAll;
  late ScrollController _scrollControllerLoved;
  final TextEditingController _searchController = TextEditingController();
  bool _showLovedOnly = false;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: _showLovedOnly ? 1 : 0);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation?.value == _tabController.index) {
        final isLoved = _tabController.index == 1;
        if (_showLovedOnly != isLoved) {
          setState(() {
            _showLovedOnly = isLoved;
          });
          ref.read(audioProvider.notifier).filterMusic(isLoved, _searchController.text);
        }
      }
    });
    
    _scrollControllerAll = ScrollController();
    _scrollControllerLoved = ScrollController();
    // Kick off the load only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider.notifier).loadMusic().then((_) {
        final state = ref.read(audioProvider);
        if (state.selectedIndex > 0) {
          final activeScrollController = _showLovedOnly ? _scrollControllerLoved : _scrollControllerAll;
          if (activeScrollController.hasClients) {
            activeScrollController.jumpTo(state.selectedIndex * 80.0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerAll.dispose();
    _scrollControllerLoved.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    int matchIndex = -1;
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      final audioState = ref.read(audioProvider);
      
      List<Map<String, String>> currentAssets = audioState.allAssets;
      if (_showLovedOnly) {
        currentAssets = currentAssets.where((t) => audioState.lovedTrackUrls.contains(t['url'])).toList();
      }
      
      matchIndex = currentAssets.indexWhere((t) => (t['name'] ?? '').toLowerCase().contains(q));
      
      final activeScrollController = _showLovedOnly ? _scrollControllerLoved : _scrollControllerAll;
      if (matchIndex != -1 && activeScrollController.hasClients) {
        // Approximate height of a track tile is 86 pixels
        activeScrollController.animateTo(
          matchIndex * 86.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    setState(() {
      _highlightedIndex = matchIndex;
    });
  }

  bool _isRequesting = false;

  Future<void> _requestSong(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isRequesting = true);
    try {
      await FirebaseFirestore.instance.collection('song_requests').add({
        'query': query.trim(),
        'requestedBy': widget.currentUser.id,
        'requestedByName': widget.currentUser.name,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent successfully!', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request.', style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Widget _buildRequestSongCard(bool isDark, String query) {
    return Card(
      color: AppTheme.surface(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_rounded, size: 48, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Song not found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find "$query" in our library. Would you like to request it?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isRequesting ? null : () => _requestSong(query),
                child: _isRequesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Request Song',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final audioState = ref.watch(audioProvider);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt(isDark),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: TextField(
                          style: GoogleFonts.outfit(color: AppTheme.textPrimary(isDark), fontSize: 14),
                          textInputAction: TextInputAction.search,
                          controller: _searchController,
                          onChanged: (query) {
                            _performSearch(query);
                          },
                          onSubmitted: (query) {
                            _performSearch(query);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search songs...',
                            hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark), fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTheme.textSecondary(isDark)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close, size: 18, color: AppTheme.textSecondary(isDark)),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(audioProvider.notifier).filterMusic(_showLovedOnly, '');
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Floating Toggle Switch
                  Container(
                    height: 40,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.surface(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.textPrimary(isDark),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: AppTheme.surface(isDark),
                      unselectedLabelColor: AppTheme.textSecondary(isDark),
                      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      splashBorderRadius: BorderRadius.circular(20),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Loved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Standard List View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMusicList(audioState, isDark, false),
                  _buildMusicList(audioState, isDark, true),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ));
  }

  Widget _buildMusicList(AudioState audioState, bool isDark, bool isLoved) {
    List<Map<String, String>> currentAssets = audioState.allAssets;
    if (isLoved) {
      currentAssets = currentAssets.where((t) => audioState.lovedTrackUrls.contains(t['url'])).toList();
    }
    
    final ScrollController scrollController = isLoved ? _scrollControllerLoved : _scrollControllerAll;
    
    if (audioState.isLoading) return const AppLoader();
    if (currentAssets.isEmpty) {
      return Center(
        child: _searchController.text.trim().isNotEmpty
          ? _buildRequestSongCard(isDark, _searchController.text.trim())
          : Text(
              isLoved ? 'No loved songs yet' : 'No tracks available',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark)),
            ),
      );
    }
    
    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: currentAssets.length,
      itemBuilder: (context, index) {
        final track = currentAssets[index];
        final currentPlayingUrl = audioState.queueAssets.isNotEmpty && audioState.selectedIndex >= 0 && audioState.selectedIndex < audioState.queueAssets.length
            ? audioState.queueAssets[audioState.selectedIndex]['url']
            : null;
        final isSelected = track['url'] == currentPlayingUrl;
        
        return _buildTrackTile(track, isDark, audioState, index, isSelected, () {
          final notifier = ref.read(audioProvider.notifier);
          if (isSelected) {
            notifier.togglePlayPause();
          } else {
            notifier.updateMusicList(currentAssets);
            notifier.setSelectedIndex(index);
          }
        });
      },
    );
  }

  Widget _buildTrackTile(Map<String, String> track, bool isDark, AudioState audioState, int index, bool isSelected, VoidCallback onTap) {
    final trackName = track['name']?.replaceAll('.mp3', '') ?? 'Unknown Track';
    final url = track['url'] ?? '';
    final isLoved = audioState.lovedTrackUrls.contains(url);
    final isDownloaded = audioState.downloadedTrackUrls.contains(url);
    final downloadProgress = audioState.downloadProgress[url];
    final isHighlighted = index == _highlightedIndex;

    const _imagePattern = [1, 5, 2, 6, 3, 7, 4, 8];
    final int imageId = _imagePattern[index % _imagePattern.length];

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted 
              ? AppTheme.accent(isDark).withOpacity(0.15)
              : (isSelected ? AppTheme.surfaceAlt(isDark).withOpacity(0.5) : AppTheme.surface(isDark)),
          borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppTheme.accent(isDark) : (isDark ? Colors.white12 : Colors.black12), 
          width: 1
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Track Icon/Art
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage('assets/music$imageId.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: isSelected && audioState.isPlaying
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const RepaintBoundary(
                        child: SpectrumVisualizer(
                          isPlaying: true,
                          color: Colors.white,
                          useSingleColor: true,
                          barCount: 4,
                          maxHeight: 24,
                          minHeight: 4,
                          barWidth: 4,
                        ),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 16),
              
              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary(isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              

              // Download Button
              if (downloadProgress != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 20, height: 20,
                  child: CircularProgressIndicator(value: downloadProgress, color: AppTheme.primary, strokeWidth: 2)
                )
              else
                IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.offline_pin_rounded : Icons.download_rounded,
                    color: isDownloaded ? AppTheme.success : AppTheme.textSecondary(isDark),
                    size: 20,
                  ),
                  onPressed: () => ref.read(audioProvider.notifier).downloadTrack(url, trackName),
                ),
                
              // Heart Button
              IconButton(
                icon: Icon(
                  isLoved ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isLoved ? AppTheme.error : AppTheme.textSecondary(isDark),
                  size: 20,
                ),
                onPressed: () => ref.read(audioProvider.notifier).toggleLoved(url),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}


class SpectrumVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;
  final double maxHeight;
  final double minHeight;
  final double barWidth;
  final bool useSingleColor;

  const SpectrumVisualizer({
    super.key, 
    required this.isPlaying, 
    required this.color,
    this.barCount = 4,
    this.maxHeight = 16.0,
    this.minHeight = 6.0,
    this.barWidth = 4.0,
    this.useSingleColor = false,
  });

  @override
  State<SpectrumVisualizer> createState() => _SpectrumVisualizerState();
}

class _SpectrumVisualizerState extends State<SpectrumVisualizer> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }
  
  void _initControllers() {
    _controllers = List.generate(widget.barCount, (index) {
      final duration = 300 + (index * (1500 ~/ widget.barCount)); // spread
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: duration),
      )..addListener(() => setState(() {}));
    });
    if (widget.isPlaying) _startAnimation();
  }

  @override
  void didUpdateWidget(SpectrumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barCount != widget.barCount) {
      for (var c in _controllers) { c.dispose(); }
      _initControllers();
    }
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (var controller in _controllers) {
      controller.animateTo(0.1, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static const List<Color> _spectrumColors = [
    Color(0xFFFFD600), // Yellow
    Color(0xFF00E5FF), // Cyan
    Color(0xFF00E676), // Green
    Color(0xFFFFFFFF), // White
    Color(0xFFFF5252), // Red
    Color(0xFFFF9100), // Orange
    Color(0xFF2979FF), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final height = widget.minHeight + (widget.maxHeight * _controllers[index].value);
          
          final color = widget.useSingleColor ? widget.color : _spectrumColors[index % _spectrumColors.length];
          
          return Container(
            width: widget.barWidth,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.barWidth / 2),
              boxShadow: widget.useSingleColor ? [] : [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      _startScrolling();
    }
  }

  void _startScrolling() async {
    if (_isScrolling || !mounted) return;
    _isScrolling = true;
    
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: (widget.text.length * 80).clamp(2000, 10000)),
          curve: Curves.linear,
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    _isScrolling = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
