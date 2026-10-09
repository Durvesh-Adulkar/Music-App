import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track_model.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';

class MusicProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DownloadService _downloadService = DownloadService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Track> _tracks = [];
  List<Track> _searchResults = [];
  List<Track> _downloadedTracks = [];
  final Map<String, double> _downloadProgress = {};

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isOffline = false;
  int _offset = 0;
  bool _hasMore = true;

  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  Timer? _searchDebounceTimer;

  // Getters
  List<Track> get tracks => _tracks;
  List<Track> get searchResults => _searchResults;
  List<Track> get downloadedTracks => _downloadedTracks;
  Map<String, double> get downloadProgress => _downloadProgress;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isOffline => _isOffline;
  bool get hasMore => _hasMore;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  AudioPlayer get audioPlayer => _audioPlayer;

  MusicProvider() {
    _initAudioPlayer();
    _loadDownloadedTracks();
    fetchTracks();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (_isPlaying != state.playing) {
        _isPlaying = state.playing;
        notifyListeners();
      }
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.sequenceStateStream.listen((state) {
      final currentItem = state.currentSource?.tag as MediaItem?;
      if (currentItem != null) {
        final track = _findTrackById(currentItem.id);
        if (track != null && _currentTrack?.id != track.id) {
          _currentTrack = track;
          notifyListeners();
        }
      }
    });
  }

  Track? _findTrackById(String id) {
    try {
      return _downloadedTracks.firstWhere((t) => t.id == id);
    } catch (_) {
      try {
        return _tracks.firstWhere((t) => t.id == id);
      } catch (_) {
        try {
          return _searchResults.firstWhere((t) => t.id == id);
        } catch (_) {
          return null;
        }
      }
    }
  }

  Future<void> _loadDownloadedTracks() async {
    _downloadedTracks = await _downloadService.getDownloadedTracks();
    _syncDownloadedStatus();
    notifyListeners();
  }

  void _syncDownloadedStatus() {
    for (var track in _tracks) {
      final match = _downloadedTracks.where((dt) => dt.id == track.id).firstOrNull;
      if (match != null) {
        track.isDownloaded = true;
        track.localPath = match.localPath;
        track.localImagePath = match.localImagePath;
      } else {
        track.isDownloaded = false;
        track.localPath = null;
        track.localImagePath = null;
      }
    }
    for (var track in _searchResults) {
      final match = _downloadedTracks.where((dt) => dt.id == track.id).firstOrNull;
      if (match != null) {
        track.isDownloaded = true;
        track.localPath = match.localPath;
        track.localImagePath = match.localImagePath;
      }
    }
  }

  // Fetch online tracks with pull-to-refresh & offline fallback
  Future<void> fetchTracks({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (isRefresh) {
      _offset = 0;
      _hasMore = true;
    }
    if (!_hasMore && !isRefresh) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newTracks = await _apiService.fetchTracks(offset: _offset);
      _isOffline = false;

      if (isRefresh) {
        _tracks.clear();
      }

      if (newTracks.isEmpty) {
        _hasMore = false;
      } else {
        for (var track in newTracks) {
          final match = _downloadedTracks.where((dt) => dt.id == track.id).firstOrNull;
          if (match != null) {
            track.isDownloaded = true;
            track.localPath = match.localPath;
            track.localImagePath = match.localImagePath;
          }
        }
        _tracks.addAll(newTracks);
        _offset += 20;
      }
    } catch (e) {
      // Offline / Network error
      _isOffline = true;
      // Reload downloaded songs so user can play offline
      await _loadDownloadedTracks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Live search with debounce and instant offline results
  void liveSearch(String query) {
    _searchDebounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;

    // Instant local matches from downloaded & cached tracks
    final lower = trimmed.toLowerCase();
    final localMatches = <Track>{};
    for (var t in _downloadedTracks) {
      if (t.name.toLowerCase().contains(lower) || t.artistName.toLowerCase().contains(lower)) {
        localMatches.add(t);
      }
    }
    for (var t in _tracks) {
      if (t.name.toLowerCase().contains(lower) || t.artistName.toLowerCase().contains(lower)) {
        localMatches.add(t);
      }
    }

    _searchResults = localMatches.toList();
    _isLoading = true;
    notifyListeners();

    // Debounce online search by 350ms to make it fast without overwhelming API
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final onlineTracks = await _apiService.searchTracks(query: trimmed);
        _isOffline = false;

        // Merge results avoiding duplicates
        final merged = <String, Track>{};
        for (var t in _searchResults) {
          merged[t.id] = t;
        }
        for (var t in onlineTracks) {
          final match = _downloadedTracks.where((dt) => dt.id == t.id).firstOrNull;
          if (match != null) {
            t.isDownloaded = true;
            t.localPath = match.localPath;
            t.localImagePath = match.localImagePath;
          }
          merged[t.id] = t;
        }

        _searchResults = merged.values.toList();
      } catch (e) {
        // If offline, user still has the local matches
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    _isSearching = false;
    _searchResults.clear();
    _isLoading = false;
    notifyListeners();
  }

  // Play track (supports both online streaming and 100% offline local files)
  Future<void> playTrack(Track track, List<Track> playlist) async {
    _currentTrack = track;
    notifyListeners();

    try {
      final playlistAudioSource = ConcatenatingAudioSource(
        children: playlist.map((t) {
          Uri audioUri;
          final isLocal = t.isDownloaded && t.localPath != null && File(t.localPath!).existsSync();
          if (isLocal) {
            audioUri = Uri.file(t.localPath!);
          } else {
            audioUri = Uri.parse(t.audio.isNotEmpty ? t.audio : t.audioDownload);
          }

          Uri? artUri;
          if (t.localImagePath != null && File(t.localImagePath!).existsSync()) {
            artUri = Uri.file(t.localImagePath!);
          } else if (t.image.isNotEmpty && t.image.startsWith('http') && !_isOffline) {
            artUri = Uri.parse(t.image);
          }

          return AudioSource.uri(
            audioUri,
            tag: MediaItem(
              id: t.id,
              album: t.albumName,
              title: t.name,
              artist: t.artistName,
              artUri: artUri,
            ),
          );
        }).toList(),
      );

      final initialIndex = playlist.indexWhere((t) => t.id == track.id);
      await _audioPlayer.setAudioSource(
        playlistAudioSource,
        initialIndex: initialIndex >= 0 ? initialIndex : 0,
      );
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing track: $e");
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> nextTrack() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> previousTrack() async {
    if (_audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // Real download implementation with progress and offline catalog update
  Future<void> downloadTrack(Track track, BuildContext context) async {
    if (_downloadProgress.containsKey(track.id)) return; // Already in progress

    _downloadProgress[track.id] = 0.05;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${track.name}"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final path = await _downloadService.downloadTrack(track, (progress) {
      _downloadProgress[track.id] = progress;
      notifyListeners();
    });

    _downloadProgress.remove(track.id);

    if (path != null && File(path).existsSync()) {
      track.isDownloaded = true;
      track.localPath = path;

      await _loadDownloadedTracks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1DB954),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${track.name}" saved! Available in Offline Music.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Download failed. Check your internet connection.'),
          ),
        );
      }
    }
  }

  // Delete downloaded track
  Future<void> deleteTrack(Track track, BuildContext context) async {
    final success = await _downloadService.deleteDownloadedTrack(track.id);
    if (success) {
      track.isDownloaded = false;
      track.localPath = null;
      track.localImagePath = null;
      await _loadDownloadedTracks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "${track.name}" from offline music.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
