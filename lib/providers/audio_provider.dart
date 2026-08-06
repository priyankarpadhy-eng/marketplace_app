import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:market_app/services/github_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AudioState {
  final List<Map<String, String>> allAssets;
  final List<Map<String, String>> musicAssets;
  final List<Map<String, String>> queueAssets;
  final int selectedIndex;
  final bool isPlaying;
  final bool isBuffering;
  final LoopMode loopMode;
  final Set<String> downloadedTrackUrls;
  final Set<String> lovedTrackUrls;
  final Map<String, double> downloadProgress;
  final bool isLoading;
  final bool hasStartedPlaying;

  AudioState({
    this.allAssets = const [],
    this.musicAssets = const [],
    this.queueAssets = const [],
    this.selectedIndex = 0,
    this.isPlaying = false,
    this.isBuffering = false,
    this.loopMode = LoopMode.off,
    this.downloadedTrackUrls = const {},
    this.lovedTrackUrls = const {},
    this.downloadProgress = const {},
    this.isLoading = true,
    this.hasStartedPlaying = false,
  });

  AudioState copyWith({
    List<Map<String, String>>? allAssets,
    List<Map<String, String>>? musicAssets,
    List<Map<String, String>>? queueAssets,
    int? selectedIndex,
    bool? isPlaying,
    bool? isBuffering,
    LoopMode? loopMode,
    Set<String>? downloadedTrackUrls,
    Set<String>? lovedTrackUrls,
    Map<String, double>? downloadProgress,
    bool? isLoading,
    bool? hasStartedPlaying,
  }) {
    return AudioState(
      allAssets: allAssets ?? this.allAssets,
      musicAssets: musicAssets ?? this.musicAssets,
      queueAssets: queueAssets ?? this.queueAssets,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      loopMode: loopMode ?? this.loopMode,
      downloadedTrackUrls: downloadedTrackUrls ?? this.downloadedTrackUrls,
      lovedTrackUrls: lovedTrackUrls ?? this.lovedTrackUrls,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isLoading: isLoading ?? this.isLoading,
      hasStartedPlaying: hasStartedPlaying ?? this.hasStartedPlaying,
    );
  }
}

class AudioNotifier extends StateNotifier<AudioState> {
  final AudioPlayer audioPlayer = AudioPlayer();
  int _loadSequence = 0;

  AudioNotifier() : super(AudioState()) {
    _initAudioPlayerListeners();
  }

