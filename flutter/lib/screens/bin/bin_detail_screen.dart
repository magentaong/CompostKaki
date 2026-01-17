import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_timeline_item.dart';
import '../../widgets/compost_loading_animation.dart';
import '../../widgets/bin_leaderboard_widget.dart';
import '../../widgets/notification_badge.dart';
import '../../services/educational_service.dart';

// Helper function to get current time in Singapore (UTC+8)
DateTime _getSingaporeTime() {
  return DateTime.now().toUtc().add(const Duration(hours: 8));
}

class BinDetailScreen extends StatefulWidget {
  final String binId;

  const BinDetailScreen({super.key, required this.binId});

  @override
  State<BinDetailScreen> createState() => _BinDetailScreenState();
}

class _BinDetailScreenState extends State<BinDetailScreen> {
  static const _defaultBinImage =
      'https://tqpjrlwdgoctacfrbanf.supabase.co/storage/v1/object/public/bin-images/image_2025-11-18_153342109.png';
  static const _legacyDefaultImages = {
    'https://images.unsplash.com/photo-1445620466293-d6316372ab59?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1445620466293-d6316372ab59?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=80',
  };
  final BinService _binService = BinService();
  final TaskService _taskService = TaskService();
  Map<String, dynamic>? _bin;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String? _error;
  int _logsToShow = 7;
  bool _isDeleting = false;
  bool _canDelete = false;
  bool _isUploadingImage = false;
  bool _isOwner = false;
  bool _hasUpdates = false;
  bool _hasCustomImage(String? image) {
    if (image == null) return false;
    final trimmed = image.trim();
    if (trimmed.isEmpty) return false;
    return !_legacyDefaultImages.contains(trimmed);
  }

  String get _deepLink => 'compostkaki://bin/${widget.binId}';

