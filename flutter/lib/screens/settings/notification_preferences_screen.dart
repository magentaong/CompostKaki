import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await _notificationService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs ?? _getDefaultPreferences();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'push_messages': true,
      'push_join_requests': true,
      'push_activities': true,
      'push_help_requests': true,
      'push_bin_health': true,
      'badge_messages': true,
      'badge_join_requests': true,
      'badge_activities': true,
      'badge_help_requests': true,
      'badge_bin_health': true,
    };
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _notificationService.updatePreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updatePreference(String key, bool value) {
    setState(() {
      _preferences![key] = value;
    });
    // Auto-save on change
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(child: Text('Failed to load preferences'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Push Notifications Section
                      _buildSectionHeader('Push Notifications'),
                      const SizedBox(height: 8),
                      _buildPreferenceTile(
                        title: 'New Messages',
                        subtitle: 'Receive push notifications for new messages',
                        key: 'push_messages',
                        value: _preferences!['push_messages'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Join Requests',
                        subtitle: 'Receive push notifications for join requests (Admin only)',
                        key: 'push_join_requests',
                        value: _preferences!['push_join_requests'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'New Activities',
                        subtitle: 'Receive push notifications when someone logs an activity',
                        key: 'push_activities',
                        value: _preferences!['push_activities'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Help Requests',
                        subtitle: 'Receive push notifications for new help requests',
                        key: 'push_help_requests',
                        value: _preferences!['push_help_requests'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Bin Health Alerts',
                        subtitle: 'Receive push notifications when bin health deteriorates',
                        key: 'push_bin_health',
                        value: _preferences!['push_bin_health'] ?? true,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // In-App Badges Section
                      _buildSectionHeader('In-App Badges'),
                      const SizedBox(height: 8),
                      _buildPreferenceTile(
                        title: 'Message Badges',
                        subtitle: 'Show badge count for unread messages',
                        key: 'badge_messages',
                        value: _preferences!['badge_messages'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Join Request Badges',
                        subtitle: 'Show badge count for pending join requests (Admin only)',
                        key: 'badge_join_requests',
                        value: _preferences!['badge_join_requests'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Activity Badges',
                        subtitle: 'Show badge count for new activities',
                        key: 'badge_activities',
                        value: _preferences!['badge_activities'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Help Request Badges',
                        subtitle: 'Show badge count for new help requests',
                        key: 'badge_help_requests',
                        value: _preferences!['badge_help_requests'] ?? true,
                      ),
                      _buildPreferenceTile(
                        title: 'Bin Health Badges',
                        subtitle: 'Show badge count for bin health alerts',
                        key: 'badge_bin_health',
                        value: _preferences!['badge_bin_health'] ?? true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save Button (backup, though auto-save is enabled)
                      if (_isSaving)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savePreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Save Preferences'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required String key,
    required bool value,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
      ),
      value: value,
      onChanged: (newValue) => _updatePreference(key, newValue),
      activeColor: AppTheme.primaryGreen,
    );
  }
}

