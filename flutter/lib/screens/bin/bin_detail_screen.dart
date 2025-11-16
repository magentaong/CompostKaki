import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_timeline_item.dart';

class BinDetailScreen extends StatefulWidget {
  final String binId;

  const BinDetailScreen({super.key, required this.binId});

  @override
  State<BinDetailScreen> createState() => _BinDetailScreenState();
}

class _BinDetailScreenState extends State<BinDetailScreen> {
  final BinService _binService = BinService();
  Map<String, dynamic>? _bin;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String? _error;
  int _logsToShow = 7;

  @override
  void initState() {
    super.initState();
    _loadBin();
  }

  Future<void> _loadBin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bin = await _binService.getBin(widget.binId);
      final activities = await _binService.getBinLogs(widget.binId);
      
      if (mounted) {
        setState(() {
          _bin = bin;
          _activities = activities;
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

  Color _getHealthColor(String? status) {
    switch (status) {
      case 'Critical':
        return AppTheme.healthCritical;
      case 'Healthy':
        return AppTheme.healthHealthy;
      case 'Needs Attention':
        return AppTheme.healthNeedsAttention;
      default:
        return AppTheme.healthHealthy;
    }
  }

  Color _getHealthTextColor(String? status) {
    switch (status) {
      case 'Critical':
        return AppTheme.healthCriticalText;
      case 'Healthy':
        return Colors.black87;
      case 'Needs Attention':
        return AppTheme.healthNeedsAttentionText;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _bin == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bin Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadBin,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final healthStatus = _bin!['health_status'] as String? ?? 'Healthy';
    final temperature = _bin!['latest_temperature'];
    final moisture = _bin!['latest_moisture'];
    final flips = _bin!['latest_flips'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _bin!['image'] != null
                  ? CachedNetworkImage(
                      imageUrl: _bin!['image'] as String,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.image, size: 64),
                      ),
                    )
                  : Container(
                      color: AppTheme.backgroundGray,
                      child: const Icon(Icons.eco, size: 64, color: AppTheme.primaryGreen),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () {
                  // QR code functionality
                },
              ),
            ],
          ),
          
          // Bin info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _bin!['name'] as String? ?? 'Bin',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getHealthColor(healthStatus),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      healthStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getHealthTextColor(healthStatus),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: temperature != null ? '$temperature°C' : '-°C',
                          label: 'Temp',
                          icon: Icons.thermostat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: moisture?.toString() ?? '-',
                          label: 'Moisture',
                          icon: Icons.water_drop,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: flips?.toString() ?? '-',
                          label: 'Flips',
                          icon: Icons.refresh,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/bin/${widget.binId}/log'),
                      icon: const Icon(Icons.add),
                      label: const Text('Log Activity'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Ask for help
                      },
                      icon: const Text('💪'),
                      label: const Text('Ask for Help'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Activity timeline
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_activities.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No activities logged yet.',
                          style: TextStyle(color: AppTheme.textGray),
                        ),
                      ),
                    )
                  else
                    ..._activities.take(_logsToShow).map((activity) => 
                      ActivityTimelineItem(activity: activity)
                    ),
                  if (_activities.length > _logsToShow)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _logsToShow += 7;
                          });
                        },
                        child: Text('Load ${_activities.length - _logsToShow} more logs'),
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

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderGray, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

