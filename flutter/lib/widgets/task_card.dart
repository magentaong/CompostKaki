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
      case 'high priority':
        return AppTheme.urgencyHigh;
      case 'normal':
        return AppTheme.urgencyNormal;
      case 'low priority':
      default:
        return AppTheme.urgencyLow;
    }
  }

  Color _getUrgencyTextColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high priority':
        return AppTheme.urgencyHighText;
      case 'normal':
        return AppTheme.urgencyNormalText;
      case 'low priority':
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
                    Text(
                      'Bin: ${bin['name']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted by: $firstName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
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

