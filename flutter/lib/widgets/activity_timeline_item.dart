import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ActivityTimelineItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback? onTap;

  const ActivityTimelineItem({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final createdAt = activity['created_at'] as String?;
    final date = createdAt != null ? DateTime.parse(createdAt) : DateTime.now();
    final formattedDate = DateFormat('MMMM d, y').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    
    final type = activity['type'] as String? ?? activity['action'] as String? ?? '';
    final content = activity['content'] as String? ?? '';
    final image = activity['image'];
    final profile = activity['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final lastName = profile?['last_name'] as String? ?? '';
    final initials = ((firstName.isNotEmpty ? firstName[0] : '?') +
            (lastName.isNotEmpty ? lastName[0] : ''))
        .toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.borderGray,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              // Only show line if not last item (we'll handle this in parent)
              Container(
                width: 2,
                height: 24, // Fixed height for line
                color: AppTheme.borderGray,
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$formattedDate, $formattedTime',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.backgroundGray,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posted by $firstName $lastName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (image != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: image is List ? image[0] : image,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppTheme.backgroundGray,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