  @override
  void initState() {
    super.initState();
    _loadBin();
    
    // Clear activity badges when viewing bin detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = context.read<NotificationService>();
      notificationService.markAsRead(type: 'activity', binId: widget.binId);
    });
  }

  Future<void> _loadBin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bin = await _binService.getBin(widget.binId);
      final activities = await _binService.getBinLogs(widget.binId);
      final isOwner = bin['user_id'] == _binService.currentUserId;

      if (mounted) {
        setState(() {
          _bin = bin;
          _activities = activities;
          _canDelete = isOwner;
          _isOwner = isOwner;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if bin was deleted
        if (e.toString().contains('deleted') ||
            e.toString().contains('no longer exists')) {
          // Show dialog and navigate back
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Bin Not Found'),
              content: const Text('This bin has been deleted by the owner.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _hasUpdates = true;
                    _popWithResult();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
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

  String _getAgeText(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdDate);
      final days = difference.inDays;
      
      if (days == 0) {
        return 'Created today';
      } else if (days == 1) {
        return '1 day old';
      } else {
        return '$days days old';
      }
    } catch (e) {
      return '';
    }
  }

  void _popWithResult() {
    // Pop back with result so main screen can refresh
    // Always return true to indicate data should be refreshed
    if (Navigator.of(context).canPop()) {
      context.pop(true); // Always return true to trigger refresh
    } else {
      // Can't pop, navigate to home
      context.go('/main?tab=home');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bin'),
        content: const Text('This action cannot be undone. Delete this bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });
      try {
        await _binService.deleteBin(widget.binId);
        _hasUpdates = true;
        if (mounted) {
          _popWithResult();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _confirmLeave() async {
    final binName = _bin?['name'] ?? 'this bin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Bin'),
        content: Text('Are you sure you want to leave "$binName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });
      try {
        await _binService.leaveBin(widget.binId);
        _hasUpdates = true;
        if (mounted) {
          _popWithResult();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _shareBin() async {
    final name = _bin?['name'] ?? 'our compost bin';
    final message =
        'Join $name on CompostKaki!\n\nTap here to join: $_deepLink';
    await Share.share(message);
  }

  Widget _buildBinStatusSection() {
    if (_bin == null) return const SizedBox.shrink();

    final binStatus = _bin!['bin_status'] as String? ?? 'active';
    final restingUntil = _bin!['resting_until'] as String?;
    final maturedAt = _bin!['matured_at'] as String?;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (binStatus) {
      case 'resting':
        statusColor = Colors.orange;
        statusText = 'Resting';
        statusIcon = Icons.bedtime;
        break;
      case 'matured':
        statusColor = Colors.purple;
        statusText = 'Matured';
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = AppTheme.primaryGreen;
        statusText = 'Active';
        statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Status: $statusText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_isOwner)
                TextButton.icon(
                  onPressed: _showStatusChangeDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (binStatus == 'resting' && restingUntil != null) ...[
            const SizedBox(height: 8),
            _buildRestingCountdown(restingUntil),
          ],
          if (binStatus == 'matured' && maturedAt != null) ...[
            const SizedBox(height: 8),
            _buildMaturedDepletion(maturedAt),
          ],
        ],
      ),
    );
  }

  Widget _buildRestingCountdown(String restingUntilStr) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => _getSingaporeTime()),
      builder: (context, snapshot) {
        final now = _getSingaporeTime();
        // Parse the timestamp from database (stored in UTC)
        // Supabase timestamps are in UTC, so parse as UTC and convert to Singapore time
        DateTime until;
        try {
          // Parse the timestamp - Supabase stores in UTC
          // Ensure we parse as UTC by adding Z if not present
          String timestampStr = restingUntilStr;
          if (!timestampStr.endsWith('Z') && !timestampStr.contains('+') && !timestampStr.contains('-', 10)) {
            // No timezone info, add Z to force UTC parsing
            timestampStr = '${timestampStr}Z';
          }
          final parsed = DateTime.parse(timestampStr);
          // Convert UTC to Singapore time (add 8 hours)
          until = parsed.isUtc 
              ? parsed.add(const Duration(hours: 8))
              : parsed.toUtc().add(const Duration(hours: 8));
        } catch (e) {
          // Fallback: try adding Z and parsing as UTC
          until = DateTime.parse('${restingUntilStr}Z').add(const Duration(hours: 8));
        }
        final difference = until.difference(now);

        if (difference.isNegative) {
          return Text(
            'Resting period completed',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
            ),
          );
        }

        final days = difference.inDays;
        final hours = difference.inHours % 24;
        final minutes = difference.inMinutes % 60;

        // Calculate progress: estimate start time from updated_at or calculate backwards
        // We'll use updated_at as when resting started, or estimate from remaining time
        final restingStarted = _bin?['updated_at'] as String?;
        double progressPercent = 0.0;
        int totalDays = 0;
        
          try {
            DateTime? started;
            if (restingStarted != null) {
              // Convert to Singapore time - handle timezone parsing
              final startedStr = restingStarted.toString();
              if (startedStr.endsWith('Z') || startedStr.contains('+') || startedStr.contains('-', 10)) {
                started = DateTime.parse(startedStr).toUtc().add(const Duration(hours: 8));
              } else {
                started = DateTime.parse('${startedStr}Z').toUtc().add(const Duration(hours: 8));
              }
            } else {
              // If no updated_at, estimate start as (now - some reasonable default)
              // But we'll calculate backwards from until date
              started = now.subtract(Duration(days: days + 1)); // Estimate 1 day has passed
            }
          
          if (started != null) {
            final totalDuration = until.difference(started);
            final elapsed = now.difference(started);
            
            if (totalDuration.inDays > 0) {
              totalDays = totalDuration.inDays;
              progressPercent = (elapsed.inDays / totalDuration.inDays * 100).clamp(0.0, 100.0);
            } else {
              // Fallback: if duration calculation fails, use remaining days as estimate
              totalDays = days + 1; // Assume at least 1 day has passed
              progressPercent = ((totalDays - days) / totalDays * 100).clamp(0.0, 100.0);
            }
          }
        } catch (e) {
          // If parsing fails, use a simple estimate
          totalDays = days + 1;
          progressPercent = ((totalDays - days) / totalDays * 100).clamp(0.0, 100.0);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Unlocks in ${days}d ${hours}h ${minutes}m',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                backgroundColor: Colors.orange[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              days == 1 ? '$days day remaining' : '$days days remaining',
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 11,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaturedDepletion(String maturedAtStr) {
    // Convert to Singapore time - handle timezone parsing
    DateTime matured;
    if (maturedAtStr.endsWith('Z') || maturedAtStr.contains('+') || maturedAtStr.contains('-', 10)) {
      matured = DateTime.parse(maturedAtStr).toUtc().add(const Duration(hours: 8));
    } else {
      matured = DateTime.parse('${maturedAtStr}Z').toUtc().add(const Duration(hours: 8));
    }
    final now = _getSingaporeTime();
    final daysSinceMatured = now.difference(matured).inDays;
    const sixMonthsInDays = 180;
    final depletionPercent = (daysSinceMatured / sixMonthsInDays * 100).clamp(0.0, 100.0);
    final daysRemaining = (sixMonthsInDays - daysSinceMatured).clamp(0, sixMonthsInDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hourglass_bottom, size: 16, color: Colors.purple[700]),
            const SizedBox(width: 4),
            Text(
              'Microbes depleting: ${depletionPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.purple[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: depletionPercent / 100,
            backgroundColor: Colors.purple[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[700]!),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          daysRemaining == 1 ? '$daysRemaining day remaining' : '$daysRemaining days remaining',
          style: TextStyle(
            color: Colors.purple[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<void> _showStatusChangeDialog() async {
    if (!_isOwner) return;

    String selectedStatus = _bin!['bin_status'] as String? ?? 'active';
    DateTime? restingUntil;
    DateTime? maturedAt;

    // Pre-fill existing dates (convert from UTC to Singapore time for display)
    final existingRestingUntil = _bin!['resting_until'] as String?;
    if (existingRestingUntil != null) {
      final untilStr = existingRestingUntil.toString();
      if (untilStr.endsWith('Z') || untilStr.contains('+') || untilStr.contains('-', 10)) {
        restingUntil = DateTime.parse(untilStr).toUtc().add(const Duration(hours: 8));
      } else {
        restingUntil = DateTime.parse('${untilStr}Z').toUtc().add(const Duration(hours: 8));
      }
    }

    final existingMaturedAt = _bin!['matured_at'] as String?;
    if (existingMaturedAt != null) {
      final maturedStr = existingMaturedAt.toString();
      if (maturedStr.endsWith('Z') || maturedStr.contains('+') || maturedStr.contains('-', 10)) {
        maturedAt = DateTime.parse(maturedStr).toUtc().add(const Duration(hours: 8));
      } else {
        maturedAt = DateTime.parse('${maturedStr}Z').toUtc().add(const Duration(hours: 8));
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Bin Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Active'),
                  subtitle: const Text('Normal operation'),
                  value: 'active',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Resting'),
                  subtitle: const Text('Locked away, only flipping allowed'),
                  value: 'resting',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() {
                    selectedStatus = value!;
                    if (restingUntil == null) {
                      restingUntil = _getSingaporeTime().add(const Duration(days: 7));
                    }
                  }),
                ),
                if (selectedStatus == 'resting') ...[
                  const SizedBox(height: 8),
                  const Text('Resting until:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: restingUntil ?? _getSingaporeTime().add(const Duration(days: 7)),
                        firstDate: _getSingaporeTime(),
                        lastDate: _getSingaporeTime().add(const Duration(days: 365)),
                      );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(restingUntil ?? _getSingaporeTime()),
                      );
                      if (time != null) {
                        setState(() {
                          // Create DateTime - the picked date/time is what user wants in Singapore time
                          // DateTime constructor creates in local time, but we treat it as Singapore time
                          restingUntil = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            restingUntil != null
                                ? DateFormat('MMM dd, yyyy HH:mm').format(restingUntil!)
                                : 'Select date',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                RadioListTile<String>(
                  title: const Text('Matured'),
                  subtitle: const Text('Microbes depleting over 6 months'),
                  value: 'matured',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() {
                    selectedStatus = value!;
                    if (maturedAt == null) {
                      maturedAt = _getSingaporeTime();
                    }
                  }),
                ),
                if (selectedStatus == 'matured') ...[
                  const SizedBox(height: 8),
                  const Text('Matured on:', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: maturedAt ?? _getSingaporeTime(),
                        firstDate: _getSingaporeTime().subtract(const Duration(days: 365)),
                        lastDate: _getSingaporeTime(),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(maturedAt ?? _getSingaporeTime()),
                        );
                        if (time != null) {
                          setState(() {
                            // Create DateTime in Singapore time
                            maturedAt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            maturedAt != null
                                ? DateFormat('MMM dd, yyyy HH:mm').format(maturedAt!)
                                : 'Select date',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Convert Singapore time back to UTC for storage
                  // The DateTime from date picker represents Singapore time (what user selected)
                  DateTime? restingUntilUtc;
                  if (selectedStatus == 'resting' && restingUntil != null) {
                    // The picked time represents Singapore time (16:55 SGT)
                    // Convert to UTC: Singapore time - 8 hours = UTC (08:55 UTC)
                    final sgTime = restingUntil!;
                    // Create UTC DateTime with Singapore time values, then subtract 8 hours
                    restingUntilUtc = DateTime.utc(
                      sgTime.year,
                      sgTime.month,
                      sgTime.day,
                      sgTime.hour,
                      sgTime.minute,
                    ).subtract(const Duration(hours: 8));
                  }
                  
                  DateTime? maturedAtUtc;
                  if (selectedStatus == 'matured' && maturedAt != null) {
                    // The picked time represents Singapore time
                    // Convert to UTC: Singapore time - 8 hours = UTC
                    final sgTime = maturedAt!;
                    maturedAtUtc = DateTime.utc(
                      sgTime.year,
                      sgTime.month,
                      sgTime.day,
                      sgTime.hour,
                      sgTime.minute,
                    ).subtract(const Duration(hours: 8));
                  }
                  
                  await _binService.updateBinStatus(
                    binId: widget.binId,
                    status: selectedStatus,
                    restingUntil: restingUntilUtc,
                    maturedAt: maturedAtUtc,
                  );
                  _hasUpdates = true;
                  await _loadBin();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bin status updated'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only the bin owner can update the photo.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      await _binService.updateBinImage(widget.binId, File(picked.path));
      _hasUpdates = true;
      await _loadBin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _showQrCodeDialog() async {
    final qrPainter = QrPainter(
      data: _deepLink,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(color: AppTheme.primaryGreen),
      dataModuleStyle: const QrDataModuleStyle(color: AppTheme.primaryGreen),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share Bin QR Code'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: CustomPaint(
                  size: const Size.square(220),
                  painter: qrPainter,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan to join this bin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _deepLink));
              Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              }
            },
            child: const Text('Copy Link'),
          ),
          TextButton.icon(
            onPressed: () async {
              try {
                final tempDir = await Directory.systemTemp.createTemp();
                final file = File('${tempDir.path}/bin_qr_${widget.binId}.png');
                final picData = await qrPainter.toImageData(220, format: ui.ImageByteFormat.png);
                if (picData != null) {
                  await file.writeAsBytes(picData.buffer.asUint8List());
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Scan to join this bin!');
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to generate QR code image')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save QR code: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Save/Share QR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogDetail(Map<String, dynamic> activity) async {
    final image = activity['image'];
    final profile = activity['profiles'] as Map<String, dynamic>?;
    final name =
        '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
    await showDialog(
      context: context,
      builder: (context) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name.isNotEmpty) Text('Posted by: $name'),
            if (activity['temperature'] != null)
              Text('Temperature: ${activity['temperature']}°C'),
            if (activity['moisture'] != null)
              Text('Moisture: ${activity['moisture']}'),
            if ((activity['content'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(activity['content']),
            ],
            if (image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: image is List ? image.first : image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        );

        final hasImage = image != null;

        return AlertDialog(
          title: Text(activity['type'] ?? 'Activity'),
          content: hasImage
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SingleChildScrollView(child: content),
                )
              : content,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAdminPanel(BuildContext context) async {
    if (!_isOwner) return;

    List<Map<String, dynamic>> members = [];
    List<Map<String, dynamic>> pendingRequests = [];
    bool isLoading = true;
    String? error;

    // Load data
    try {
      members = await _binService.getBinMembers(widget.binId);
      pendingRequests = await _binService.getPendingRequests(widget.binId);
      isLoading = false;
    } catch (e) {
      error = e.toString();
      isLoading = false;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> refreshData() async {
            setSheetState(() => isLoading = true);
            try {
              final newMembers = await _binService.getBinMembers(widget.binId);
              final newRequests =
                  await _binService.getPendingRequests(widget.binId);
              setSheetState(() {
                members = newMembers;
                pendingRequests = newRequests;
                isLoading = false;
                error = null;
              });
            } catch (e) {
              setSheetState(() {
                error = e.toString();
                isLoading = false;
              });
            }
          }

          Future<void> handleApprove(String requestId) async {
            try {
              await _binService.approveRequest(requestId);
              await refreshData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request approved!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to approve: $e')),
                );
              }
            }
          }

          Future<void> handleReject(String requestId) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reject Request'),
                content:
                    const Text('Are you sure you want to reject this request?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;

            try {
              await _binService.rejectRequest(requestId);
              await refreshData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request rejected')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to reject: $e')),
                );
              }
            }
          }

          Future<void> handleRemoveMember(
              String memberUserId, String memberName) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove Member'),
                content: Text(
                    'Are you sure you want to remove $memberName from this bin?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;

            try {
              await _binService.removeMember(widget.binId, memberUserId);
              await refreshData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member removed')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to remove member: $e')),
                );
              }
            }
          }

          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Manage Bin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Content
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Error: $error',
                                          style: const TextStyle(
                                              color: Colors.red)),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: refreshData,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : DefaultTabController(
                                length: 2,
                                child: Column(
                                  children: [
                                    Consumer<NotificationService>(
                                      builder: (context, notificationService, _) {
                                        return FutureBuilder<int>(
                                          future: notificationService.getUnreadJoinRequestCountForBin(widget.binId),
                                          builder: (context, snapshot) {
                                            final unreadCount = snapshot.data ?? 0;
                                            
                                            return TabBar(
                                              tabs: [
                                                const Tab(text: 'Members'),
                                                Tab(
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Text('Requests'),
                                                      if (unreadCount > 0) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.error,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          constraints: const BoxConstraints(
                                                            minWidth: 16,
                                                            minHeight: 16,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          // Members Tab
                                          members.isEmpty
                                              ? const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(32),
                                                    child:
                                                        Text('No members yet.'),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  itemCount: members.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final member =
                                                        members[index];
                                                    final profile =
                                                        member['profiles']
                                                            as Map<String,
                                                                dynamic>?;
                                                    final firstName = profile?[
                                                            'first_name'] ??
                                                        '';
                                                    final lastName =
                                                        profile?['last_name'] ??
                                                            '';
                                                    final memberName =
                                                        '$firstName $lastName'
                                                            .trim();
                                                    final memberUserId =
                                                        member['user_id']
                                                            as String;
                                                    final isOwner =
                                                        _bin?['user_id'] ==
                                                            memberUserId;

                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      child: ListTile(
                                                        title: Text(memberName
                                                                .isEmpty
                                                            ? 'User ${memberUserId.substring(0, 8)}...'
                                                            : memberName),
                                                        subtitle: memberName
                                                                .isEmpty
                                                            ? Text(
                                                                'User ID: ${memberUserId.substring(0, 8)}...',
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            12))
                                                            : null,
                                                        trailing: isOwner
                                                            ? Chip(
                                                                label:
                                                                    const Text(
                                                                        'Owner'),
                                                                backgroundColor:
                                                                    AppTheme
                                                                        .primaryGreenLight,
                                                              )
                                                            : IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .remove_circle,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: () =>
                                                                    handleRemoveMember(
                                                                        memberUserId,
                                                                        memberName),
                                                                tooltip:
                                                                    'Remove member',
                                                              ),
                                                      ),
                                                    );
                                                  },
                                                ),

                                          // Requests Tab
                                          Builder(
                                            builder: (context) {
                                              // Clear join request badges when viewing requests tab
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                final notificationService = Provider.of<NotificationService>(context, listen: false);
                                                notificationService.markAsRead(
                                                  type: 'join_request',
                                                  binId: widget.binId,
                                                );
                                              });
                                              
                                              return pendingRequests.isEmpty
                                                  ? const Center(
                                                      child: Padding(
                                                        padding: EdgeInsets.all(32),
                                                        child: Text(
                                                            'No pending requests.'),
                                                      ),
                                                    )
                                                  : ListView.builder(
                                                      padding:
                                                          const EdgeInsets.all(16),
                                                      itemCount:
                                                          pendingRequests.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final request =
                                                            pendingRequests[index];
                                                    final profile =
                                                        request['profiles']
                                                            as Map<String,
                                                                dynamic>?;
                                                    final firstName = profile?[
                                                            'first_name'] ??
                                                        '';
                                                    final lastName =
                                                        profile?['last_name'] ??
                                                            '';
                                                    final requesterName =
                                                        '$firstName $lastName'
                                                            .trim();
                                                    final requestId =
                                                        request['id'] as String;
                                                    final userId =
                                                        request['user_id']
                                                            as String;

                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      child: ListTile(
                                                        title: Text(requesterName
                                                                .isEmpty
                                                            ? 'User ${userId.substring(0, 8)}...'
                                                            : requesterName),
                                                        subtitle: requesterName
                                                                .isEmpty
                                                            ? Text(
                                                                'User ID: ${userId.substring(0, 8)}...',
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            12))
                                                            : null,
                                                        trailing: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  color: AppTheme
                                                                      .primaryGreen),
                                                              onPressed: () =>
                                                                  handleApprove(
                                                                      requestId),
                                                              tooltip:
                                                                  'Approve',
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.cancel,
                                                                  color: Colors
                                                                      .red),
                                                              onPressed: () =>
                                                                  handleReject(
                                                                      requestId),
                                                              tooltip: 'Reject',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showHelpSheet() async {
    final descController = TextEditingController();
    String urgency = 'Normal';
    String effort = 'Medium';
    bool timeSensitive = false;
    DateTime? dueDate;
    bool isSubmitting = false;
    String? errorText;
    
    // Capture parent context for use after sheet is closed
    final parentContext = context;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> submit() async {
                if (descController.text.trim().isEmpty) {
                  setSheetState(
                      () => errorText = 'Please describe the help you need.');
                  return;
                }
                setSheetState(() {
                  isSubmitting = true;
                  errorText = null;
                });
                try {
                  await _taskService.createTask(
                    binId: widget.binId,
                    description: descController.text.trim(),
                    urgency: urgency,
                    effort: effort,
                    isTimeSensitive: timeSensitive,
                    dueDate: timeSensitive && dueDate != null
                        ? dueDate!.toIso8601String()
                        : null,
                  );
                  
                  // Close the bottom sheet first
                  Navigator.pop(sheetContext);
                  
                  // Wait for next frame to ensure sheet animation starts before showing dialog
                  // This prevents keyboard animation conflicts
                  await Future.delayed(const Duration(milliseconds: 200));
                  
                  // Show dialog with option to go to Tasks
                  final goToTasks = await showDialog<bool>(
                    context: parentContext,
                    barrierDismissible: true,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Help Request Posted!'),
                      content: const Text(
                        'Your help request has been posted successfully. Would you like to view it in the Tasks page?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Stay Here'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Go to Tasks'),
                        ),
                      ],
                    ),
                  );
                  
                  // If user wants to go to Tasks, navigate directly to main with Tasks tab
                  if (goToTasks == true) {
                    // Use go() to navigate directly to Tasks page, clearing navigation stack
                    // This ensures no back button appears and goes straight to Tasks tab
                    if (parentContext.mounted) {
                      parentContext.go('/main?tab=tasks');
                    }
                  } else {
                    // Show success message if staying
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Help request posted'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  // Only update state if sheet is still open
                  if (Navigator.canPop(sheetContext)) {
                    setSheetState(() {
                      errorText = e.toString();
                      isSubmitting = false;
                    });
                  } else {
                    // Sheet was closed, show error in snackbar instead
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to post request: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ask for Help',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'How can the community help?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Urgency'),
                  Wrap(
                    spacing: 8,
                    children: ['Low', 'Normal', 'High']
                        .map(
                          (u) => ChoiceChip(
                            label: Text(u),
                            selected: urgency == u,
                            onSelected: (_) {
                              setSheetState(() => urgency = u);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Effort required'),
                  Wrap(
                    spacing: 8,
                    children: ['Low', 'Medium', 'High']
                        .map(
                          (e) => ChoiceChip(
                            label: Text(e),
                            selected: effort == e,
                            onSelected: (_) {
                              setSheetState(() => effort = e);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Time sensitive?'),
                    value: timeSensitive,
                    onChanged: (val) {
                      setSheetState(() {
                        timeSensitive = val;
                        if (!val) dueDate = null;
                      });
                    },
                  ),
                  if (timeSensitive)
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setSheetState(() => dueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        dueDate == null
                            ? 'Pick due date'
                            : DateFormat.yMMMMd().format(dueDate!),
                      ),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post Request'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CompostLoadingAnimation(
            message: 'Loading bin details...',
          ),
        ),
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

    final rawImage = (_bin!['image'] as String?)?.trim();
    final hasCustomImage = _hasCustomImage(rawImage);
    final binImage = hasCustomImage ? rawImage! : _defaultBinImage;

    return WillPopScope(
      onWillPop: () async {
        _popWithResult();
        return false;
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: binImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.image, size: 64),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.backgroundGray,
                        child: const Icon(Icons.eco,
                            size: 64, color: AppTheme.primaryGreen),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _popWithResult,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Consumer<NotificationService>(
                      builder: (context, notificationService, _) {
                        return FutureBuilder<int>(
                          future: notificationService.getUnreadMessageCountForBin(widget.binId),
                          builder: (context, snapshot) {
                            final unreadCount = snapshot.data ?? 0;
                            
                            return NotificationBadge(
                              count: unreadCount,
                              child: IconButton(
                                icon: const Icon(Icons.chat, color: Colors.white),
                                onPressed: () {
                                  // Clear message badges when opening chat
                                  notificationService.markAsRead(
                                    type: 'message',
                                    binId: widget.binId,
                                  );
                                  // Admin goes to chat list, normal users go directly to chat
                                  if (_isOwner) {
                                    context.push('/bin/${widget.binId}/chat');
                                  } else {
                                    context.push('/bin/${widget.binId}/chat');
                                  }
                                },
                                tooltip: _isOwner ? 'View Messages' : 'Chat with Admin',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                if (_isOwner)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Consumer<NotificationService>(
                        builder: (context, notificationService, _) {
                          return NotificationBadge(
                            count: notificationService.unreadJoinRequests,
                            child: IconButton(
                              icon: const Icon(Icons.admin_panel_settings,
                                  color: Colors.white),
                              onPressed: () {
                                // Clear join request badges when opening admin panel
                                notificationService.markAsRead(
                                  type: 'join_request',
                                  binId: widget.binId,
                                );
                                _showAdminPanel(context);
                              },
                              tooltip: 'Manage Bin',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'share') _shareBin();
                        if (value == 'qr') _showQrCodeDialog();
                        if (value == 'photo' && _isOwner) _changePhoto();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Share'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'qr',
                          child: ListTile(
                            leading: Icon(Icons.qr_code),
                            title: Text('QR Code'),
                          ),
                        ),
                        if (_isOwner)
                          const PopupMenuItem(
                            value: 'photo',
                            child: ListTile(
                              leading: Icon(Icons.photo_library),
                              title: Text('Edit Image'),
                            ),
                          ),
                      ],
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                    if (_getAgeText(_bin!['created_at'] as String?).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getAgeText(_bin!['created_at'] as String?),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Bin Status Section
                    _buildBinStatusSection(),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value:
                                temperature != null ? '$temperature°C' : '-°C',
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

            // Action buttons - Sticky
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyButtonsDelegate(
                child: SizedBox(
                  height: 108,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Builder(
                              builder: (context) {
                                final binStatus = _bin?['bin_status'] as String? ?? 'active';
                                // Disable button only when matured (no actions allowed)
                                final isDisabled = binStatus == 'matured';
                                
                                return Opacity(
                                  opacity: isDisabled ? 0.5 : 1.0,
                                  child: ElevatedButton.icon(
                                    onPressed: isDisabled ? () {
                                      // Show message even when disabled
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Bin is matured. No actions allowed.'),
                                        ),
                                      );
                                    } : () async {
                                      // For matured bins, this shouldn't be called (button is disabled)
                                      // For resting bins, allow opening the log screen (only Turn Pile will be available)
                                      final result =
                                          await context.push('/bin/${widget.binId}/log');
                                      if (result == true) {
                                        _hasUpdates = true;
                                        _loadBin();
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Log Activity'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showHelpSheet,
                              icon: const Text('💪', style: TextStyle(fontSize: 16)),
                              label: const Text('Ask for Help'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Leaderboard
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BinLeaderboardWidget(
                  key: ValueKey('leaderboard_${_activities.length}_${DateTime.now().millisecondsSinceEpoch}'),
                  binId: widget.binId,
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: const [
                        Tab(icon: Icon(Icons.timeline), text: 'Activity'),
                        Tab(icon: Icon(Icons.school), text: 'Guides'),
                      ],
                      labelColor: AppTheme.primaryGreen,
                      unselectedLabelColor: AppTheme.textGray,
                      indicatorColor: AppTheme.primaryGreen,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: TabBarView(
                        children: [
                          // Activity Tab
                          _buildActivityTab(),
                          // Guides Tab
                          _buildGuidesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Delete or Leave button
            if (_canDelete)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isDeleting ? null : _confirmDelete,
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Delete Bin'),
                  ),
                ),
              )
            else if (!_isOwner) // Member but not owner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700, width: 2),
                    ),
                    onPressed: _isDeleting ? null : _confirmLeave,
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Leave Bin'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
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
            ..._activities.take(_logsToShow).map(
                  (activity) => ActivityTimelineItem(
                    activity: activity,
                    onTap: () => _showLogDetail(activity),
                  ),
                ),
          if (_activities.length > _logsToShow)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _logsToShow += 7;
                  });
                },
                child: Text(
                    'Load ${_activities.length - _logsToShow} more logs'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    return _BinFoodWasteGuideContent(
      binId: widget.binId,
      isOwner: _isOwner,
    );
  }
}

// Delegate for sticky buttons
class _StickyButtonsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyButtonsDelegate({required this.child});

  @override
  double get minExtent => 108; // Minimum height: 2 buttons (48px each) + spacing (6px) + padding (8px) = 110px, but use 108 for safety

  @override
  double get maxExtent => 108; // Maximum height

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: BoxConstraints(
        minHeight: minExtent,
        maxHeight: maxExtent,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyButtonsDelegate oldDelegate) {
    return child != oldDelegate.child;
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

// Wrapper widget that extracts just the body content from BinFoodWasteGuideScreen
class _BinFoodWasteGuideContent extends StatefulWidget {
  final String binId;
  final bool isOwner;

  const _BinFoodWasteGuideContent({
    required this.binId,
    required this.isOwner,
  });

  @override
  State<_BinFoodWasteGuideContent> createState() =>
      _BinFoodWasteGuideContentState();
}

class _BinFoodWasteGuideContentState extends State<_BinFoodWasteGuideContent> {
  final EducationalService _educationalService = EducationalService();
  final TextEditingController _newCanAddController = TextEditingController();
  final TextEditingController _newCannotAddController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _guide;
  bool _isLoading = true;
  String? _error;
  List<String> _canAddItems = [];
  List<String> _cannotAddItems = [];

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  @override
  void dispose() {
    _newCanAddController.dispose();
    _newCannotAddController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGuide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guide =
          await _educationalService.getBinFoodWasteGuide(widget.binId);
      if (mounted) {
        setState(() {
          _guide = guide;
          if (guide != null) {
            _canAddItems = List<String>.from(guide['can_add'] as List? ?? []);
            _cannotAddItems =
                List<String>.from(guide['cannot_add'] as List? ?? []);
            _notesController.text = guide['notes'] as String? ?? '';
          } else {
            _canAddItems = [];
            _cannotAddItems = [];
            _notesController.text = '';
          }
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

  Future<void> _saveGuide() async {
    if (!widget.isOwner) return;

    setState(() {
      _error = null;
    });

    try {
      await _educationalService.upsertBinFoodWasteGuide(
        binId: widget.binId,
        canAdd: _canAddItems,
        cannotAdd: _cannotAddItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food waste guidelines updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _newCanAddController.clear();
        _newCannotAddController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCanAddItem() {
    final item = _newCanAddController.text.trim();
    if (item.isNotEmpty && !_canAddItems.contains(item)) {
      // Check if item exists in "cannot add" list before adding
      final wasInCannotAdd = _cannotAddItems.contains(item);
      
      setState(() {
        // Remove from "cannot add" list if it exists there
        if (wasInCannotAdd) {
          _cannotAddItems.remove(item);
        }
        // Add to "can add" list
        _canAddItems.add(item);
        _newCanAddController.clear();
      });
      _saveGuide();
      
      // Show message if item was moved from "cannot add" to "can add"
      if (wasInCannotAdd && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$item" moved from "Cannot Add" to "Can Add"'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _addCannotAddItem() {
    final item = _newCannotAddController.text.trim();
    if (item.isNotEmpty && !_cannotAddItems.contains(item)) {
      // Check if item exists in "can add" list before adding
      final wasInCanAdd = _canAddItems.contains(item);
      
      setState(() {
        // Remove from "can add" list if it exists there
        if (wasInCanAdd) {
          _canAddItems.remove(item);
        }
        // Add to "cannot add" list
        _cannotAddItems.add(item);
        _newCannotAddController.clear();
      });
      _saveGuide();
      
      // Show message if item was moved from "can add" to "cannot add"
      if (wasInCanAdd && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$item" moved from "Can Add" to "Cannot Add"'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeCanAddItem(String item) {
    setState(() {
      _canAddItems.remove(item);
    });
    _saveGuide();
  }

  void _removeCannotAddItem(String item) {
    setState(() {
      _cannotAddItems.remove(item);
    });
    _saveGuide();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGuide,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadGuide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_guide == null && !widget.isOwner)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No food waste guidelines set for this bin yet.',
                              style: TextStyle(color: AppTheme.textGray),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else ...[
                        // Can Add Section
                        Card(
                          color: widget.isOwner
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: widget.isOwner
                                            ? Colors.green
                                            : Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Can Add',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isOwner
                                            ? Colors.green
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (widget.isOwner)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _newCanAddController,
                                          decoration: InputDecoration(
                                            hintText: 'Add new item...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          onSubmitted: (_) => _addCanAddItem(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _addCanAddItem,
                                        icon: Icon(Icons.add_circle,
                                            color: widget.isOwner
                                                ? Colors.green
                                                : Colors.black87),
                                        tooltip: 'Add item',
                                      ),
                                    ],
                                  ),
                                if (widget.isOwner && _canAddItems.isNotEmpty)
                                  const SizedBox(height: 12),
                                if (_canAddItems.isEmpty)
                                  const Text(
                                    'No items specified yet.',
                                    style: TextStyle(color: AppTheme.textGray),
                                  )
                                else
                                  ..._canAddItems.map((item) => _GuideItemTile(
                                        item: item,
                                        color: widget.isOwner
                                            ? Colors.green
                                            : Colors.black87,
                                        isOwner: widget.isOwner,
                                        isCanAdd: true,
                                        onDelete: widget.isOwner
                                            ? () => _removeCanAddItem(item)
                                            : null,
                                      )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cannot Add Section
                        Card(
                          color: widget.isOwner
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.cancel,
                                        color: widget.isOwner
                                            ? Colors.red
                                            : Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cannot Add',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isOwner
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (widget.isOwner)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _newCannotAddController,
                                          decoration: InputDecoration(
                                            hintText: 'Add new item...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          onSubmitted: (_) =>
                                              _addCannotAddItem(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _addCannotAddItem,
                                        icon: Icon(Icons.add_circle,
                                            color: widget.isOwner
                                                ? Colors.red
                                                : Colors.black87),
                                        tooltip: 'Add item',
                                      ),
                                    ],
                                  ),
                                if (widget.isOwner &&
                                    _cannotAddItems.isNotEmpty)
                                  const SizedBox(height: 12),
                                if (_cannotAddItems.isEmpty)
                                  const Text(
                                    'No items specified yet.',
                                    style: TextStyle(color: AppTheme.textGray),
                                  )
                                else
                                  ..._cannotAddItems
                                      .map((item) => _GuideItemTile(
                                            item: item,
                                            color: widget.isOwner
                                                ? Colors.red
                                                : Colors.black87,
                                            isOwner: widget.isOwner,
                                            isCanAdd: false,
                                            onDelete: widget.isOwner
                                                ? () =>
                                                    _removeCannotAddItem(item)
                                                : null,
                                          )),
                              ],
                            ),
                          ),
                        ),
                        if (_guide?['notes'] != null || widget.isOwner) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Additional Notes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  widget.isOwner
                                      ? TextField(
                                          controller: _notesController,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Add any additional notes...',
                                            border: OutlineInputBorder(),
                                          ),
                                          maxLines: 5,
                                          onChanged: (_) => _saveGuide(),
                                        )
                                      : Text(
                                          _guide?['notes'] as String? ?? '',
                                          style: const TextStyle(
                                              color: AppTheme.textGray),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (widget.isOwner &&
                            _guide == null &&
                            _canAddItems.isEmpty &&
                            _cannotAddItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(Icons.info_outline,
                                      size: 48, color: AppTheme.textGray),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No guidelines set yet. Start by adding items above.',
                                    style: TextStyle(color: AppTheme.textGray),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
  }
}

class _GuideItemTile extends StatelessWidget {
  final String item;
  final Color color;
  final bool isOwner;
  final bool isCanAdd;
  final VoidCallback? onDelete;

  const _GuideItemTile({
    required this.item,
    required this.color,
    required this.isOwner,
    required this.isCanAdd,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // For normal users, use black/white/gray colors
    final displayColor = isOwner ? color : Colors.black87;
    final backgroundColor = isOwner
        ? color.withOpacity(0.1)
        : Colors.grey.shade100;
    final borderColor = isOwner
        ? color.withOpacity(0.3)
        : Colors.grey.shade300;
    final textColor = isOwner
        ? (color == Colors.green
            ? Colors.green.shade700
            : Colors.red.shade700)
        : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isCanAdd
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: displayColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              onPressed: onDelete,
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
