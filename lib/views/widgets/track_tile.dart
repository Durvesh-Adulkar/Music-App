import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/track_model.dart';
import '../../core/theme.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final double? downloadProgress;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onDownload,
    this.onDelete,
    this.downloadProgress,
    this.isPlaying = false,
  });

  Widget _buildAlbumArt() {
    // If local image is cached on disk
    if (track.localImagePath != null && File(track.localImagePath!).existsSync()) {
      return Image.file(
        File(track.localImagePath!),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackArt(),
      );
    }

    if (track.image.isNotEmpty && track.image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: track.image,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        memCacheWidth: 160,
        memCacheHeight: 160,
        placeholder: (_, __) => _buildFallbackArt(),
        errorWidget: (_, __, ___) => _buildFallbackArt(),
      );
    }

    return _buildFallbackArt();
  }

  Widget _buildFallbackArt() {
    return Container(
      width: 52,
      height: 52,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDownloading = downloadProgress != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildAlbumArt(),
        ),
        title: Text(
          track.name,
          style: TextStyle(
            color: isPlaying ? AppTheme.primaryColor : AppTheme.textColor,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (track.isDownloaded) ...[
              const Icon(Icons.offline_pin, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                track.artistName,
                style: const TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDownloading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: downloadProgress! > 0.05 ? downloadProgress : null,
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor,
                ),
              )
            else if (track.isDownloaded)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Remove from offline',
                    ),
                ],
              )
            else if (onDownload != null)
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppTheme.subtitleColor),
                onPressed: onDownload,
                tooltip: 'Download song',
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
