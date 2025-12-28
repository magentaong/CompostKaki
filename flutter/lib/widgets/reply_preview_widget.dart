import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReplyPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> repliedToMessage;
  final VoidCallback onCancel;

  const ReplyPreviewWidget({
    super.key,
    required this.repliedToMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final message = repliedToMessage['message'] as String? ?? '';
    final senderProfile = repliedToMessage['sender_profile'] as Map<String, dynamic>?;
    final senderFirstName = senderProfile?['first_name'] as String? ?? 'User';
    final senderLastName = senderProfile?['last_name'] as String? ?? '';
    final senderName = '$senderFirstName $senderLastName'.trim();
    final mediaType = repliedToMessage['media_type'] as String?;
    final isDeleted = repliedToMessage['is_deleted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.primaryGreen, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                if (isDeleted)
                  const Text(
                    'This message was deleted',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textGray,
                    ),
                  )
                else if (mediaType != null)
                  Row(
                    children: [
                      Icon(
                        _getMediaIcon(mediaType),
                        size: 14,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getMediaLabel(mediaType),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    message.isEmpty ? '(Empty message)' : message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(String mediaType) {
    switch (mediaType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.mic;
      default:
        return Icons.attachment;
    }
  }

  String _getMediaLabel(String mediaType) {
    switch (mediaType) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      default:
        return 'Media';
    }
  }
}

