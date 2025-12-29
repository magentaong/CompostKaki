import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing notifications (badges and push notifications)
class NotificationService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Badge counts
  int _unreadMessages = 0;
  int _unreadJoinRequests = 0;
  int _unreadActivities = 0;
  int _unreadHelpRequests = 0;
  int _unreadBinHealth = 0;
  int _unreadTaskCompleted = 0;

  // Per-bin badge counts cache
  final Map<String, int> _binMessageCounts = {};
  final Map<String, int> _binActivityCounts = {};
  final Map<String, int> _binJoinRequestCounts = {};

  // Realtime subscriptions
  RealtimeChannel? _notificationsChannel;

  // Track FCM initialization attempts to avoid infinite retries
  int _fcmInitAttempts = 0;
  static const int _maxFcmInitAttempts = 3;

  // Getters
  int get unreadMessages => _unreadMessages;
  int get unreadJoinRequests => _unreadJoinRequests;
  int get unreadActivities => _unreadActivities;
  int get unreadHelpRequests => _unreadHelpRequests;
  int get unreadBinHealth => _unreadBinHealth;
  int get unreadTaskCompleted => _unreadTaskCompleted;

  int get totalUnread => _unreadMessages +
      _unreadJoinRequests +
      _unreadActivities +
      _unreadHelpRequests +
      _unreadBinHealth +
      _unreadTaskCompleted;

  String? get currentUserId => _supabaseService.currentUser?.id;

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_supabaseService.isAuthenticated) {
      await _loadBadgeCounts();
      await _subscribeToNotifications();
    }
  }

  /// Initialize FCM and request permissions
  Future<void> initializeFCM() async {
    _fcmInitAttempts = 0; // Reset attempts counter
    
    try {
      // Request permission (iOS)
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          print('User declined or has not accepted notification permissions');
          return;
        }

        // On iOS, we need to wait for APNS token before getting FCM token
        // Try to get APNS token first
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            print('APNS token not available yet. This is normal on first launch.');
            print('Make sure Push Notifications capability is enabled in Xcode.');
            print('Will retry FCM token after a delay...');
            // Retry getting FCM token after a delay (APNS token might be set by then)
            Future.delayed(const Duration(seconds: 3), () {
              _getAndSaveFCMToken();
            });
            return;
          }
          print('✅ APNS token obtained: ${apnsToken.substring(0, 20)}...');
        } catch (e) {
          print('⚠️ APNS token not ready yet: $e');
          print('This is normal if Push Notifications capability is not enabled in Xcode.');
          print('See APNS_SETUP_GUIDE.md for setup instructions.');
          // Retry after delay - APNS token might become available
          Future.delayed(const Duration(seconds: 3), () {
            _getAndSaveFCMToken();
          });
          return;
        }
      }

      // Get FCM token (for Android and iOS after APNS token is set)
      await _getAndSaveFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        if (currentUserId != null) {
          _saveFCMToken(newToken);
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } catch (e) {
      print('Error initializing FCM: $e');
      // Don't throw - allow app to continue without push notifications
      // The error is expected on iOS if APNS token isn't ready yet
    }
  }

  /// Get FCM token and save it (with retry logic for iOS)
  Future<void> _getAndSaveFCMToken() async {
    // Stop retrying after max attempts
    if (_fcmInitAttempts >= _maxFcmInitAttempts) {
      print('⚠️ Max FCM initialization attempts reached. Push notifications may not work.');
      print('Please ensure Push Notifications capability is enabled in Xcode.');
      return;
    }

    _fcmInitAttempts++;
    
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && currentUserId != null) {
        await _saveFCMToken(token);
        print('✅ FCM token obtained and saved: ${token.substring(0, 20)}...');
        _fcmInitAttempts = 0; // Reset on success
      } else if (token == null) {
        if (Platform.isIOS) {
          print('FCM token is null on iOS (attempt $_fcmInitAttempts/$_maxFcmInitAttempts)');
          if (_fcmInitAttempts < _maxFcmInitAttempts) {
            // Retry after a longer delay
            Future.delayed(const Duration(seconds: 5), () {
              _getAndSaveFCMToken();
            });
          }
        } else {
          print('FCM token is null');
        }
      }
    } catch (e) {
      print('Error getting FCM token (attempt $_fcmInitAttempts/$_maxFcmInitAttempts): $e');
      // On iOS, if APNS token error, retry after delay (but limit attempts)
      if (Platform.isIOS && e.toString().contains('apns-token')) {
        if (_fcmInitAttempts < _maxFcmInitAttempts) {
          print('Will retry FCM token in 5 seconds...');
          Future.delayed(const Duration(seconds: 5), () {
            _getAndSaveFCMToken();
          });
        } else {
          print('⚠️ APNS token still not available after $_maxFcmInitAttempts attempts.');
          print('Please check:');
          print('1. Push Notifications capability is enabled in Xcode');
          print('2. Background Modes > Remote notifications is enabled');
          print('3. APNs key is uploaded to Firebase Console');
          print('See APNS_SETUP_GUIDE.md for detailed instructions.');
        }
      }
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveFCMToken(String token) async {
    if (currentUserId == null) return;

    try {
      final deviceType = Platform.isIOS ? 'ios' : 'android';

      // Check if token already exists
      final existing = await _supabaseService.client
          .from('user_fcm_tokens')
          .select('id')
          .eq('fcm_token', token)
          .maybeSingle();

      if (existing == null) {
        // Insert new token
        await _supabaseService.client.from('user_fcm_tokens').insert({
          'user_id': currentUserId,
          'fcm_token': token,
          'device_type': deviceType,
        });
      } else {
        // Update existing token
        await _supabaseService.client
            .from('user_fcm_tokens')
            .update({
              'user_id': currentUserId,
              'device_type': deviceType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('fcm_token', token);
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token (on logout)
  Future<void> removeFCMToken(String? token) async {
    if (token == null) return;

    try {
      await _supabaseService.client
          .from('user_fcm_tokens')
          .delete()
          .eq('fcm_token', token);
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  /// Load badge counts from database
  Future<void> _loadBadgeCounts() async {
    if (currentUserId == null) return;

    try {
      final response = await _supabaseService.client
          .from('user_notifications')
          .select('type, bin_id, is_read')
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      final notifications = List<Map<String, dynamic>>.from(response);

      // Reset counts
      _unreadMessages = 0;
      _unreadJoinRequests = 0;
      _unreadActivities = 0;
      _unreadHelpRequests = 0;
      _unreadBinHealth = 0;
      _unreadTaskCompleted = 0;
      _binMessageCounts.clear();
      _binActivityCounts.clear();
      _binJoinRequestCounts.clear();

      // Count by type and bin
      for (final notification in notifications) {
        final type = notification['type'] as String?;
        final binId = notification['bin_id'] as String?;

        switch (type) {
          case 'message':
            _unreadMessages++;
            if (binId != null) {
              _binMessageCounts[binId] = (_binMessageCounts[binId] ?? 0) + 1;
            } else {
              print('Warning: Message notification without bin_id: ${notification['id']}');
            }
            break;
          case 'join_request':
            _unreadJoinRequests++;
            if (binId != null) {
              _binJoinRequestCounts[binId] = (_binJoinRequestCounts[binId] ?? 0) + 1;
            } else {
              print('Warning: Join request notification without bin_id: ${notification['id']}');
            }
            break;
          case 'activity':
            _unreadActivities++;
            if (binId != null) {
              _binActivityCounts[binId] = (_binActivityCounts[binId] ?? 0) + 1;
            } else {
              print('Warning: Activity notification without bin_id: ${notification['id']}');
            }
            break;
          case 'help_request':
            _unreadHelpRequests++;
            break;
          case 'bin_health':
            _unreadBinHealth++;
            break;
          case 'task_completed':
            _unreadTaskCompleted++;
            break;
        }
      }

      // Debug: Print loaded counts
      print('Loaded badge counts:');
      print('  Total messages: $_unreadMessages');
      print('  Total join requests: $_unreadJoinRequests');
      print('  Total activities: $_unreadActivities');
      print('  Total task completed: $_unreadTaskCompleted');
      print('  Per-bin message counts: $_binMessageCounts');
      print('  Per-bin activity counts: $_binActivityCounts');
      print('  Per-bin join request counts: $_binJoinRequestCounts');

      notifyListeners();
    } catch (e) {
      print('Error loading badge counts: $e');
    }
  }

  /// Get unread message count for a specific bin (with caching)
  Future<int> getUnreadMessageCountForBin(String binId) async {
    if (currentUserId == null) return 0;

    // Return cached value if available
    if (_binMessageCounts.containsKey(binId)) {
      return _binMessageCounts[binId]!;
    }

    try {
      final response = await _supabaseService.client
          .from('user_notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('type', 'message')
          .eq('bin_id', binId)
          .eq('is_read', false);

      final count = (response as List).length;
      _binMessageCounts[binId] = count;
      return count;
    } catch (e) {
      print('Error getting unread count for bin: $e');
      return 0;
    }
  }

  /// Get unread activity count for a specific bin (with caching)
  Future<int> getUnreadActivityCountForBin(String binId) async {
    if (currentUserId == null) return 0;

    // Return cached value if available
    if (_binActivityCounts.containsKey(binId)) {
      return _binActivityCounts[binId]!;
    }

    try {
      final response = await _supabaseService.client
          .from('user_notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('type', 'activity')
          .eq('bin_id', binId)
          .eq('is_read', false);

      final count = (response as List).length;
      _binActivityCounts[binId] = count;
      return count;
    } catch (e) {
      print('Error getting unread activity count for bin: $e');
      return 0;
    }
  }

  /// Get unread message count for a specific bin (synchronous, uses cache)
  int getUnreadMessageCountForBinSync(String binId) {
    return _binMessageCounts[binId] ?? 0;
  }

  /// Get unread activity count for a specific bin (synchronous, uses cache)
  int getUnreadActivityCountForBinSync(String binId) {
    return _binActivityCounts[binId] ?? 0;
  }

  /// Get unread join request count for a specific bin (synchronous, uses cache)
  int getUnreadJoinRequestCountForBinSync(String binId) {
    return _binJoinRequestCounts[binId] ?? 0;
  }

  /// Get unread join request count for a specific bin (with caching)
  /// Only returns count if user is admin of the bin
  Future<int> getUnreadJoinRequestCountForBin(String binId) async {
    if (currentUserId == null) return 0;

    // Return cached value if available
    if (_binJoinRequestCounts.containsKey(binId)) {
      return _binJoinRequestCounts[binId]!;
    }

    try {
      // First check if user is admin of this bin
      final bin = await _supabaseService.client
          .from('bins')
          .select('user_id')
          .eq('id', binId)
          .maybeSingle();

      if (bin == null || bin['user_id'] != currentUserId) {
        // User is not admin, return 0
        _binJoinRequestCounts[binId] = 0;
        return 0;
      }

      // User is admin, get join request count
      final response = await _supabaseService.client
          .from('user_notifications')
          .select('id')
          .eq('user_id', currentUserId!)
          .eq('type', 'join_request')
          .eq('bin_id', binId)
          .eq('is_read', false);

      final count = (response as List).length;
      _binJoinRequestCounts[binId] = count;
      return count;
    } catch (e) {
      print('Error getting unread join request count for bin: $e');
      return 0;
    }
  }

  /// Subscribe to Supabase Realtime for notification updates
  Future<void> _subscribeToNotifications() async {
    if (currentUserId == null) return;

    try {
      // Unsubscribe from previous channel if exists
      await _notificationsChannel?.unsubscribe();

      // Create new channel
      _notificationsChannel = _supabaseService.client
          .channel('user_notifications_${currentUserId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'user_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: currentUserId!,
            ),
            callback: (payload) {
              final notification = payload.newRecord;
              final type = notification['type'] as String?;
              final binId = notification['bin_id'] as String?;
              
              // Increment appropriate badge count
              switch (type) {
                case 'message':
                  _unreadMessages++;
                  if (binId != null) {
                    _binMessageCounts[binId] = (_binMessageCounts[binId] ?? 0) + 1;
                  }
                  break;
                case 'join_request':
                  _unreadJoinRequests++;
                  if (binId != null) {
                    _binJoinRequestCounts[binId] = (_binJoinRequestCounts[binId] ?? 0) + 1;
                  }
                  break;
                case 'activity':
                  _unreadActivities++;
                  if (binId != null) {
                    _binActivityCounts[binId] = (_binActivityCounts[binId] ?? 0) + 1;
                  }
                  break;
                case 'help_request':
                  _unreadHelpRequests++;
                  break;
                case 'bin_health':
                  _unreadBinHealth++;
                  break;
                case 'task_completed':
                  _unreadTaskCompleted++;
                  break;
              }
              
              notifyListeners();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: currentUserId!,
            ),
            callback: (payload) {
              // Reload counts when notification is marked as read
              _loadBadgeCounts();
            },
          )
          .subscribe();

      print('Subscribed to notifications realtime channel');
    } catch (e) {
      print('Error subscribing to notifications: $e');
    }
  }

  /// Mark notifications as read by type and bin_id (optional)
  Future<void> markAsRead({
    required String type,
    String? binId,
  }) async {
    if (currentUserId == null) return;

    try {
      var query = _supabaseService.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', currentUserId!)
          .eq('type', type)
          .eq('is_read', false);

      if (binId != null) {
        query = query.eq('bin_id', binId);
      }

      await query;

      // Clear cached counts for this bin if binId provided
      if (binId != null) {
        if (type == 'message') {
          _binMessageCounts.remove(binId);
        } else if (type == 'activity') {
          _binActivityCounts.remove(binId);
        } else if (type == 'join_request') {
          _binJoinRequestCounts.remove(binId);
        }
      }

      // Reload badge counts
      await _loadBadgeCounts();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  /// Reload badge counts (public method for manual refresh)
  Future<void> reloadBadgeCounts() async {
    await _loadBadgeCounts();
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      await _supabaseService.client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', currentUserId!)
          .eq('is_read', false);

      await _loadBadgeCounts();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    if (currentUserId == null) return null;

    try {
      final response = await _supabaseService.client
          .from('notification_preferences')
          .select('*')
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }

      // Return default preferences if none exist
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
    } catch (e) {
      print('Error getting notification preferences: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (currentUserId == null) return;

    try {
      final existing = await _supabaseService.client
          .from('notification_preferences')
          .select('id')
          .eq('user_id', currentUserId!)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _supabaseService.client
            .from('notification_preferences')
            .update(preferences)
            .eq('user_id', currentUserId!);
      } else {
        // Insert new
        await _supabaseService.client.from('notification_preferences').insert({
          'user_id': currentUserId!,
          ...preferences,
        });
      }
    } catch (e) {
      print('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Handle foreground message (app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    // Reload badge counts
    _loadBadgeCounts();
    // You can show an in-app notification here if needed
  }

  /// Handle background message (app opened from notification)
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message opened: ${message.notification?.title}');
    // Reload badge counts
    _loadBadgeCounts();
    // Navigate to relevant screen based on message data
  }

  /// Cleanup: unsubscribe from realtime
  Future<void> dispose() async {
    await _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  /// Reinitialize when user logs in
  Future<void> onUserLogin() async {
    await _initialize();
    await initializeFCM();
  }

  /// Cleanup when user logs out
  Future<void> onUserLogout() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await removeFCMToken(token);
    }
    await _notificationsChannel?.unsubscribe();
    _notificationsChannel = null;
    
    _unreadMessages = 0;
    _unreadJoinRequests = 0;
    _unreadActivities = 0;
    _unreadHelpRequests = 0;
    _unreadBinHealth = 0;
    _binMessageCounts.clear();
    _binActivityCounts.clear();
    
    notifyListeners();
  }
}

