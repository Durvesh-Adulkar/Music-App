import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/track_model.dart';
import '../../providers/music_provider.dart';
import '../../core/theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  Widget _buildAlbumArt(Track track) {
    if (track.localImagePath != null && File(track.localImagePath!).existsSync()) {
      return Image.file(
        File(track.localImagePath!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );
    }
    if (track.image.isNotEmpty && track.image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: track.image,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade900,
      child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final track = provider.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
            );
          },
          child: Container(
            height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildAlbumArt(track),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (track.isDownloaded) ...[
                            const Icon(Icons.offline_pin, size: 12, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              track.artistName,
                              style: const TextStyle(
                                color: AppTheme.subtitleColor,
                                fontSize: 12,
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
                IconButton(
                  icon: Icon(
                    provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppTheme.primaryColor,
                    size: 36,
                  ),
                  onPressed: () {
                    provider.togglePlayPause();
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
