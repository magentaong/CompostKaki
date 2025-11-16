import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BinCard extends StatelessWidget {
  final Map<String, dynamic> bin;
  final VoidCallback onTap;

  const BinCard({
    super.key,
    required this.bin,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final healthStatus = bin['health_status'] as String? ?? 'Healthy';
    final temperature = bin['latest_temperature'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Bin image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: bin['image'] != null
                    ? CachedNetworkImage(
                        imageUrl: bin['image'] as String,
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
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.eco, color: AppTheme.primaryGreen),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Bin info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bin['name'] as String? ?? 'Bin',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                      ),
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
              
              // Health status and temp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

