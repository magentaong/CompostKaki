import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> bins;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.bins,
    required this.onTap,
  });

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
        return AppTheme.urgencyHigh;
      case 'normal':
        return AppTheme.urgencyNormal;
      case 'low':
      default:
        return AppTheme.urgencyLow;
    }
  }

  Color _getUrgencyTextColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
        return AppTheme.urgencyHighText;
      case 'normal':
        return AppTheme.urgencyNormalText;
      case 'low':
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final binId = task['bin_id'] as String?;
    final bin = bins.firstWhere(
      (b) => b['id'] == binId,
      orElse: () => {'name': 'Unknown'},
    );
    final urgency = task['urgency'] as String? ?? 'Normal';
    final description = task['description'] as String? ?? '';
    final profile = task['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final status = task['status'] as String? ?? 'open';
    final acceptedByProfile = task['accepted_by_profile'] as Map<String, dynamic>?;
    final acceptedByFirstName = acceptedByProfile?['first_name'] as String?;
    final acceptedByLastName = acceptedByProfile?['last_name'] as String?;
    final acceptedByName = acceptedByFirstName != null && acceptedByLastName != null
        ? '$acceptedByFirstName $acceptedByLastName'.trim()
        : acceptedByFirstName ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Bin: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                        Text(
                          bin['name'] as String? ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted by: $firstName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                    if (status == 'accepted' && acceptedByName != 'Unknown') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Taken by: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGray,
                            ),
                          ),
                          Text(
                            acceptedByName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(urgency),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getUrgencyTextColor(urgency),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
