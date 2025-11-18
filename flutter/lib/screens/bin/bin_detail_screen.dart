import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_timeline_item.dart';

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

  String get _binId => widget.binId;
  String get _deepLink => 'compostkaki://bin/${widget.binId}';

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

  void _popWithResult() {
    if (Navigator.of(context).canPop()) {
      context.pop(_hasUpdates);
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

  Future<void> _shareBin() async {
    final name = _bin?['name'] ?? 'our compost bin';
    final message = 'Join $name on CompostKaki!\n\nTap here to join: $_deepLink';
    await Share.share(message);
  }

  Future<void> _changePhoto() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the bin owner can update the photo.')),
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
              final tempDir = await Directory.systemTemp.createTemp();
              final file = File('${tempDir.path}/bin_qr_${widget.binId}.png');
              final picData = await qrPainter.toImageData(220);
              if (picData != null) {
                await file.writeAsBytes(picData.buffer.asUint8List());
                await Share.shareXFiles([XFile(file.path)], text: 'Scan to join this bin!');
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

  Future<void> _showHelpSheet() async {
    final descController = TextEditingController();
    String urgency = 'Normal';
    String effort = 'Medium';
    bool timeSensitive = false;
    DateTime? dueDate;
    bool isSubmitting = false;
    String? errorText;

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
                  setSheetState(() => errorText = 'Please describe the help you need.');
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
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help request posted')),
                    );
                  }
                } catch (e) {
                  setSheetState(() {
                    errorText = e.toString();
                  });
                } finally {
                  setSheetState(() => isSubmitting = false);
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
                          lastDate: DateTime.now().add(const Duration(days: 60)),
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
                      onPressed: () async {
                        final result = await context.push('/bin/${widget.binId}/log');
                        if (result == true) {
                          _loadBin();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Log Activity'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showHelpSheet,
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
                      ActivityTimelineItem(
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
                        child: Text('Load ${_activities.length - _logsToShow} more logs'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_canDelete)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete Bin'),
                ),
              ),
            ),
        ],
      ),
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

