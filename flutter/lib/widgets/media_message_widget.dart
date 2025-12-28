import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';

class MediaMessageWidget extends StatefulWidget {
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String mediaType;
  final int? duration;
  final String? filename;
  final VoidCallback? onTap;

  const MediaMessageWidget({
    super.key,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    this.duration,
    this.filename,
    this.onTap,
  });

  @override
  State<MediaMessageWidget> createState() => _MediaMessageWidgetState();
}

class _MediaMessageWidgetState extends State<MediaMessageWidget> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video' && widget.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl!),
      );
      _videoController!.initialize();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (widget.mediaUrl == null) return;

    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(UrlSource(widget.mediaUrl!));
      setState(() => _isPlayingAudio = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlayingAudio = false);
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrl == null) {
      return const SizedBox.shrink();
    }

    switch (widget.mediaType) {
      case 'image':
        return _buildImage();
      case 'video':
        return _buildVideo();
      case 'audio':
        return _buildAudio();
      default:
        return _buildGenericMedia();
    }
  }

  Widget _buildImage() {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.mediaUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 200,
            color: AppTheme.backgroundGray,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 200,
            color: AppTheme.backgroundGray,
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    return GestureDetector(
      onTap: widget.onTap ?? () {},
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: 250,
                    height: 200,
                    placeholder: (context, url) => Container(
                      width: 250,
                      height: 200,
                      color: AppTheme.backgroundGray,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  )
                : Container(
                    width: 250,
                    height: 200,
                    color: AppTheme.backgroundGray,
                    child: const Icon(Icons.videocam, size: 48),
                  ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          if (widget.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(widget.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudio() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlayingAudio ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAudio,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Audio',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (widget.duration != null)
                Text(
                  _formatDuration(widget.duration!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textGray,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericMedia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attachment),
          const SizedBox(width: 8),
          Text(
            widget.filename ?? 'Media',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

