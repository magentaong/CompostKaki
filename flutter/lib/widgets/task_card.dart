import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> bins;
  final VoidCallback onTap;
  final bool isCompleted; // Highlight completed tasks
  final bool isPendingCheck; // If true, white background; if false, darkened green
  final bool isDeleting; // Play delete animation before removal

  const TaskCard({
    super.key,
    required this.task,
    required this.bins,
    required this.onTap,
    this.isCompleted = false,
    this.isPendingCheck = false,
    this.isDeleting = false,
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

  ({String text, Color color}) _getTimeLeft(String? dueDateRaw) {
    if (dueDateRaw == null || dueDateRaw.trim().isEmpty) {
      return (text: '', color: AppTheme.textGray);
    }

    try {
      final due = DateTime.parse(dueDateRaw).toLocal();
      final now = DateTime.now();
      final diff = due.difference(now);
      final isOverdue = diff.isNegative;
      final absDiff = isOverdue ? now.difference(due) : diff;

      final days = absDiff.inDays;
      final hours = absDiff.inHours % 24;
      final minutes = absDiff.inMinutes % 60;

      String spanText;
      if (days > 0) {
        spanText = '${days}d ${hours}h';
      } else if (absDiff.inHours > 0) {
        spanText = '${absDiff.inHours}h ${minutes}m';
      } else {
        spanText = '${absDiff.inMinutes.clamp(0, 59)}m';
      }

      if (isOverdue) {
        return (text: 'Overdue by $spanText', color: Colors.red.shade700);
      }

      if (absDiff.inHours <= 24) {
        return (text: '$spanText left', color: Colors.orange.shade700);
      }

      return (text: '$spanText left', color: AppTheme.primaryGreen);
    } catch (_) {
      return (text: '', color: AppTheme.textGray);
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
    final isTimeSensitive = task['is_time_sensitive'] == true;
    final dueDateRaw = task['due_date'] as String?;
    final timeLeft = _getTimeLeft(dueDateRaw);
    final description = task['description'] as String? ?? '';
    final profile = task['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final status = task['status'] as String? ?? 'open';
    final assignedToProfile = task['assigned_to_profile'] as Map<String, dynamic>?;
    final acceptedByProfile = task['accepted_by_profile'] as Map<String, dynamic>?;
    final assignedFirstName = assignedToProfile?['first_name'] as String?;
    final assignedLastName = assignedToProfile?['last_name'] as String?;
    final assignedToName = assignedFirstName != null && assignedLastName != null
        ? '$assignedFirstName $assignedLastName'.trim()
        : assignedFirstName ?? 'Anyone';
    final acceptedByFirstName = acceptedByProfile?['first_name'] as String?;
    final acceptedByLastName = acceptedByProfile?['last_name'] as String?;
    final acceptedByName = acceptedByFirstName != null && acceptedByLastName != null
        ? '$acceptedByFirstName $acceptedByLastName'.trim()
        : acceptedByFirstName ?? 'Unknown';

    // Determine card color based on completion status
    Color? cardColor;
    BorderSide? borderSide;
    if (isCompleted) {
      if (isPendingCheck) {
        // Pending check: white background with green border
        cardColor = Colors.white;
        borderSide = const BorderSide(color: AppTheme.primaryGreen, width: 2);
      } else {
        // Checked/reverted: darkened green background
        cardColor = AppTheme.primaryGreen.withOpacity(0.3); // Darker green
        borderSide = const BorderSide(color: AppTheme.primaryGreen, width: 2);
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      opacity: isDeleting ? 0.0 : 1.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: isDeleting ? 0.82 : 1.0,
        child: IgnorePointer(
          ignoring: isDeleting,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: borderSide ?? BorderSide.none,
            ),
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
                    const SizedBox(height: 4),
                    Text(
                      'Assigned to: $assignedToName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                    if (isTimeSensitive && timeLeft.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: timeLeft.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLeft.text,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: timeLeft.color,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    if (status == 'completed' && acceptedByName != 'Unknown') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'Completed by: ',
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
          ),
        ),
      ),
    );
  }
}
