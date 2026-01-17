import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/xp_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _xpStats;
  List<Map<String, dynamic>> _badges = [];
  Map<String, int>? _badgeProgressStats;
  bool _isLoadingStats = true;
  final XPService _xpService = XPService();
  String? _lastUserId; // Track user ID to detect changes
  String _appVersion = '1.1.1';
  String _buildNumber = '6';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadXPStats();
    _loadBadges();
    _loadBadgeProgress();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      // If package_info fails, keep default values
    }
  }


  Future<void> _loadProfile() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profile =
              response != null ? Map<String, dynamic>.from(response) : null;
        });
      }
    } catch (e) {
      // Silently fail - we'll fall back to userMetadata
    }
  }

  Future<void> _loadXPStats() async {
    try {
      final stats = await _xpService.getUserStats();
      if (mounted) {
        setState(() {
          _xpStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _xpService.getUserBadges();
      if (mounted) {
        setState(() {
          _badges = badges;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadBadgeProgress() async {
    try {
      final progressStats = await _xpService.getBadgeProgressStats();
      if (mounted) {
        setState(() {
          _badgeProgressStats = progressStats;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final authService = context.read<AuthService>();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during deletion
      builder: (dialogContext) => _DeleteAccountDialog(
        onDelete: () async {
          try {
            await authService.deleteAccount();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            if (context.mounted) {
              context.go('/login');
            }
          } catch (e) {
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete account: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            // Re-throw to let the dialog handle the error state
            rethrow;
          }
        },
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentEmail = authService.currentUser?.email ?? '';

    // Navigate to reset password screen with current user's email as query parameter
    context.push('/reset-password?email=${Uri.encodeComponent(currentEmail)}');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final email = user?.email ?? '';
    
    // Reload profile if user ID changed or if profile is null but user exists
    if (user != null && (user.id != _lastUserId || (_profile == null && user.id == _lastUserId))) {
      _lastUserId = user.id;
      // Reload profile asynchronously
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProfile();
        }
      });
    }

    // Get firstName and lastName from profiles table (source of truth), fallback to userMetadata
    // Also check userMetadata first since it updates immediately after AuthService.updateProfile
    final firstName = user?.userMetadata?['first_name'] as String? ??
        _profile?['first_name'] as String? ??
        '';
    final lastName = user?.userMetadata?['last_name'] as String? ??
        _profile?['last_name'] as String? ??
        '';

    // Build avatar initials safely
    String getAvatarInitials() {
      String firstInitial = '';
      String lastInitial = '';

      if (firstName.isNotEmpty) {
        firstInitial = firstName[0];
      } else if (email.isNotEmpty) {
        firstInitial = email[0];
      } else {
        firstInitial = 'U'; // Fallback to 'U' for User
      }

      if (lastName.isNotEmpty) {
        lastInitial = lastName[0];
      }

      return '$firstInitial$lastInitial'.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      getAvatarInitials(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$firstName $lastName'.trim().isEmpty
                        ? email
                        : '$firstName $lastName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // XP & Level Display
          if (_xpStats != null) _XPLevelCard(stats: _xpStats!),
          const SizedBox(height: 16),

          // Stats Overview
          if (_xpStats != null) _StatsOverviewCard(stats: _xpStats!),
          const SizedBox(height: 16),

          // Badges Collection
          _BadgesCard(
            badges: _badges,
            progressStats: _badgeProgressStats,
          ),
          const SizedBox(height: 16),

          // Settings
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/profile/edit');
                    // Reload profile when returning from edit screen
                    if (mounted) {
                      _loadProfile();
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_reset,
                      color: AppTheme.primaryGreen),
                  title: const Text('Reset Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showResetPasswordDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content:
                            const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await authService.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Version
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textGray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Version $_appVersion (Build $_buildNumber)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final String currentEmail;
  final Future<void> Function(String) onReset;

  const _ResetPasswordDialog({
    required this.currentEmail,
    required this.onReset,
  });

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.currentEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onReset(_emailController.text);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset, color: AppTheme.primaryGreen),
          SizedBox(width: 8),
          Text('Reset Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReset,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final Future<void> Function() onDelete;

  const _DeleteAccountDialog({
    required this.onDelete,
  });

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _isLoading = false;

  Future<void> _handleDelete() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onDelete();
      // Dialog will be closed by the parent after successful deletion
    } catch (e) {
      // Error handling is done in the parent
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Deleting your account...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Are you sure you want to delete your account?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'This action cannot be undone. All your data will be permanently deleted, including:',
            style: TextStyle(color: AppTheme.textGray),
          ),
          const SizedBox(height: 8),
          const Text('• Your profile', style: TextStyle(color: AppTheme.textGray)),
          const Text('• All bins you own',
              style: TextStyle(color: AppTheme.textGray)),
          const Text('• Your messages (will be anonymized)',
              style: TextStyle(color: AppTheme.textGray)),
          const Text('• All your tasks', style: TextStyle(color: AppTheme.textGray)),
          const SizedBox(height: 12),
          const Text(
            'If you own bins, they will be deleted along with all their data.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete Account'),
        ),
      ],
    );
  }
}

// XP & Level Display Card
class _XPLevelCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _XPLevelCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalXP = stats['totalXP'] as int;
    final currentLevel = stats['currentLevel'] as int;
    final xpProgress = stats['xpProgress'] as int;
    final xpNeeded = stats['xpNeeded'] as int;
    final progress = xpNeeded > 0 ? (xpProgress / xpNeeded).clamp(0.0, 1.0) : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalXP XP',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress to Next Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      '$xpProgress / $xpNeeded XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppTheme.backgroundGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Stats Overview Card
class _StatsOverviewCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsOverviewCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final streakDays = stats['streakDays'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '$streakDays days',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    icon: Icons.star,
                    label: 'Level',
                    value: '${stats['currentLevel']}',
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatItem(
                    icon: Icons.workspace_premium,
                    label: 'Total XP',
                    value: '${stats['totalXP']}',
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

// Badges Collection Card
class _BadgesCard extends StatefulWidget {
  final List<Map<String, dynamic>> badges;
  final Map<String, int>? progressStats;

  const _BadgesCard({
    required this.badges,
    this.progressStats,
  });

  @override
  State<_BadgesCard> createState() => _BadgesCardState();
}

class _BadgesCardState extends State<_BadgesCard> {
  bool _showAll = false;

  // Fallback emojis for badges (used if images not found)
  String _getFallbackEmoji(String badgeId) {
    const fallbackEmojis = {
      'first_log': '🌱',
      'log_10': '📝',
      'log_50': '🔥',
      'log_100': '📊',
      'complete_1': '✅',
      'complete_5': '🤝',
      'complete_10': '⭐',
      'complete_25': '🏅',
      'streak_3': '🔥',
      'streak_7': '💪',
      'streak_30': '🌟',
      'streak_100': '👑',
    };
    return fallbackEmojis[badgeId] ?? '🏆';
  }

  // Calculate progress for a badge
  Map<String, dynamic> _getBadgeProgress(String badgeId) {
    if (widget.progressStats == null) {
      return {'current': 0, 'target': 1, 'progress': 0.0};
    }

    final stats = widget.progressStats!;
    final totalLogs = stats['totalLogs'] ?? 0;
    final totalTasks = stats['totalTasks'] ?? 0;
    final streakDays = stats['streakDays'] ?? 0;

    switch (badgeId) {
      case 'first_log':
        return {
          'current': totalLogs,
          'target': 1,
          'progress': (totalLogs / 1).clamp(0.0, 1.0),
        };
      case 'log_10':
        return {
          'current': totalLogs,
          'target': 10,
          'progress': (totalLogs / 10).clamp(0.0, 1.0),
        };
      case 'log_50':
        return {
          'current': totalLogs,
          'target': 50,
          'progress': (totalLogs / 50).clamp(0.0, 1.0),
        };
      case 'log_100':
        return {
          'current': totalLogs,
          'target': 100,
          'progress': (totalLogs / 100).clamp(0.0, 1.0),
        };
      case 'complete_1':
        return {
          'current': totalTasks,
          'target': 1,
          'progress': (totalTasks / 1).clamp(0.0, 1.0),
        };
      case 'complete_5':
        return {
          'current': totalTasks,
          'target': 5,
          'progress': (totalTasks / 5).clamp(0.0, 1.0),
        };
      case 'complete_10':
        return {
          'current': totalTasks,
          'target': 10,
          'progress': (totalTasks / 10).clamp(0.0, 1.0),
        };
      case 'complete_25':
        return {
          'current': totalTasks,
          'target': 25,
          'progress': (totalTasks / 25).clamp(0.0, 1.0),
        };
      case 'streak_3':
        return {
          'current': streakDays,
          'target': 3,
          'progress': (streakDays / 3).clamp(0.0, 1.0),
        };
      case 'streak_7':
        return {
          'current': streakDays,
          'target': 7,
          'progress': (streakDays / 7).clamp(0.0, 1.0),
        };
      case 'streak_30':
        return {
          'current': streakDays,
          'target': 30,
          'progress': (streakDays / 30).clamp(0.0, 1.0),
        };
      case 'streak_100':
        return {
          'current': streakDays,
          'target': 100,
          'progress': (streakDays / 100).clamp(0.0, 1.0),
        };
      default:
        return {'current': 0, 'target': 1, 'progress': 0.0};
    }
  }

  // Badge definitions
  static const Map<String, Map<String, dynamic>> badgeDefinitions = {
    'first_log': {
      'name': 'First Steps',
      'imagePath': 'assets/images/badges/badge_first_log.png',
      'description': 'Logged your first activity',
    },
    'log_10': {
      'name': 'Dedicated Logger',
      'imagePath': 'assets/images/badges/badge_first_10.png', // Using existing file
      'description': 'Logged 10 activities',
    },
    'log_50': {
      'name': 'On Fire',
      'imagePath': 'assets/images/badges/badge_first_50.png', // Using existing file
      'description': 'Logged 50 activities',
    },
    'log_100': {
      'name': 'Data Master',
      'imagePath': 'assets/images/badges/badge_log_100.png',
      'description': 'Logged 100 activities',
    },
    'complete_1': {
      'name': 'Helper',
      'imagePath': 'assets/images/badges/badge_complete_1.png',
      'description': 'Completed 1 task',
    },
    'complete_5': {
      'name': 'Team Player',
      'imagePath': 'assets/images/badges/badge_complete_5.png',
      'description': 'Completed 5 tasks',
    },
    'complete_10': {
      'name': 'Task Master',
      'imagePath': 'assets/images/badges/badge_complete_10.png',
      'description': 'Completed 10 tasks',
    },
    'complete_25': {
      'name': 'Community Hero',
      'imagePath': 'assets/images/badges/badge_complete_25.png',
      'description': 'Completed 25 tasks',
    },
    'streak_3': {
      'name': '3-Day Streak',
      'imagePath': 'assets/images/badges/badge_streak_3.png',
      'description': 'Logged 3 days in a row',
    },
    'streak_7': {
      'name': 'Week Warrior',
      'imagePath': 'assets/images/badges/badge_streak_7.png',
      'description': '7-day streak',
    },
    'streak_30': {
      'name': 'Month Master',
      'imagePath': 'assets/images/badges/badge_streak_30.png',
      'description': '30-day streak',
    },
    'streak_100': {
      'name': 'Consistency King',
      'imagePath': 'assets/images/badges/badge_streak_100.png',
      'description': '100-day streak',
    },
  };

  @override
  Widget build(BuildContext context) {
    final earnedBadgeIds = widget.badges.map((b) => b['badge_id'] as String).toSet();
    
    // Get earned badges with their info
    final earnedBadges = badgeDefinitions.entries
        .where((entry) => earnedBadgeIds.contains(entry.key))
        .map((entry) => {
              'id': entry.key,
              'name': entry.value['name'],
              'imagePath': entry.value['imagePath'],
              'description': entry.value['description'],
            })
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (earnedBadges.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAll = !_showAll;
                      });
                    },
                    child: Text(
                      _showAll ? 'Show Earned' : 'View All',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_showAll)
              // Show only earned badges
              earnedBadges.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No badges earned yet. Keep logging activities and completing tasks!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: earnedBadges.map((badge) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Badge image
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    badge['imagePath'] as String,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        _getFallbackEmoji(badge['id'] as String),
                                        style: const TextStyle(fontSize: 24),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Badge name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      badge['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      badge['description'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
            else
              // Show all badges
              Column(
                children: badgeDefinitions.entries.map((entry) {
                  final badgeId = entry.key;
                  final badgeInfo = entry.value;
                  final isEarned = earnedBadgeIds.contains(badgeId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Badge image
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isEarned
                                ? AppTheme.primaryGreen.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEarned
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade300,
                              width: isEarned ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: isEarned ? 1.0 : 0.3,
                              child: Image.asset(
                                badgeInfo['imagePath'] as String,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    _getFallbackEmoji(badgeId),
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: isEarned
                                          ? null
                                          : Colors.grey.withOpacity(0.5),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Badge name and description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    badgeInfo['name'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isEarned ? null : AppTheme.textGray,
                                    ),
                                  ),
                                  if (!isEarned) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.lock,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badgeInfo['description'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGray,
                                ),
                              ),
                              if (!isEarned && widget.progressStats != null) ...[
                                const SizedBox(height: 8),
                                _buildProgressBar(badgeId),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Text(
              '${earnedBadgeIds.length} / ${badgeDefinitions.length} badges earned',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String badgeId) {
    final progress = _getBadgeProgress(badgeId);
    final current = progress['current'] as int;
    final target = progress['target'] as int;
    final progressValue = progress['progress'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current / $target',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              '${(progressValue * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
