import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../services/xp_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/xp_floating_animation.dart';
import '../../widgets/notification_badge.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bin_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/compost_loading_animation.dart';
import '../../widgets/kaki_mascot_widget.dart';
import '../bin/add_bin_screen.dart';
import '../bin/join_bin_scanner_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int? initialTab;

  const MainScreen({super.key, this.initialTab});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final BinService _binService = BinService();
  final TaskService _taskService = TaskService();
  final XPService _xpService = XPService();

  List<Map<String, dynamic>> _bins = [];
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _xpStats;
  bool _isLoading = true;
  bool _isLoadingBins = false; // Separate flag for loading bins in background
  String? _error;
  int _userLogCount = 0;
  int _selectedIndex = 0;
  String? _lastTasksRefreshToken;
  final Set<String> _deletingTaskIds = <String>{};

  @override
  void initState() {
    super.initState();

    // Initialize notifications when user is authenticated
    final notificationService = context.read<NotificationService>();
    if (context.read<AuthService>().isAuthenticated) {
      notificationService.onUserLogin();
      // Reload badge counts to ensure we have latest data
      notificationService.reloadBadgeCounts();
    }

    // Set initial tab if provided
    if (widget.initialTab != null) {
      _selectedIndex = widget.initialTab!;
      if (_selectedIndex == 1) {
        // If Tasks tab is selected, load tasks immediately and skip loading bins
        // This makes navigation to Tasks tab much faster
        _isLoading = false; // Don't show loading for bins
        // Load tasks immediately without waiting
        _loadTasks();
        // Clear help request and task completed badges when viewing tasks tab
        notificationService.markAsRead(type: 'help_request');
        notificationService.markAsRead(type: 'task_completed');
        // Load bins in background (non-blocking) for when user switches to Home tab
        _loadDataInBackground();
        return;
      }
    }
    // Only load data if we don't already have bins (to avoid reload on navigation back)
    if (_bins.isEmpty) {
      _loadData();
    } else {
      // We already have data, just mark as not loading
      _isLoading = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for tab query parameter in case widget is reused
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];
    final refreshToken = uri.queryParameters['refresh'];
    final targetTab = tabParam == 'tasks' ? 1 : (tabParam == 'home' ? 0 : null);

    // If navigating explicitly to tasks, always refresh tasks at least once per refresh token.
    // This ensures newly created tasks appear immediately without manual pull-to-refresh.
    if (targetTab == 1 &&
        refreshToken != null &&
        _lastTasksRefreshToken != refreshToken) {
      _lastTasksRefreshToken = refreshToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_selectedIndex != 1) {
            setState(() {
              _selectedIndex = 1;
            });
          }
          _loadTasks();
          final notificationService = context.read<NotificationService>();
          notificationService.markAsRead(type: 'help_request');
          notificationService.markAsRead(type: 'task_completed');
        }
      });
      return;
    }

    if (targetTab != null && _selectedIndex != targetTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = targetTab;
          });
          if (targetTab == 1) {
            _loadTasks();
            // Clear badges when switching to Tasks tab
            final notificationService = context.read<NotificationService>();
            notificationService.markAsRead(type: 'help_request');
            notificationService.markAsRead(type: 'task_completed');
          }
          // If switching to home tab and we have no bins loaded, reload
          if (targetTab == 0 &&
              _bins.isEmpty &&
              !_isLoading &&
              !_isLoadingBins) {
            _loadData();
          }
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Reload badge counts first to ensure we have latest notification data
      final notificationService = context.read<NotificationService>();
      await notificationService.reloadBadgeCounts();

      final bins = await _binService.getUserBins();

      // Get log count
      int logCount = 0;
      for (var bin in bins) {
        final logs = await _binService.getBinLogs(bin['id'] as String);
        logCount += logs.length;
      }

      // Always fetch tasks so community tab is ready
      final tasks = await _taskService.getCommunityTasks();

      // Load XP stats for Kaki mascot
      Map<String, dynamic>? xpStats;
      try {
        xpStats = await _xpService.getUserStats();
      } catch (e) {
        // Silently fail - XP stats are optional
      }

      if (mounted) {
        setState(() {
          _bins = bins;
          _userLogCount = logCount;
          _tasks = tasks;
          _xpStats = xpStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Load data in background without showing loading indicator
  Future<void> _loadDataInBackground() async {
    setState(() {
      _isLoadingBins = true;
    });

    try {
      final bins = await _binService.getUserBins();

      // Get log count
      int logCount = 0;
      for (var bin in bins) {
        final logs = await _binService.getBinLogs(bin['id'] as String);
        logCount += logs.length;
      }

      if (mounted) {
        setState(() {
          _bins = bins;
          _userLogCount = logCount;
          _isLoadingBins = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBins = false;
          // Don't set error for background loading
        });
      }
    }
  }

  // Fast refresh - only reload bins, skip log counts, tasks, and XP stats
  Future<void> _refreshBinsOnly() async {
    try {
      // Just reload bins - this is fast since it doesn't fetch logs
      final bins = await _binService.getUserBins();

      if (mounted) {
        setState(() {
          _bins = bins;
          // Don't update log count or tasks - keep existing values
        });
      }
    } catch (e) {
      // Silently fail - if refresh fails, keep existing data
      debugPrint('Failed to refresh bins: $e');
    }
  }

  Future<void> _openAddBin() async {
    final result = await context.push('/add-bin');
    if (result is String) {
      await _loadData();
      await context.push('/bin/$result');
    } else if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openBin(String binId) async {
    // Check if user has pending request
    final hasPendingRequest = await _binService.hasPendingRequest(binId);
    if (hasPendingRequest) {
      // Show popup that request is under review
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Request Under Review'),
            content: const Text(
                'Your request to join this bin is currently under review by the bin owner. You will be notified once your request is approved.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final result = await context.push('/bin/$binId');
    // Fast refresh - only reload bins data, skip tasks and log counts
    if (mounted) {
      await _refreshBinsOnly();
      // Ensure we're on Home tab when returning from bin
      if (_selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getCommunityTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showLogBinPicker,
              icon: const Icon(Icons.edit_note),
              label: const Text('Log Activity'),
            )
          : null,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: Row(
            children: [
              const Icon(Icons.eco, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text('CompostKaki'),
            ],
          ),
          actions: [
            // Bell icon with notification badge (shows only new notifications since last visit)
            Consumer<NotificationService>(
              builder: (context, notificationService, _) {
                final newNotificationsCount =
                    notificationService.newNotificationsSinceLastVisit;
                return IconButton(
                  icon: NotificationBadge(
                    count: newNotificationsCount,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => _showNotificationsPage(context),
                  tooltip: 'Notifications',
                );
              },
            ),
            if (_bins.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showJoinBinDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Join Bin'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
          ],
        );
      case 1:
        return AppBar(
          title: const Text('Community Tasks'),
          automaticallyImplyLeading: false, // No back button on Tasks tab
        );
      case 2:
        return AppBar(
          title: const Text('Leaderboard'),
        );
      default:
        return AppBar(
          title: const Text('CompostKaki'),
        );
    }
  }

  Widget _buildBody() {
    // Only show loading if we're on Home tab (index 0) and loading bins
    if (_isLoading && _selectedIndex == 0) {
      return const Center(
        child: CompostLoadingAnimation(
          message: 'Loading your compost bins...',
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildJournalTab();
      case 1:
        return _buildCommunityTab();
      case 2:
        return _buildLeaderboardTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildJournalTab() {
    if (_isLoading) {
      return const Center(
        child: SimpleCompostLoader(
          message: 'Loading...',
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Sort bins by health status
    final sortedBins = List<Map<String, dynamic>>.from(_bins);
    sortedBins.sort((a, b) {
      final priority = {'Critical': 0, 'Needs Attention': 1, 'Healthy': 2};
      final aStatus = a['health_status'] as String? ?? 'Healthy';
      final bStatus = b['health_status'] as String? ?? 'Healthy';
      return (priority[aStatus] ?? 3).compareTo(priority[bStatus] ?? 3);
    });

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Kaki Mascot
          SliverToBoxAdapter(
            child: KakiMascotWidget(
              bins: _bins,
              xpStats: _xpStats,
              onTap: () {
                // Optional: Add any action when Kaki is tapped
                // Could show a dialog, navigate, etc.
              },
            ),
          ),
          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: _bins.length.toString(),
                      label: 'Active Bins',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      value: _userLogCount.toString(),
                      label: 'Logs',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Piles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  if (_bins.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _openAddBin,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New Bin'),
                    ),
                ],
              ),
            ),
          ),

          // Bins list
          if (sortedBins.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                onJoinBin: () => _showJoinBinDialog(context),
                onCreateBin: _openAddBin,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final bin = sortedBins[index];
                  final hasPendingRequest = bin['has_pending_request'] == true;
                  final binId = bin['id'] as String;

                  return Consumer<NotificationService>(
                    builder: (context, notificationService, _) {
                      // Use synchronous getters for reactive updates
                      final unreadMessages = notificationService
                          .getUnreadMessageCountForBinSync(binId);
                      final unreadActivities = notificationService
                          .getUnreadActivityCountForBinSync(binId);
                      final unreadJoinRequests = notificationService
                          .getUnreadJoinRequestCountForBinSync(binId);

                      return BinCard(
                        bin: bin,
                        onTap: () => _openBin(binId),
                        hasPendingRequest: hasPendingRequest,
                        unreadMessageCount: unreadMessages,
                        unreadActivityCount: unreadActivities,
                        unreadJoinRequestCount: unreadJoinRequests,
                      );
                    },
                  );
                },
                childCount: sortedBins.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    final currentUserId = _taskService.currentUserId;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final newTasks = _tasks.where((t) => t['status'] == 'open').toList();
    final ongoingTasks = _tasks
        .where((t) =>
            t['status'] == 'accepted' &&
            (t['accepted_by'] == currentUserId ||
                t['user_id'] == currentUserId))
        .toList();

    // Completed tasks from last 30 days - separate into pending and checked/reverted
    final allCompletedTasks = _tasks.where((t) {
      if (t['status'] != 'completed') return false;
      final completedAt = t['completed_at'] as String?;
      if (completedAt == null) return false;
      try {
        final completedDate = DateTime.parse(completedAt);
        return completedDate.isAfter(thirtyDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList();

    // Pending check tasks (white, shown first)
    final pendingCheckTasks = allCompletedTasks
        .where((t) => t['completion_status'] == 'pending_check')
        .toList();

    // Checked/reverted tasks (darkened green, shown second)
    final checkedRevertedTasks = allCompletedTasks
        .where((t) =>
            t['completion_status'] == 'checked' ||
            t['completion_status'] == 'reverted')
        .toList();

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // New Tasks
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (newTasks.isEmpty)
                      const Text(
                        'No new tasks.',
                        style: TextStyle(color: AppTheme.textGray),
                      )
                    else
                      ...newTasks.map((task) => TaskCard(
                            task: task,
                            bins: _bins,
                            onTap: () => _showTaskDetail(task),
                            isDeleting: _deletingTaskIds
                                .contains(task['id']?.toString()),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),

                // Ongoing Tasks
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ongoing Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (ongoingTasks.isEmpty)
                      const Text(
                        'No ongoing tasks.',
                        style: TextStyle(color: AppTheme.textGray),
                      )
                    else
                      ...ongoingTasks.map((task) => TaskCard(
                            task: task,
                            bins: _bins,
                            onTap: () => _showTaskDetail(task),
                            isDeleting: _deletingTaskIds
                                .contains(task['id']?.toString()),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),

                // Completed Tasks (Last 30 Days)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Completed Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showPastHistory(context),
                          child: const Text(
                            'View Past History',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pending check tasks (white, shown first)
                    if (pendingCheckTasks.isNotEmpty) ...[
                      ...pendingCheckTasks.map((task) => TaskCard(
                            task: task,
                            bins: _bins,
                            onTap: () => _showTaskDetail(task),
                            isCompleted: true,
                            isPendingCheck: true, // White background
                            isDeleting: _deletingTaskIds
                                .contains(task['id']?.toString()),
                          )),
                      const SizedBox(height: 12),
                    ],

                    // Checked/reverted tasks (darkened green, shown second)
                    if (checkedRevertedTasks.isNotEmpty)
                      ...checkedRevertedTasks.map((task) => TaskCard(
                            task: task,
                            bins: _bins,
                            onTap: () => _showTaskDetail(task),
                            isCompleted: true,
                            isPendingCheck: false, // Darkened green
                            isDeleting: _deletingTaskIds
                                .contains(task['id']?.toString()),
                          )),

                    if (pendingCheckTasks.isEmpty &&
                        checkedRevertedTasks.isEmpty)
                      const Text(
                        'No completed tasks in the last 30 days.',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsPage(BuildContext context) {
    context.push('/notifications');
  }

  void _showJoinBinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _JoinBinDialog(
        onJoin: (binId) async {
          try {
            // First, fetch bin details to show confirmation
            final bin = await _binService.getBin(binId);
            final binName = bin['name'] as String? ?? 'this bin';
            final contributors = bin['contributors_list'] as List? ?? [];
            final currentUserId = _binService.currentUserId;
            final isOwner = bin['user_id'] == currentUserId;
            final isMember = contributors.contains(currentUserId);
            final isAlreadyPartOfBin = isOwner || isMember;
            final hasPendingRequest =
                await _binService.hasPendingRequest(binId);

            if (!context.mounted) return;

            if (isAlreadyPartOfBin) {
              // User is already part of this bin
              final goToBin = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Already in Bin'),
                  content: Text('You are already part of "$binName"!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Go to Bin'),
                    ),
                  ],
                ),
              );

              if (goToBin == true && context.mounted) {
                Navigator.pop(context);
                await _openBin(binId);
              }
              return;
            }

            if (hasPendingRequest) {
              // User already has a pending request
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'You already have a pending request to join "$binName".'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
              return;
            }

            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Request to Join Bin'),
                content: Text(
                    'You are not part of "$binName". Would you like to request to join? The bin owner will review your request.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Request to Join'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;

            // Now request to join the bin
            await _binService.requestToJoinBin(binId);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Request sent to join "$binName"! The owner will review your request.'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
              await _loadData();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to request to join bin: $e')),
              );
            }
          }
        },
        onScan: () async {
          final scanned = await Navigator.push<String?>(
            context,
            MaterialPageRoute(
              builder: (_) => const JoinBinScannerScreen(),
            ),
          );
          return scanned;
        },
        onUploadQR: () async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked == null) return null;

          try {
            final controller = MobileScannerController();
            final result = await controller.analyzeImage(picked.path);
            await controller.dispose();

            if (result?.barcodes.isNotEmpty ?? false) {
              final rawValue = result!.barcodes.first.rawValue;
              if (rawValue != null) {
                // Try to extract bin ID from various formats:
                // 1. Deep link: compostkaki://bin/{uuid}
                // 2. Web URL: https://.../bin/{uuid} or /bin/{uuid}
                // 3. Just UUID: {uuid}
                final deepLinkMatch = RegExp(
                        r'compostkaki://bin/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})')
                    .firstMatch(rawValue);
                if (deepLinkMatch != null) return deepLinkMatch.group(1);

                final urlMatch = RegExp(
                        r'/bin/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})')
                    .firstMatch(rawValue);
                if (urlMatch != null) return urlMatch.group(1);

                final uuidMatch = RegExp(
                        r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$')
                    .firstMatch(rawValue);
                if (uuidMatch != null) return uuidMatch.group(1);
              }
            }

            // Throw exception instead of showing SnackBar - dialog will catch and display
            throw Exception('No QR code detected in that image.');
          } catch (e) {
            // If it's already our custom exception, re-throw it
            if (e.toString().contains('No QR code detected')) {
              rethrow;
            }
            // Otherwise, wrap other errors
            throw Exception(
                'Failed to read QR code: ${e.toString().replaceFirst('Exception: ', '')}');
          }
        },
      ),
    );
  }

  void _updateLocalTask(String taskId, Map<String, dynamic> updates) {
    setState(() {
      final index = _tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        _tasks[index] = {
          ..._tasks[index],
          ...updates,
        };
      }
    });
  }

  Future<void> _deleteTaskWithAnimation(Map<String, dynamic> task) async {
    final rawTaskId = task['id'];
    final taskId = rawTaskId?.toString();
    if (taskId == null || _deletingTaskIds.contains(taskId)) return;

    final originalIndex =
        _tasks.indexWhere((t) => t['id']?.toString() == taskId);
    final originalTask = Map<String, dynamic>.from(task);

    setState(() {
      _deletingTaskIds.add(taskId);
    });

    // Let the card play a quick "poof" before list reflows.
    await Future.delayed(const Duration(milliseconds: 220));

    if (mounted) {
      setState(() {
        _tasks.removeWhere((t) => t['id']?.toString() == taskId);
        _deletingTaskIds.remove(taskId);
      });
    }

    try {
      await _taskService.deleteTask(taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poof! Task deleted'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final safeIndex = originalIndex < 0 || originalIndex > _tasks.length
              ? _tasks.length
              : originalIndex;
          _tasks.insert(safeIndex, originalTask);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPastHistory(BuildContext context) {
    // Get all completed tasks (not just last 30 days)
    final allCompletedTasks =
        _tasks.where((t) => t['status'] == 'completed').toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Past Completed Tasks'),
        content: SizedBox(
          width: double.maxFinite,
          child: allCompletedTasks.isEmpty
              ? const Text('No completed tasks found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allCompletedTasks.length,
                  itemBuilder: (context, index) {
                    final task = allCompletedTasks[index];
                    final completionStatus =
                        task['completion_status'] as String?;
                    return TaskCard(
                      task: task,
                      bins: _bins,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showTaskDetail(task);
                      },
                      isCompleted: true,
                      isPendingCheck: completionStatus == 'pending_check',
                      isDeleting:
                          _deletingTaskIds.contains(task['id']?.toString()),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    // Capture parent context before showing dialog
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => _TaskDetailDialog(
        task: task,
        bins: _bins,
        onAccept: () async {
          // Show animation immediately (before closing dialog)
          showXPFloatingAnimation(
            dialogContext,
            xpAmount: 5, // Show immediately with expected value
            isLevelUp: false,
          );

          final xpResult = await _taskService.acceptTask(task['id']);
          _updateLocalTask(task['id'], {
            'status': 'accepted',
            'accepted_by': _taskService.currentUserId,
          });
          if (mounted) {
            _loadTasks();
            // Close dialog after a short delay to let animation start
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.pop(dialogContext);
          }
        },
        onComplete: () async {
          final xpResult = await _taskService.completeTask(task['id']);
          _updateLocalTask(task['id'], {
            'status': 'completed',
            'accepted_by': _taskService.currentUserId,
          });
          if (mounted) {
            _loadTasks();
            // Close dialog first
            Navigator.pop(dialogContext);
            // Wait a bit for dialog to close
            await Future.delayed(const Duration(milliseconds: 200));
            // Show celebration using parent context
            if (xpResult != null && parentContext.mounted) {
              final xpGained = (xpResult['xpGained'] as int?) ??
                  25; // Default to 25 for task completion
              final isLevelUp = (xpResult['levelUp'] as bool?) ?? false;

              if (xpGained > 0) {
                showXPFloatingAnimation(
                  parentContext,
                  xpAmount: xpGained,
                  isLevelUp: isLevelUp,
                );
              }
            }
          }
        },
        onUnassign: () async {
          // Show penalty animation immediately
          showXPFloatingAnimation(
            dialogContext,
            xpAmount: -5, // Show penalty immediately
            isLevelUp: false,
          );

          final xpResult = await _taskService.unassignTask(task['id']);
          _updateLocalTask(task['id'], {
            'status': 'open',
            'accepted_by': null,
          });
          if (mounted) {
            _loadTasks();
            // Close dialog after a short delay to let animation start
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.pop(dialogContext);
          }
        },
        onCheck: task['status'] == 'completed' &&
                task['completion_status'] == 'pending_check' &&
                task['user_id'] == _taskService.currentUserId
            ? () async {
                try {
                  await _taskService.checkTask(task['id']);
                  _updateLocalTask(task['id'], {
                    'completion_status': 'checked',
                    'checked_at': DateTime.now().toUtc().toIso8601String(),
                  });
                  if (mounted) {
                    _loadTasks();
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Task marked as checked'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
        onRevert: task['status'] == 'completed' &&
                task['completion_status'] == 'pending_check' &&
                task['user_id'] == _taskService.currentUserId
            ? () async {
                try {
                  final xpResult = await _taskService.revertTask(task['id']);
                  _updateLocalTask(task['id'], {
                    'status': 'open',
                    'completion_status': 'reverted',
                    'reverted_at': DateTime.now().toUtc().toIso8601String(),
                    'accepted_by': null,
                    'accepted_at': null,
                  });
                  if (mounted) {
                    _loadTasks();
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Task reverted. XP has been subtracted from completer.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
        onDelete: task['user_id'] == _taskService.currentUserId &&
                task['status'] != 'completed'
            ? () async {
                await _deleteTaskWithAnimation(task);
              }
            : null,
        onEdit: task['user_id'] == _taskService.currentUserId &&
                task['status'] != 'completed'
            ? () async {
                Navigator.pop(dialogContext);
                await _showEditTaskDialog(task);
              }
            : null,
      ),
    );
  }

  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    final taskId = task['id'] as String?;
    final binId = task['bin_id'] as String?;
    if (taskId == null || binId == null) return;

    final originalDescription = (task['description'] as String? ?? '').trim();
    final split = originalDescription.split('\n');
    final initialTitle = split.isNotEmpty ? split.first.trim() : '';
    final initialContent =
        split.length > 1 ? split.sublist(1).join('\n').trim() : '';

    final titleController = TextEditingController(text: initialTitle);
    final contentController = TextEditingController(text: initialContent);

    final assignableUsers = await _taskService.getBinAssignableUsers(binId);
    String? assignedToUserId = task['assigned_to'] as String?;
    bool isSaving = false;
    String? errorText;
    final parentContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitEdit() async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty) {
                setSheetState(() {
                  errorText = 'Please enter a task title.';
                });
                return;
              }
              if (assignedToUserId == _taskService.currentUserId) {
                setSheetState(() {
                  errorText = 'You cannot assign the task to yourself.';
                });
                return;
              }

              setSheetState(() {
                isSaving = true;
                errorText = null;
              });

              final updatedDescription =
                  content.isEmpty ? title : '$title\n\n$content';

              try {
                await _taskService.updateTask(
                  taskId: taskId,
                  description: updatedDescription,
                  assignedTo: assignedToUserId,
                );

                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }

                if (parentContext.mounted) {
                  await _loadTasks();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Task updated successfully'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              } catch (e) {
                setSheetState(() {
                  errorText = e.toString().replaceFirst('Exception: ', '');
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text(
                'Edit Task',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Add details for this task...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: assignedToUserId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned to',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Anyone'),
                          ),
                          ...assignableUsers.map(
                            (user) => DropdownMenuItem<String>(
                              value: user['id'],
                              child: Text(
                                '${user['name'] ?? 'User'}${user['id'] == _taskService.currentUserId ? ' (You)' : ''}',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            assignedToUserId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bin cannot be changed.',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.textGray),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submitEdit,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.emoji_events, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Leaderboard is coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Track your compost contributions and compete with your community.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Consumer<NotificationService>(
              builder: (context, notificationService, _) {
                final homeBadgeCount = notificationService.unreadMessages +
                    notificationService.unreadJoinRequests;
                // Debug: Print home tab badge count
                if (homeBadgeCount > 0) {
                  debugPrint('Home tab badge count: $homeBadgeCount '
                      '(Messages: ${notificationService.unreadMessages}, '
                      'JoinRequests: ${notificationService.unreadJoinRequests})');
                }
                return _buildNavItem(
                  index: 0,
                  icon: Icons.home,
                  label: 'Home',
                  badgeCount: homeBadgeCount,
                );
              },
            ),
            Consumer<NotificationService>(
              builder: (context, notificationService, _) => _buildNavItem(
                index: 1,
                icon: Icons.assignment,
                label: 'Tasks',
                badgeCount: notificationService.unreadHelpRequests,
              ),
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.leaderboard,
              label: 'Leaderboard',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person,
              label: 'Profile',
              onTapOverride: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    VoidCallback? onTapOverride,
    int? badgeCount,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryGreen : AppTheme.textGray;
    final notificationService = context.watch<NotificationService>();

    return Expanded(
      child: InkWell(
        onTap: onTapOverride ??
            () {
              if (_selectedIndex != index) {
                setState(() {
                  _selectedIndex = index;
                });
                if (index == 1) {
                  _loadTasks();
                  // Clear help request and task completed badges when viewing tasks tab
                  notificationService.markAsRead(type: 'help_request');
                  notificationService.markAsRead(type: 'task_completed');
                } else if (index == 0) {
                  // Clear message badges when viewing home tab (messages are in bin detail)
                  // We'll handle this in bin detail screen instead
                }
              }
            },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationBadge(
                count: badgeCount ?? 0,
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogBinPicker() {
    if (_bins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to join or add a bin first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Log Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bins.length,
                  itemBuilder: (context, index) {
                    final bin = _bins[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.eco, color: AppTheme.primaryGreen),
                      title: Text(bin['name'] as String? ?? 'Bin'),
                      subtitle: Text(bin['location'] as String? ?? ''),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final result =
                            await context.push('/bin/${bin['id']}/log');
                        if (result == true && mounted) {
                          _refreshBinsOnly();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onJoinBin;
  final VoidCallback onCreateBin;

  const _EmptyState({
    required this.onJoinBin,
    required this.onCreateBin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.eco,
              size: 120,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Wow, it\'s empty!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have any compost bins yet.\nGet started by joining an existing bin or creating a new one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onJoinBin,
                child: const Text('Join an Existing Bin'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('OR', style: TextStyle(color: AppTheme.textGray)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreateBin,
                child: const Text('Create a New Bin'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinBinDialog extends StatefulWidget {
  final Future<void> Function(String) onJoin;
  final Future<String?> Function()? onScan;
  final Future<String?> Function()? onUploadQR;

  const _JoinBinDialog({required this.onJoin, this.onScan, this.onUploadQR});

  @override
  State<_JoinBinDialog> createState() => _JoinBinDialogState();
}

class _JoinBinDialogState extends State<_JoinBinDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _joinBin() async {
    final text = _controller.text;
    final binId = _extractBinId(text);

    if (binId == null) {
      setState(() {
        _error = 'Please enter a valid bin ID, link, or scan a QR code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await widget.onJoin(binId);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _extractBinId(String? text) {
    if (text == null) return null;
    final uuidRegex = RegExp(
        r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})');
    final match = uuidRegex.firstMatch(text);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request to Join a Bin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Paste bin link here',
              hintText: 'https://... or bin ID',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.onScan != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final scanned = await widget.onScan!.call();
                            if (scanned != null) {
                              setState(() {
                                _controller.text = scanned;
                                _error = null;
                              });
                            }
                          },
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text('Scan QR'),
                  ),
                ),
              if (widget.onScan != null && widget.onUploadQR != null)
                const SizedBox(width: 8),
              if (widget.onUploadQR != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            try {
                              final uploaded = await widget.onUploadQR!.call();
                              if (uploaded != null) {
                                setState(() {
                                  _controller.text = uploaded;
                                  _error = null;
                                });
                              }
                            } catch (e) {
                              setState(() {
                                _error = e
                                    .toString()
                                    .replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    icon: const Icon(Icons.upload, size: 20),
                    label: const Text('Upload QR'),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinBin,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Request to Join'),
        ),
      ],
    );
  }
}

class _TaskDetailDialog extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> bins;
  final VoidCallback onAccept;
  final VoidCallback onComplete;
  final VoidCallback onUnassign;
  final VoidCallback? onCheck;
  final VoidCallback? onRevert;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _TaskDetailDialog({
    required this.task,
    required this.bins,
    required this.onAccept,
    required this.onComplete,
    required this.onUnassign,
    this.onCheck,
    this.onRevert,
    this.onDelete,
    this.onEdit,
  });

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
    var details = lines.sublist(firstNonEmptyIndex + 1).join('\n').trim();

    // Normalize legacy/new task formats so dialog content avoids duplicate headings.
    final detailParts =
        details.split('\n').map((line) => line.trimRight()).toList();
    if (detailParts.isNotEmpty &&
        detailParts.first.trim().toLowerCase() == 'additional detail') {
      detailParts.removeAt(0);
      details = detailParts.join('\n').trim();
    }

    return (title: title, details: details);
  }

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

  @override
  Widget build(BuildContext context) {
    final binId = task['bin_id'] as String?;
    final bin = bins.firstWhere(
      (b) => b['id'] == binId,
      orElse: () => {'name': 'Unknown'},
    );
    final description = task['description'] as String? ?? '';
    final parsedDescription = _parseTaskDescription(description);
    final urgency = task['urgency'] as String? ?? 'Normal';
    final effort = task['effort'] as String? ?? '';
    final status = task['status'] as String? ?? 'open';
    final completionStatus = task['completion_status'] as String?;
    final profile = task['profiles'] as Map<String, dynamic>?;
    final posterAvatarUrl = profile?['avatar_url'] as String?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final taskPosterId = task['user_id'] as String?;
    final acceptedBy = task['accepted_by'];
    final assignedToProfile =
        task['assigned_to_profile'] as Map<String, dynamic>?;
    final assignedAvatarUrl = assignedToProfile?['avatar_url'] as String?;
    // Get current user ID from TaskService
    final taskService = TaskService();
    final currentUserId = taskService.currentUserId;
    final assignedFirstName = assignedToProfile?['first_name'] as String?;
    final assignedLastName = assignedToProfile?['last_name'] as String?;
    final assignedToName = assignedFirstName != null && assignedLastName != null
        ? '$assignedFirstName $assignedLastName'.trim()
        : assignedFirstName ?? 'Anyone';
    final acceptedByProfile =
        task['accepted_by_profile'] as Map<String, dynamic>?;
    final acceptedAvatarUrl = acceptedByProfile?['avatar_url'] as String?;
    final acceptedByFirstName = acceptedByProfile?['first_name'] as String?;
    final acceptedByLastName = acceptedByProfile?['last_name'] as String?;
    final acceptedByName =
        acceptedByFirstName != null && acceptedByLastName != null
            ? '$acceptedByFirstName $acceptedByLastName'.trim()
            : acceptedByFirstName ?? 'Unknown';
    final isTimeSensitive = task['is_time_sensitive'] == true;
    final dueDateRaw = task['due_date'] as String?;
    final timeLeft = _getTimeLeft(dueDateRaw);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
            backgroundImage:
                posterAvatarUrl != null && posterAvatarUrl.trim().isNotEmpty
                    ? NetworkImage(posterAvatarUrl)
                    : null,
            child: (posterAvatarUrl == null || posterAvatarUrl.trim().isEmpty)
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
            child: Text(
              parsedDescription.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
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
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _TaskDetailInfoRow(
              label: 'Bin',
              child: _TaskDetailMetaChip(
                icon: Icons.eco_outlined,
                label: bin['name'] as String? ?? 'Unknown',
              ),
            ),
            const SizedBox(height: 8),
            _TaskDetailInfoRow(
              label: 'Assigned to',
              child: _TaskDetailMetaChip(
                icon: Icons.person_outline,
                label: assignedToName,
                avatarUrl: assignedAvatarUrl,
              ),
            ),
            const SizedBox(height: 8),
            _TaskDetailInfoRow(
              label: 'Status',
              child: _TaskDetailMetaChip(
                icon: Icons.flag_outlined,
                label: status.toUpperCase(),
                backgroundColor: _statusColor(status),
              ),
            ),
            if (effort.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _TaskDetailInfoRow(
                label: 'Effort',
                child: _TaskDetailMetaChip(
                  icon: Icons.bolt_outlined,
                  label: effort,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _TaskDetailInfoRow(
              label: 'Posted by',
              child: _TaskDetailMetaChip(
                icon: Icons.person_outline,
                label: firstName,
                avatarUrl: posterAvatarUrl,
              ),
            ),
            if (isTimeSensitive && timeLeft.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TaskDetailInfoRow(
                label: 'Time left',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: timeLeft.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: timeLeft.color),
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
              ),
            ],
            const SizedBox(height: 12),
            if (parsedDescription.details.isNotEmpty) ...[
              const Text(
                'Additional details',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                parsedDescription.details,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (status == 'accepted' && acceptedBy != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
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
            if (status == 'completed' && acceptedBy != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
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
                    'Completed by $acceptedByName',
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
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Any authenticated non-owner member can complete an accepted task
              if (status == 'accepted' &&
                  currentUserId != null &&
                  taskPosterId != currentUserId) ...[
                // Mark as Completed (top)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onComplete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark as Completed'),
                  ),
                ),
                const SizedBox(height: 8),
                // Unassign (middle)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUnassign();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange, width: 1.5),
                    ),
                    child: const Text('Unassign Task'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Show Checked and Revert buttons for completed tasks (only for task owner)
              if (status == 'completed' &&
                  completionStatus == 'pending_check' &&
                  taskPosterId == currentUserId &&
                  onCheck != null &&
                  onRevert != null) ...[
                // Checked button (confirm completion)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onCheck!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Checked'),
                  ),
                ),
                const SizedBox(height: 8),
                // Revert button (reject completion)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onRevert!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    child: const Text('Not Done Properly'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (status == 'open' &&
                  acceptedBy != currentUserId &&
                  taskPosterId != currentUserId) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (onDelete != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    child: const Text('Delete Task'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (onEdit != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                    child: const Text('Edit Task'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Close (bottom)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskDetailInfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _TaskDetailInfoRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _TaskDetailMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final String? avatarUrl;

  const _TaskDetailMetaChip({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.avatarUrl,
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
