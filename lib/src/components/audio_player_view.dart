import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';

class AudioPlayerView extends StatelessWidget {
  final PlayerState state;
  final VoidCallback? onTap;

  const AudioPlayerView({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAlbumArt(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      state.currentItem?.title ?? 'Unknown',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentItem?.artist ?? 'Unknown Artist',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildAlbumArt() {
    final thumbnailUrl = state.currentItem?.thumbnailUrl;
    final isLocalFile = state.currentItem?.isLocal ?? false;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImage(thumbnailUrl, isLocalFile),
      ),
    );
  }

  Widget _buildImage(String? thumbnailUrl, bool isLocalFile) {
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      if (isLocalFile && _isLocalImagePath(thumbnailUrl)) {
        return Image.file(
          File(thumbnailUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } else if (!isLocalFile || _isNetworkUrl(thumbnailUrl)) {
        return Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }

    return _buildPlaceholder();
  }

  bool _isLocalImagePath(String path) {
    return path.startsWith('/') || 
           path.startsWith(r'C:\') || 
           path.startsWith(r'D:\') || 
           path.contains(':\\');
  }

  bool _isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(
        Icons.music_note,
        size: 100,
        color: Colors.white54,
      ),
    );
  }
}
