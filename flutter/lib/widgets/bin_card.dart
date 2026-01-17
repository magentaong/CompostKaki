import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BinCard extends StatelessWidget {
  final Map<String, dynamic> bin;
  final VoidCallback onTap;
  final bool hasPendingRequest;
  final int? unreadMessageCount;
  final int? unreadActivityCount;
  final int? unreadJoinRequestCount;

  const BinCard({
    super.key,
    required this.bin,
    required this.onTap,
    this.hasPendingRequest = false,
    this.unreadMessageCount,
    this.unreadActivityCount,
    this.unreadJoinRequestCount,
  });

  static const _defaultBinImage =
      'https://tqpjrlwdgoctacfrbanf.supabase.co/storage/v1/object/public/bin-images/image_2025-11-18_153342109.png';
  static const _legacyDefaultImages = {
    'https://images.unsplash.com/photo-1445620466293-d6316372ab59?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1445620466293-d6316372ab59?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80',
  };
  String _resolveBinImage(String? image) {
    if (image == null) return _defaultBinImage;
    final trimmed = image.trim();
    if (trimmed.isEmpty || _legacyDefaultImages.contains(trimmed)) {
      return _defaultBinImage;
    }
    return trimmed;
  }

  Color _getHealthColor(String? status) {
    switch (status) {
      case 'Critical':
        return AppTheme.healthCritical;
      case 'Healthy':
        return AppTheme.healthHealthy;
      case 'Needs Attention':
        return AppTheme.healthNeedsAttention;
      default:
        return AppTheme.healthHealthy;
    }
  }

  Color _getHealthTextColor(String? status) {
    switch (status) {
      case 'Critical':
        return AppTheme.healthCriticalText;
      case 'Healthy':
        return Colors.black87;
      case 'Needs Attention':
        return AppTheme.healthNeedsAttentionText;
      default:
        return Colors.black87;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'resting':
        return Colors.orange;
      case 'matured':
        return Colors.purple;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'resting':
        return 'Resting';
      case 'matured':
        return 'Matured';
      default:
        return 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthStatus = bin['health_status'] as String? ?? 'Healthy';
    final binStatus = bin['bin_status'] as String? ?? 'active';
    final temperature = bin['latest_temperature'];
    final binImage = _resolveBinImage(bin['image'] as String?);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bin image with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      key: ValueKey(
                          '${bin['id']}_${bin['updated_at'] ?? DateTime.now().millisecondsSinceEpoch}'),
                      imageUrl: binImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.image),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                  // More prominent notification badge
                  Builder(
                    builder: (context) {
                      final totalCount = (unreadMessageCount ?? 0) + 
                                       (unreadActivityCount ?? 0) + 
                                       (unreadJoinRequestCount ?? 0);
                      
                      // Debug: Print counts for this bin
                      if (totalCount > 0) {
                        debugPrint('Bin ${bin['name']} (${bin['id']}): '
                            'Messages: ${unreadMessageCount ?? 0}, '
                            'Activities: ${unreadActivityCount ?? 0}, '
                            'JoinRequests: ${unreadJoinRequestCount ?? 0}, '
                            'Total: $totalCount');
                      }
                      
                      if (totalCount > 0) {
                        return Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                totalCount > 99 ? '99+' : '$totalCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Bin info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bin['name'] as String? ?? 'Bin',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        // Show notification count badge next to name if > 0
                        if ((unreadMessageCount ?? 0) + (unreadActivityCount ?? 0) + (unreadJoinRequestCount ?? 0) > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(unreadMessageCount ?? 0) + (unreadActivityCount ?? 0) + (unreadJoinRequestCount ?? 0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bin['location'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Health status and temp (or Request under review)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasPendingRequest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending,
                            size: 12,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Request under review',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Bin Status Badge
                    if (binStatus != 'active')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(binStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(binStatus),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (binStatus != 'active') const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getHealthColor(healthStatus),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getHealthTextColor(healthStatus),
                        ),
                      ),
                    ),
                    if (temperature != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$temperature°C',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
