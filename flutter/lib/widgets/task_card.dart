import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> bins;
  final VoidCallback onTap;
  final bool isCompleted; // Highlight completed tasks
  final bool
      isPendingCheck; // If true, white background; if false, darkened green
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

  ({String title, String details}) _parseTaskDescription(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return (title: 'Task', details: '');
    }

    final lines =
        normalized.split('\n').map((line) => line.trimRight()).toList();

    final firstNonEmptyIndex =
        lines.indexWhere((line) => line.trim().isNotEmpty);
    if (firstNonEmptyIndex == -1) {
      return (title: 'Task', details: '');
    }

    final title = lines[firstNonEmptyIndex].trim();
    var detailLines = lines.sublist(firstNonEmptyIndex + 1).join('\n').trim();

    // Normalize legacy/new task formats so cards don't show duplicate headings.
    final detailParts =
        detailLines.split('\n').map((line) => line.trimRight()).toList();
    if (detailParts.isNotEmpty &&
        detailParts.first.trim().toLowerCase() == 'additional detail') {
      detailParts.removeAt(0);
      detailLines = detailParts.join('\n').trim();
    }

    return (title: title, details: detailLines);
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

  String _initialsFromProfile(Map<String, dynamic>? profile) {
    final first = (profile?['first_name'] as String? ?? '').trim();
    final last = (profile?['last_name'] as String? ?? '').trim();
    final a = first.isNotEmpty ? first[0] : 'U';
    final b = last.isNotEmpty ? last[0] : '';
    return '$a$b'.toUpperCase();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.primaryGreen.withOpacity(0.15);
      case 'accepted':
        return Colors.blue.withOpacity(0.14);
      default:
        return AppTheme.backgroundGray;
    }
  }

  String _initialsFromName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
    final parsed = _parseTaskDescription(description);
    final profile = task['profiles'] as Map<String, dynamic>?;
    final posterAvatarUrl = profile?['avatar_url'] as String?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final status = task['status'] as String? ?? 'open';
    final assignedToProfile =
        task['assigned_to_profile'] as Map<String, dynamic>?;
    final assignedAvatarUrl = assignedToProfile?['avatar_url'] as String?;
    final acceptedByProfile =
        task['accepted_by_profile'] as Map<String, dynamic>?;
    final acceptedAvatarUrl = acceptedByProfile?['avatar_url'] as String?;
    final assignedFirstName = assignedToProfile?['first_name'] as String?;
    final assignedLastName = assignedToProfile?['last_name'] as String?;
    final assignedToName = assignedFirstName != null && assignedLastName != null
        ? '$assignedFirstName $assignedLastName'.trim()
        : assignedFirstName ?? 'Anyone';
    final acceptedByFirstName = acceptedByProfile?['first_name'] as String?;
    final acceptedByLastName = acceptedByProfile?['last_name'] as String?;
    final acceptedByName =
        acceptedByFirstName != null && acceptedByLastName != null
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
            elevation: isCompleted ? 0 : 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: borderSide ?? BorderSide.none,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _getUrgencyColor(urgency),
                      width: 3,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                AppTheme.primaryGreen.withOpacity(0.15),
                            backgroundImage: posterAvatarUrl != null &&
                                    posterAvatarUrl.trim().isNotEmpty
                                ? NetworkImage(posterAvatarUrl)
                                : null,
                            child: (posterAvatarUrl == null ||
                                    posterAvatarUrl.trim().isEmpty)
                                ? Text(
                                    _initialsFromProfile(profile),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  parsed.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Posted by $firstName',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                      if (parsed.details.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          parsed.details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.eco_outlined,
                            label: bin['name'] as String? ?? 'Unknown',
                          ),
                          _MetaChip(
                            icon: Icons.person_outline,
                            label: assignedToName,
                            avatarUrl: assignedAvatarUrl,
                            initials: _initialsFromName(assignedToName),
                          ),
                          _MetaChip(
                            icon: Icons.flag_outlined,
                            label: status.toUpperCase(),
                            backgroundColor: _statusColor(status),
                          ),
                        ],
                      ),
                      if (isTimeSensitive && timeLeft.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: timeLeft.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: timeLeft.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (status == 'accepted' &&
                          acceptedByName != 'Unknown') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor:
                                  AppTheme.primaryGreen.withOpacity(0.12),
                              backgroundImage: acceptedAvatarUrl != null &&
                                      acceptedAvatarUrl.trim().isNotEmpty
                                  ? NetworkImage(acceptedAvatarUrl)
                                  : null,
                              child: (acceptedAvatarUrl == null ||
                                      acceptedAvatarUrl.trim().isEmpty)
                                  ? Text(
                                      acceptedByName.isNotEmpty
                                          ? acceptedByName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Taken by $acceptedByName',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status == 'completed' &&
                          acceptedByName != 'Unknown') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Completed by ',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textGray,
                              ),
                            ),
                            Text(
                              acceptedByName,
                              style: const TextStyle(
                                fontSize: 11,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final String? avatarUrl;
  final String? initials;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.avatarUrl,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
            CircleAvatar(
              radius: 7,
              backgroundImage: NetworkImage(avatarUrl!),
              backgroundColor: Colors.transparent,
            )
          else if (initials != null && initials!.trim().isNotEmpty)
            CircleAvatar(
              radius: 7,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
              child: Text(
                initials!,
                style: const TextStyle(
                  fontSize: 7,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(icon, size: 12, color: AppTheme.textGray),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