  void _initAudioPlayerListeners() {
    audioPlayer.playerStateStream.listen((playerState) {
      state = state.copyWith(
        isPlaying: playerState.playing,
        isBuffering: playerState.processingState == ProcessingState.buffering || 
                     playerState.processingState == ProcessingState.loading,
        hasStartedPlaying: playerState.processingState == ProcessingState.idle 
            ? false 
            : (playerState.playing ? true : state.hasStartedPlaying),
      );
    });

    audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < state.queueAssets.length) {
        state = state.copyWith(selectedIndex: index);
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('last_played_track_url', state.queueAssets[index]['url']!);
        });
      }
    });
  }

  Future<void> loadMusic() async {
    state = state.copyWith(isLoading: true);
    final assets = await GithubStorageService.instance.fetchMusicAssets();
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('last_played_track_url');
    
    List<String> loved = [];
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && doc.data()!.containsKey('loved_tracks')) {
          loved = List<String>.from(doc.data()!['loved_tracks'] ?? []);
          prefs.setStringList('loved_tracks', loved); // sync locally
        } else {
          loved = prefs.getStringList('loved_tracks') ?? [];
        }
      } catch (e) {
        loved = prefs.getStringList('loved_tracks') ?? [];
      }
    } else {
      loved = prefs.getStringList('loved_tracks') ?? [];
    }

    final downloaded = prefs.getStringList('downloaded_tracks') ?? [];

    int initialIndex = 0;
    if (savedUrl != null) {
      final savedIndex = assets.indexWhere((t) => t['url'] == savedUrl);
      if (savedIndex != -1) {
        initialIndex = savedIndex;
      }
    }

    state = state.copyWith(
      allAssets: assets,
      musicAssets: assets,
      queueAssets: assets,
      selectedIndex: initialIndex,
      lovedTrackUrls: loved.toSet(),
      downloadedTrackUrls: downloaded.toSet(),
      isLoading: false,
    );

    if (assets.isNotEmpty) {
      await _playQueue(assets, initialIndex);
    }
  }

  Future<void> _playQueue(List<Map<String, String>> queue, int initialIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final sources = <AudioSource>[];
    for (var track in queue) {
      final url = track['url']!;
      final trackName = track['name']?.replaceAll('.mp3', '') ?? 'Unknown Track';
      final localPath = prefs.getString('local_path_$url');
      if (state.downloadedTrackUrls.contains(url) && localPath != null && File(localPath).existsSync()) {
        sources.add(AudioSource.uri(
          Uri.file(localPath),
          tag: MediaItem(id: url, title: trackName, artist: 'Local Track'),
        ));
      } else {
        sources.add(LockCachingAudioSource(
          Uri.parse(url),
          tag: MediaItem(id: url, title: trackName, artist: 'Streamed Track'),
        ));
      }
    }
    final playlist = ConcatenatingAudioSource(children: sources);
    await audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
  }

  void setSelectedIndex(int index) {
    if (index < 0 || index >= state.musicAssets.length) return;
    
    // Check if the new queue is identical to the current queue
    bool isSameQueue = state.queueAssets.length == state.musicAssets.length;
    if (isSameQueue) {
      for (int i = 0; i < state.musicAssets.length; i++) {
        if (state.queueAssets[i]['url'] != state.musicAssets[i]['url']) {
          isSameQueue = false;
          break;
        }
      }
    }

    state = state.copyWith(queueAssets: state.musicAssets, selectedIndex: index);
    
    if (isSameQueue && audioPlayer.audioSource != null) {
      audioPlayer.seek(Duration.zero, index: index).then((_) {
        audioPlayer.play();
      });
    } else {
      _playQueue(state.musicAssets, index).then((_) {
        audioPlayer.play();
      });
    }
  }

  void playNext() {
    audioPlayer.seekToNext();
    audioPlayer.play();
  }

  void playPrevious() {
    audioPlayer.seekToPrevious();
    audioPlayer.play();
  }

  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void toggleLoopMode() {
    final nextMode = state.loopMode == LoopMode.off 
        ? LoopMode.all 
        : (state.loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
    state = state.copyWith(loopMode: nextMode);
    
    audioPlayer.setLoopMode(nextMode);
  }

  void toggleLoved(String url) async {
    final newLoved = Set<String>.from(state.lovedTrackUrls);
    if (newLoved.contains(url)) {
      newLoved.remove(url);
    } else {
      newLoved.add(url);
    }
    state = state.copyWith(lovedTrackUrls: newLoved);
    
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('loved_tracks', newLoved.toList());

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'loved_tracks': newLoved.toList(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void updateMusicList(List<Map<String, String>> newAssets) {
    state = state.copyWith(musicAssets: newAssets);
    // Note: We DO NOT update the queueAssets or selectedIndex here!
    // This allows the current track to keep playing seamlessly from the old queue
    // even if the user filters the list via search or toggles the 'Loved' tab.
  }

  void filterMusic(bool showLoved, String query) {
    List<Map<String, String>> filtered = state.allAssets;
    if (showLoved) {
      filtered = filtered.where((t) => state.lovedTrackUrls.contains(t['url'])).toList();
    }
    updateMusicList(filtered);
  }

  void addDownloadedTrack(String url, String localPath) async {
    final newDownloaded = Set<String>.from(state.downloadedTrackUrls);
    newDownloaded.add(url);
    state = state.copyWith(downloadedTrackUrls: newDownloaded);
    
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('downloaded_tracks', newDownloaded.toList());
    prefs.setString('local_path_$url', localPath);

    if (state.selectedIndex >= 0 && state.selectedIndex < state.queueAssets.length) {
      final currentTrack = state.queueAssets[state.selectedIndex];
      if (currentTrack['url'] == url) {
        final playlistIndex = state.queueAssets.indexWhere((t) => t['url'] == url);
        if (playlistIndex != -1 && playlistIndex == state.selectedIndex) {
          final wasPlaying = audioPlayer.playing;
          final currentPosition = audioPlayer.position;
          
          await _playQueue(state.queueAssets, playlistIndex);
          await audioPlayer.seek(currentPosition);
          if (wasPlaying) {
            audioPlayer.play();
          }
        }
      }
    }
  }

  Future<void> downloadTrack(String url, String name) async {
    if (state.downloadedTrackUrls.contains(url)) return;
    
    final progressMap = Map<String, double>.from(state.downloadProgress);
    progressMap[url] = 0.01;
    state = state.copyWith(downloadProgress: progressMap);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name.mp3');
      
      final dio = Dio();
      await dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final pMap = Map<String, double>.from(state.downloadProgress);
            pMap[url] = received / total;
            state = state.copyWith(downloadProgress: pMap);
          }
        },
      );

      final pMap = Map<String, double>.from(state.downloadProgress);
      pMap.remove(url);
      state = state.copyWith(downloadProgress: pMap);
      
      addDownloadedTrack(url, file.path);
    } catch (e) {
      final pMap = Map<String, double>.from(state.downloadProgress);
      pMap.remove(url);
      state = state.copyWith(downloadProgress: pMap);
    }
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});
