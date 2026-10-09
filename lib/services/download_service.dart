import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track_model.dart';

class DownloadService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );
  static const String _downloadsKey = 'downloaded_tracks';

  // Get all verified downloaded tracks that exist on disk
  Future<List<Track>> getDownloadedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_downloadsKey);
      if (data == null || data.isEmpty) return [];

      final List<dynamic> decoded = json.decode(data);
      final List<Track> tracks = [];
      bool hadMissingFiles = false;

      for (var item in decoded) {
        try {
          final track = Track.fromJson(Map<String, dynamic>.from(item));
          // Verify that the downloaded audio file actually exists on device
          if (track.localPath != null && File(track.localPath!).existsSync()) {
            track.isDownloaded = true;
            tracks.add(track);
          } else {
            hadMissingFiles = true;
          }
        } catch (_) {}
      }

      // If any deleted file was detected, update preferences
      if (hadMissingFiles) {
        await prefs.setString(
          _downloadsKey,
          json.encode(tracks.map((t) => t.toJson()).toList()),
        );
      }

      return tracks;
    } catch (e) {
      return [];
    }
  }

  // Save or update a track in the downloaded tracks list
  Future<void> saveDownloadedTrack(Track track) async {
    final prefs = await SharedPreferences.getInstance();
    List<Track> downloaded = await getDownloadedTracks();

    downloaded.removeWhere((t) => t.id == track.id);
    downloaded.insert(0, track);

    await prefs.setString(
      _downloadsKey,
      json.encode(downloaded.map((t) => t.toJson()).toList()),
    );
  }

  // Real download of track audio and album cover artwork
  Future<String?> downloadTrack(Track track, Function(double) onProgress) async {
    try {
      final audioUrl = track.audioDownload.isNotEmpty ? track.audioDownload : track.audio;
      if (audioUrl.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${track.id}.mp3';
      final imagePath = '${dir.path}/${track.id}_cover.jpg';

      // Check if already downloaded on disk
      if (File(savePath).existsSync() && File(savePath).lengthSync() > 1000) {
        track.isDownloaded = true;
        track.localPath = savePath;
        if (File(imagePath).existsSync()) {
          track.localImagePath = imagePath;
        }
        await saveDownloadedTrack(track);
        return savePath;
      }

      // Download audio file with live progress
      await _dio.download(
        audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      // Download cover image for true offline experience
      if (track.image.isNotEmpty && track.image.startsWith('http')) {
        try {
          await _dio.download(track.image, imagePath);
          track.localImagePath = imagePath;
        } catch (_) {}
      }

      track.isDownloaded = true;
      track.localPath = savePath;
      await saveDownloadedTrack(track);

      return savePath;
    } catch (e) {
      return null;
    }
  }

  // Delete downloaded song from storage and preference
  Future<bool> deleteDownloadedTrack(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Track> downloaded = await getDownloadedTracks();

      final track = downloaded.firstWhere((t) => t.id == trackId);
      if (track.localPath != null && File(track.localPath!).existsSync()) {
        try {
          File(track.localPath!).deleteSync();
        } catch (_) {}
      }
      if (track.localImagePath != null && File(track.localImagePath!).existsSync()) {
        try {
          File(track.localImagePath!).deleteSync();
        } catch (_) {}
      }

      downloaded.removeWhere((t) => t.id == trackId);
      await prefs.setString(
        _downloadsKey,
        json.encode(downloaded.map((t) => t.toJson()).toList()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isTrackDownloaded(String trackId) async {
    final downloaded = await getDownloadedTracks();
    return downloaded.any((t) => t.id == trackId);
  }
}
