import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bin_card.dart';
import '../../widgets/task_card.dart';
import '../bin/add_bin_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BinService _binService = BinService();
  final TaskService _taskService = TaskService();
  
  List<Map<String, dynamic>> _bins = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;
  int _userLogCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
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
      
      // Get tasks if on community tab
      List<Map<String, dynamic>> tasks = [];
      if (_tabController.index == 1) {
        tasks = await _taskService.getCommunityTasks();
      }
      
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
    final result = await context.push('/bin/$binId');
    if (result == true) {
      await _loadData();
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _tasks.isEmpty) {
      _loadTasks();
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
      appBar: AppBar(
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
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppTheme.backgroundGray,
            child: TabBar(
              controller: _tabController,
              onTap: (_) => _onTabChanged(),
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: AppTheme.textGray,
              indicatorColor: AppTheme.primaryGreen,
              tabs: const [
                Tab(text: 'Journal'),
                Tab(text: 'Community'),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJournalTab(),
                _buildCommunityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                  return BinCard(
                    bin: bin,
                    onTap: () => _openBin(bin['id'] as String),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final newTasks = _tasks.where((t) => t['status'] == 'open').toList();
    final ongoingTasks = _tasks.where((t) => 
      t['status'] == 'accepted' && 
      t['accepted_by'] == _taskService.currentUserId
    ).toList();

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
            await _binService.joinBin(binId);
            if (context.mounted) {
              Navigator.pop(context);
              await _loadData();
              await _openBin(binId);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to join bin: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => _TaskDetailDialog(
        task: task,
        bins: _bins,
        onAccept: () async {
          await _taskService.acceptTask(task['id']);
          if (context.mounted) {
            Navigator.pop(context);
            _loadTasks();
          }
        },
        onComplete: () async {
          await _taskService.completeTask(task['id']);
          if (context.mounted) {
            Navigator.pop(context);
            _loadTasks();
          }
        },
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

  const _JoinBinDialog({required this.onJoin});

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
    // Extract UUID from URL or text
    final uuidRegex = RegExp(r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})');
    final match = uuidRegex.firstMatch(text);
    
    if (match == null) {
      setState(() {
        _error = 'Please enter a valid bin ID or URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await widget.onJoin(match.group(1)!);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a Bin'),
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
              : const Text('Join'),
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
              Navigator.pop(context);
              onAccept();
            },
            child: const Text('Accept'),
          ),
        if (status == 'accepted' && acceptedBy == currentUserId)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onComplete();
            },
            child: const Text('Mark as Completed'),
          ),
      ],
    );
  }
}
