import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/track_model.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildCoverArt(BuildContext context, Track track) {
    final size = MediaQuery.of(context).size.width - 56;

    if (track.localImagePath != null && File(track.localImagePath!).existsSync()) {
      return Image.file(
        File(track.localImagePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    if (track.image.isNotEmpty && track.image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: track.image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        memCacheHeight: 600,
        placeholder: (_, __) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 64),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 64),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade900,
      child: const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 64),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Now Playing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          final track = provider.currentTrack;
          if (track == null) return const Center(child: Text('No track playing'));

          final isDownloading = provider.downloadProgress.containsKey(track.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildCoverArt(context, track),
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (track.isDownloaded) ...[
                                const Icon(Icons.offline_pin, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  track.artistName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.subtitleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isDownloading)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: (provider.downloadProgress[track.id] ?? 0.05) > 0.05
                              ? provider.downloadProgress[track.id]
                              : null,
                          color: AppTheme.primaryColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    else if (track.isDownloaded)
                      const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 28)
                    else
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: AppTheme.textColor, size: 28),
                        onPressed: () => provider.downloadTrack(track, context),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Slider(
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade800,
                  value: provider.currentPosition.inSeconds.toDouble().clamp(
                        0.0,
                        provider.totalDuration.inSeconds.toDouble() > 0
                            ? provider.totalDuration.inSeconds.toDouble()
                            : 1.0,
                      ),
                  max: provider.totalDuration.inSeconds.toDouble() > 0
                      ? provider.totalDuration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    provider.seekTo(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(provider.currentPosition),
                        style: const TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
                      ),
                      Text(
                        _formatDuration(provider.totalDuration),
                        style: const TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 42,
                      icon: const Icon(Icons.skip_previous, color: AppTheme.textColor),
                      onPressed: () => provider.previousTrack(),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 60,
                        icon: Icon(
                          provider.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                        ),
                        onPressed: () => provider.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      iconSize: 42,
                      icon: const Icon(Icons.skip_next, color: AppTheme.textColor),
                      onPressed: () => provider.nextTrack(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
