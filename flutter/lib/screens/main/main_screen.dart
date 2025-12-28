import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bin_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/compost_loading_animation.dart';
import '../bin/add_bin_screen.dart';
import '../bin/join_bin_scanner_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final BinService _binService = BinService();
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> _bins = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;
  int _userLogCount = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bins = await _binService.getUserBins();

      // Get log count
      int logCount = 0;
      for (var bin in bins) {
        final logs = await _binService.getBinLogs(bin['id'] as String);
        logCount += logs.length;
      }

      // Always fetch tasks so community tab is ready
      final tasks = await _taskService.getCommunityTasks();

      if (mounted) {
        setState(() {
          _bins = bins;
          _userLogCount = logCount;
          _tasks = tasks;
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
    if (result == true) {
      await _loadData();
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
    if (_isLoading) {
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
                  return BinCard(
                    bin: bin,
                    onTap: () => _openBin(bin['id'] as String),
                    hasPendingRequest: hasPendingRequest,
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
    final newTasks = _tasks.where((t) => t['status'] == 'open').toList();
    final ongoingTasks = _tasks
        .where((t) =>
            t['status'] == 'accepted' &&
            t['accepted_by'] == _taskService.currentUserId)
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
                          )),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
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
                final deepLinkMatch = RegExp(r'compostkaki://bin/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})').firstMatch(rawValue);
                if (deepLinkMatch != null) return deepLinkMatch.group(1);
                
                final urlMatch = RegExp(r'/bin/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})').firstMatch(rawValue);
                if (urlMatch != null) return urlMatch.group(1);
                
                final uuidMatch = RegExp(r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$').firstMatch(rawValue);
                if (uuidMatch != null) return uuidMatch.group(1);
              }
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('No QR code detected in that image.')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to read QR code: $e')),
              );
            }
          }
          return null;
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

  void _showTaskDetail(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => _TaskDetailDialog(
        task: task,
        bins: _bins,
        onAccept: () async {
          await _taskService.acceptTask(task['id']);
          _updateLocalTask(task['id'], {
            'status': 'accepted',
            'accepted_by': _taskService.currentUserId,
          });
          if (mounted) _loadTasks();
        },
        onComplete: () async {
          await _taskService.completeTask(task['id']);
          _updateLocalTask(task['id'], {'status': 'completed'});
          if (mounted) _loadTasks();
        },
      ),
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
            _buildNavItem(
              index: 0,
              icon: Icons.home,
              label: 'Home',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.assignment,
              label: 'Tasks',
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
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryGreen : AppTheme.textGray;
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
                }
              }
            },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
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
            ..._bins.map((bin) => ListTile(
                  leading: const Icon(Icons.eco, color: AppTheme.primaryGreen),
                  title: Text(bin['name'] as String? ?? 'Bin'),
                  subtitle: Text(bin['location'] as String? ?? ''),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await context.push('/bin/${bin['id']}/log');
                    if (result == true && mounted) {
                      _loadData();
                    }
                  },
                )),
            const SizedBox(height: 8),
          ],
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
                            final uploaded = await widget.onUploadQR!.call();
                            if (uploaded != null) {
                              setState(() {
                                _controller.text = uploaded;
                                _error = null;
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

  const _TaskDetailDialog({
    required this.task,
    required this.bins,
    required this.onAccept,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final binId = task['bin_id'] as String?;
    final bin = bins.firstWhere(
      (b) => b['id'] == binId,
      orElse: () => {'name': 'Unknown'},
    );
    final description = task['description'] as String? ?? '';
    final urgency = task['urgency'] as String? ?? 'Normal';
    final effort = task['effort'] as String? ?? '';
    final status = task['status'] as String? ?? 'open';
    final profile = task['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? 'Unknown';
    final currentUserId = task['user_id'] as String?;
    final acceptedBy = task['accepted_by'];

    return AlertDialog(
      title: Text(description),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bin: ${bin['name']}'),
            const SizedBox(height: 8),
            Text('Urgency: $urgency'),
            const SizedBox(height: 8),
            Text('Effort: $effort'),
            const SizedBox(height: 8),
            Text('Status: $status'),
            const SizedBox(height: 8),
            Text('Posted by: $firstName'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (status == 'open' && acceptedBy != currentUserId)
          ElevatedButton(
            onPressed: () {
              onAccept();
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        if (status == 'accepted' && acceptedBy == currentUserId)
          ElevatedButton(
            onPressed: () {
              onComplete();
              Navigator.pop(context);
            },
            child: const Text('Mark as Completed'),
          ),
      ],
    );
  }
}
