import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/media_service.dart';
import '../../theme/app_theme.dart';

class MediaPreviewScreen extends StatefulWidget {
  final MediaAttachment media;
  final String? initialCaption;
  final Map<String, dynamic>? replyToMessage;
  final String binId;
  final String? replyToMessageId;
  final Function(MediaAttachment, String?)? onSend;

  const MediaPreviewScreen({
    super.key,
    required this.media,
    required this.binId,
    this.initialCaption,
    this.replyToMessage,
    this.replyToMessageId,
    this.onSend,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption ?? '';
    
    if (widget.media.type == MediaType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(widget.media.file);
    await _videoController!.initialize();
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _sendMedia() async {
    if (_isSending) return;
    
    final caption = _captionController.text.trim();
    
    setState(() {
      _isSending = true;
    });

    try {
      // If onSend callback is provided, use it to send immediately
      if (widget.onSend != null) {
        await widget.onSend!(widget.media, caption.isEmpty ? null : caption);
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Fallback: return data to parent
        Navigator.pop(context, {
          'media': widget.media,
          'caption': caption.isEmpty ? null : caption,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Optional: Add editing tools here in the future
          // For now, we'll keep it simple
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Media Preview Area
            Expanded(
              child: Center(
                child: widget.media.type == MediaType.image
                    ? _buildImagePreview()
                    : widget.media.type == MediaType.video
                        ? _buildVideoPreview()
                        : _buildAudioPreview(),
              ),
            ),
            
            // Reply Preview (if replying)
            if (widget.replyToMessage != null)
              _buildReplyPreview(),
            
            // Caption Input Area
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[700],
                          size: 20,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMedia,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Image.file(
        widget.media.file,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        // Play/Pause overlay
        GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mic,
          size: 64,
          color: Colors.white70,
        ),
        const SizedBox(height: 16),
        Text(
          'Audio Recording',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final senderProfile = widget.replyToMessage!['sender_profile'] as Map<String, dynamic>?;
    final senderFirstName = senderProfile?['first_name'] as String? ?? 'User';
    final message = widget.replyToMessage!['is_deleted'] == true
        ? 'This message was deleted'
        : widget.replyToMessage!['message'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.primaryGreen, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderFirstName,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

