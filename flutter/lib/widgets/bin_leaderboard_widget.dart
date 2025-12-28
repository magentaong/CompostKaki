import 'package:flutter/material.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';

class BinLeaderboardWidget extends StatefulWidget {
  final String binId;
  final VoidCallback? onRefresh;

  const BinLeaderboardWidget({
    super.key,
    required this.binId,
    this.onRefresh,
  });

  @override
  State<BinLeaderboardWidget> createState() => _BinLeaderboardWidgetState();
}

class _BinLeaderboardWidgetState extends State<BinLeaderboardWidget> {
  final XPService _xpService = XPService();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _isExpanded = false; // Controls if list is visible at all
  bool _showAll = false; // Controls if showing all or just top 5

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didUpdateWidget(BinLeaderboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.binId != widget.binId || oldWidget.key != widget.key) {
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      debugPrint('Loading leaderboard for bin: ${widget.binId}');
      final leaderboard = await _xpService.getBinLeaderboard(widget.binId);
      debugPrint('Leaderboard loaded: ${leaderboard.length} entries');
      if (mounted) {
        setState(() {
          _leaderboard = leaderboard;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading leaderboard: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  String _getUserInitials(Map<String, dynamic>? profile) {
    if (profile == null) return '?';
    final firstName = profile['first_name'] as String? ?? '';
    final lastName = profile['last_name'] as String? ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return '?';
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  String _getUserName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Unknown';
    final firstName = profile['first_name'] as String? ?? '';
    final lastName = profile['last_name'] as String? ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return 'Unknown';
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🏆 Bin Leaderboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadLeaderboard,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'No activity yet. Start logging to see the leaderboard!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // When collapsed, show nothing. When expanded, show top 5 or all based on _showAll
    final displayList = _showAll ? _leaderboard : _leaderboard.take(5).toList();
    final hasMore = _leaderboard.length > 5;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                // When collapsing, also reset showAll
                if (!_isExpanded) {
                  _showAll = false;
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        '🏆',
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Bin Leaderboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = displayList[index];
                final profile = entry['profiles'] as Map<String, dynamic>?;
                final rank = index + 1;
                final totalXP = (entry['total_xp'] as int?) ?? 0;
                final logsCount = (entry['logs_count'] as int?) ?? 0;
                final tasksCompleted = (entry['tasks_completed'] as int?) ?? 0;
                final level = XPService.calculateLevel(totalXP);

                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: index == 0 ? 0 : 12, // Less padding for first item
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 40,
                        child: Text(
                          _getRankEmoji(rank),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryGreen,
                        child: Text(
                          _getUserInitials(profile),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getUserName(profile),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Level $level',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$totalXP XP',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$logsCount logs',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textGray,
                                  ),
                                ),
                                if (tasksCompleted > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textGray,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$tasksCompleted tasks',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textGray,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (!_showAll && hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Show ${_leaderboard.length - 5} More',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            if (_showAll && hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Show Less',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_less,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
