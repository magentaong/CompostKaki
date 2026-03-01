import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bin_service.dart';
import '../../services/task_service.dart';
import '../../widgets/xp_floating_animation.dart';
import '../../theme/app_theme.dart';
import 'dart:io';

class _ActivityDraft {
  final String type;
  final String content;
  final int? temperature;
  final String? moisture;
  final double? weight;
  final File? imageFile;
  final List<String> missingMaterials;
  final Map<String, String?> missingReasons;
  final bool createTaskForMissing;
  final String taskTitleInput;
  final String missingDetailsInput;

  const _ActivityDraft({
    required this.type,
    required this.content,
    required this.temperature,
    required this.moisture,
    required this.weight,
    required this.imageFile,
    required this.missingMaterials,
    required this.missingReasons,
    required this.createTaskForMissing,
    required this.taskTitleInput,
    required this.missingDetailsInput,
  });
}

class _DraftSubmitResult {
  final int xpGained;

  const _DraftSubmitResult({required this.xpGained});
}

class LogActivityScreen extends StatefulWidget {
  final String binId;

  const LogActivityScreen({super.key, required this.binId});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final BinService _binService = BinService();
  final TaskService _taskService = TaskService();
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();
  final _taskTitleController = TextEditingController();
  final _missingDetailsController = TextEditingController();

  String? _selectedType;
  String? _selectedMoisture;
  Map<String, bool> _materials = {
    'greens': true,
    'browns': true,
    'water': true,
  };
  final Map<String, String?> _missingReasons = {
    'greens': null,
    'browns': null,
    'water': null,
  };
  File? _imageFile;
  bool _isLoading = false;
  bool _isBatchMode = false;
  String? _error;
  String _binName = 'Bin';
  Map<String, dynamic>? _bin;
  final List<_ActivityDraft> _queuedActivities = [];

  final List<String> _moistureOptions = [
    'Very Dry',
    'Dry',
    'Perfect',
    'Wet',
    'Very Wet',
  ];
  final Map<String, List<String>> _missingReasonOptions = const {
    'greens': [
      'No more greens available right now',
      'Kitchen scraps ran out today',
      'Need fresh greens collection support',
      'Greens quality is not suitable today',
    ],
    'browns': [
      'No dry leaves/cardboard available now',
      'Stored browns are finished',
      'Need more carbon-rich materials',
      'Browns are too wet to use',
    ],
    'water': [
      'No water source nearby at the moment',
      'Watering tool is unavailable',
      'Need help bringing water to the bin',
      'Weather conditions prevented watering',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadBinName();
  }

  Future<void> _loadBinName() async {
    try {
      final bin = await _binService.getBin(widget.binId);
      if (mounted) {
        setState(() {
          _bin = bin;
          _binName = bin['name'] as String? ?? 'Bin';
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  List<String> get _allowedActivityTypes {
    if (_bin == null) {
      return ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
    }

    final status = _bin!['bin_status'] as String? ?? 'active';

    if (status == 'resting') {
      // Only allow flipping when resting
      return ['Turn Pile'];
    }

    if (status == 'matured') {
      // No actions allowed when matured
      return [];
    }

    // Active - all actions allowed
    return ['Turn Pile', 'Add Materials', 'Add Water', 'Monitor'];
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      if (type == 'Turn Pile') {
        _contentController.text = 'Turned the pile';
      } else if (type == 'Add Materials') {
        _materials = {
          'greens': true,
          'browns': true,
          'water': true,
        };
        _missingReasons.updateAll((key, value) => null);
        _taskTitleController.clear();
        _missingDetailsController.clear();
        _updateAddMaterialsContent();
      } else if (type == 'Add Water') {
        _contentController.text = 'Added water to the bin';
      } else if (type == 'Monitor') {
        _contentController.text = 'Checked status';
      }
    });
  }

  void _updateAddMaterialsContent() {
    final added = <String>[];
    if (_materials['greens'] == true) added.add('greens');
    if (_materials['browns'] == true) added.add('browns');
    if (_materials['water'] == true) added.add('water');

    if (added.isEmpty) {
      _contentController.text = 'No materials were added.';
      return;
    }

    if (added.length == 1) {
      _contentController.text = 'Added materials: ${added.first}';
      return;
    }

    final last = added.removeLast();
    _contentController.text = 'Added materials: ${added.join(', ')} and $last';
  }

  List<String> get _missingMaterials => _materials.entries
      .where((entry) => entry.value == false)
      .map((entry) => entry.key)
      .toList();

  String _materialLabel(String key) {
    switch (key) {
      case 'greens':
        return 'Greens';
      case 'browns':
        return 'Browns';
      case 'water':
        return 'Water';
      default:
        return key;
    }
  }

  bool _hasRequiredMissingReasons() {
    final missing = _missingMaterials;
    return missing.every(
      (material) => (_missingReasons[material] ?? '').trim().isNotEmpty,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  bool _canSubmit() {
    if (_selectedType == null) return false;
    if (_selectedType == 'Add Materials') {
      if (_materials.values.every((v) => v)) return true;
      return _hasRequiredMissingReasons();
    }
    if (_selectedType == 'Monitor') {
      return _temperatureController.text.isNotEmpty &&
          _selectedMoisture != null;
    }
    return true;
  }

  Future<bool> _askCreateTaskForMissingMaterials(List<String> missing) async {
    final selected = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Missing Materials'),
        content: Text(
          'You are missing ${missing.length} material(s): ${missing.map(_materialLabel).join(', ')}.\n\nDo you want to create a task for help and continue logging?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Log Only'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Task + Log'),
          ),
        ],
      ),
    );

    return selected ?? false;
  }

  Future<void> _createMissingMaterialsTask({
    required List<String> missing,
    required Map<String, String?> reasonMap,
    required String taskTitleInput,
    required String missingDetailsInput,
  }) async {
    final firstSelectedReason = missing
        .map((material) => (reasonMap[material] ?? '').trim())
        .firstWhere((reason) => reason.isNotEmpty, orElse: () => '');
    final generatedTitle = firstSelectedReason.isNotEmpty
        ? firstSelectedReason
        : 'Need help getting ${missing.map(_materialLabel).join(", ").toLowerCase()}';
    final title =
        taskTitleInput.trim().isEmpty ? generatedTitle : taskTitleInput.trim();

    final contextLines = missing
        .map(
            (material) => '${_materialLabel(material)}: ${reasonMap[material]}')
        .toList();
    final extraDetails = missingDetailsInput.trim();
    if (extraDetails.isNotEmpty) {
      contextLines.add('Context: $extraDetails');
    }
    final detailBlock = contextLines.map((line) => '- $line').join('\n');
    final description = '$title\n\nAdditional detail\n$detailBlock';

    final urgency = missing.length >= 2 ? 'High' : 'Normal';
    final effort = missing.length >= 2 ? 'High' : 'Medium';

    await _taskService.createTask(
      binId: widget.binId,
      description: description,
      urgency: urgency,
      effort: effort,
    );
  }

  Future<_ActivityDraft?> _buildDraftFromCurrent() async {
    if (!_canSubmit() || !_formKey.currentState!.validate()) return null;

    bool shouldCreateTask = false;
    final missing = _selectedType == 'Add Materials'
        ? List<String>.from(_missingMaterials)
        : <String>[];
    if (_selectedType == 'Add Materials' && missing.isNotEmpty) {
      if (!_hasRequiredMissingReasons()) {
        setState(() {
          _error = 'Please select a reason for each unchecked material.';
        });
        return null;
      }
      shouldCreateTask = await _askCreateTaskForMissingMaterials(missing);
    }

    return _ActivityDraft(
      type: _selectedType!,
      content: _contentController.text.trim(),
      temperature: _temperatureController.text.isNotEmpty
          ? int.tryParse(_temperatureController.text)
          : null,
      moisture: _selectedMoisture,
      weight: _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      imageFile: _imageFile,
      missingMaterials: missing,
      missingReasons: Map<String, String?>.from(_missingReasons),
      createTaskForMissing: shouldCreateTask,
      taskTitleInput: _taskTitleController.text,
      missingDetailsInput: _missingDetailsController.text,
    );
  }

  void _resetForAnotherActivity() {
    setState(() {
      _selectedType = null;
      _selectedMoisture = null;
      _contentController.clear();
      _temperatureController.clear();
      _weightController.clear();
      _taskTitleController.clear();
      _missingDetailsController.clear();
      _materials = {
        'greens': true,
        'browns': true,
        'water': true,
      };
      _missingReasons.updateAll((key, value) => null);
      _imageFile = null;
      _error = null;
      _isLoading = false;
    });
  }

  Future<bool> _askLogAnother({required int count}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activity Logged'),
        content: Text(
          count == 1
              ? 'Your activity was logged successfully.\n\nDo you want to log another activity?'
              : '$count activities were logged successfully.\n\nDo you want to log another activity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Another'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<_DraftSubmitResult> _submitDraft(
    _ActivityDraft draft, {
    required bool showXpAnimation,
  }) async {
    String? imageUrl;
    if (draft.imageFile != null) {
      final imageExists = await draft.imageFile!.exists();
      if (!imageExists) {
        throw Exception(
          'An attached photo could not be found anymore. Please re-attach the photo and try again.',
        );
      }
      imageUrl =
          await _binService.uploadLogImage(draft.imageFile!, widget.binId);
    }

    if (draft.createTaskForMissing && draft.missingMaterials.isNotEmpty) {
      await _createMissingMaterialsTask(
        missing: draft.missingMaterials,
        reasonMap: draft.missingReasons,
        taskTitleInput: draft.taskTitleInput,
        missingDetailsInput: draft.missingDetailsInput,
      );
    }

    final xpResult = await _binService.createBinLog(
      binId: widget.binId,
      type: draft.type,
      content: draft.content,
      temperature: draft.temperature,
      moisture: draft.moisture,
      weight: draft.weight,
      image: imageUrl,
    );

    if (xpResult == null) {
      return const _DraftSubmitResult(xpGained: 0);
    }

    final baseXP = draft.type.toLowerCase().contains('turn') ? 15 : 10;
    final bonusXP = (xpResult['bonusXP'] as int?) ?? 0;
    final xpGained = baseXP + bonusXP;
    final isLevelUp = (xpResult['levelUp'] as bool?) ?? false;

    if (!showXpAnimation || !mounted) {
      return _DraftSubmitResult(xpGained: xpGained);
    }

    if (xpGained > 0) {
      showXPFloatingAnimation(
        context,
        xpAmount: xpGained,
        isLevelUp: isLevelUp,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    return _DraftSubmitResult(xpGained: xpGained);
  }

  Future<void> _addCurrentToQueue() async {
    final draft = await _buildDraftFromCurrent();
    if (draft == null) return;

    if (!mounted) return;
    setState(() {
      _queuedActivities.add(draft);
      _error = null;
    });
    _resetForAnotherActivity();
  }

  Future<void> _submitBatch() async {
    if (_queuedActivities.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    int successCount = 0;
    int totalXpGained = 0;
    final failedDrafts = <_ActivityDraft>[];
    final failureMessages = <String>[];

    for (final draft in List<_ActivityDraft>.from(_queuedActivities)) {
      try {
        final result = await _submitDraft(draft, showXpAnimation: false);
        successCount += 1;
        totalXpGained += result.xpGained;
      } catch (e) {
        failedDrafts.add(draft);
        failureMessages.add(
            '${draft.type}: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }

    if (!mounted) return;

    setState(() {
      _queuedActivities
        ..clear()
        ..addAll(failedDrafts);
      _isLoading = false;
    });

    if (failedDrafts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount logged, ${failedDrafts.length} failed. You can retry failed items.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _error = failureMessages.isNotEmpty ? failureMessages.join('\n') : null;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$successCount activities logged successfully (+$totalXpGained XP).',
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );

    final shouldLogAnother = await _askLogAnother(count: successCount);
    if (!mounted) return;
    if (shouldLogAnother) {
      _resetForAnotherActivity();
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _submit() async {
    final draft = await _buildDraftFromCurrent();
    if (draft == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _submitDraft(draft, showXpAnimation: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activity logged (+${result.xpGained} XP).'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      final shouldLogAnother = await _askLogAnother(count: 1);
      if (!mounted) return;

      if (shouldLogAnother) {
        _resetForAnotherActivity();
      } else {
        Navigator.pop(context, true);
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

  @override
  void dispose() {
    _contentController.dispose();
    _temperatureController.dispose();
    _weightController.dispose();
    _taskTitleController.dispose();
    _missingDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_binName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show status warning if needed
              if (_bin != null)
                Builder(
                  builder: (context) {
                    final status = _bin!['bin_status'] as String? ?? 'active';
                    if (status == 'matured') {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purple[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bin is matured. No actions allowed.',
                                style: TextStyle(color: Colors.purple[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (status == 'resting') {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bedtime, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bin is resting. Only flipping is allowed.',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              if (_bin != null) const SizedBox(height: 16),
              const Text(
                'Logging Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Single'),
                    selected: !_isBatchMode,
                    onSelected: _isLoading
                        ? null
                        : (_) {
                            setState(() {
                              _isBatchMode = false;
                            });
                          },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Multiple (${_queuedActivities.length})'),
                    selected: _isBatchMode,
                    onSelected: _isLoading
                        ? null
                        : (_) {
                            setState(() {
                              _isBatchMode = true;
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              _allowedActivityTypes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child:
                            Text('No actions available for this bin status.'),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: _allowedActivityTypes.map((type) {
                        IconData icon;
                        switch (type) {
                          case 'Add Materials':
                            icon = Icons.eco;
                            break;
                          case 'Add Water':
                            icon = Icons.water_drop;
                            break;
                          case 'Turn Pile':
                            icon = Icons.refresh;
                            break;
                          case 'Monitor':
                            icon = Icons.thermostat;
                            break;
                          default:
                            icon = Icons.info;
                        }
                        return _ActionButton(
                          label: type,
                          icon: icon,
                          isSelected: _selectedType == type,
                          onTap: () => _selectType(type),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              if (_isBatchMode && _queuedActivities.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Queued Activities',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._queuedActivities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final draft = entry.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.primaryGreenLight,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(draft.type),
                          subtitle: Text(
                            draft.content.isEmpty
                                ? 'No details'
                                : draft.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _queuedActivities.removeAt(index);
                                    });
                                  },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Materials checkboxes
              if (_selectedType == 'Add Materials') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'I have added the following:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text(
                            'Greens (e.g. fresh leaves, compostable food waste)'),
                        value: _materials['greens'],
                        onChanged: (value) {
                          setState(() {
                            _materials['greens'] = value ?? false;
                            if (_materials['greens'] == true) {
                              _missingReasons['greens'] = null;
                            } else {
                              _missingReasons['greens'] ??=
                                  _missingReasonOptions['greens']!.first;
                            }
                            _updateAddMaterialsContent();
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      CheckboxListTile(
                        title: const Text('Browns (e.g. dry leaves)'),
                        value: _materials['browns'],
                        onChanged: (value) {
                          setState(() {
                            _materials['browns'] = value ?? false;
                            if (_materials['browns'] == true) {
                              _missingReasons['browns'] = null;
                            } else {
                              _missingReasons['browns'] ??=
                                  _missingReasonOptions['browns']!.first;
                            }
                            _updateAddMaterialsContent();
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      CheckboxListTile(
                        title: const Text('Water'),
                        value: _materials['water'],
                        onChanged: (value) {
                          setState(() {
                            _materials['water'] = value ?? false;
                            if (_materials['water'] == true) {
                              _missingReasons['water'] = null;
                            } else {
                              _missingReasons['water'] ??=
                                  _missingReasonOptions['water']!.first;
                            }
                            _updateAddMaterialsContent();
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
                      if (_missingMaterials.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Explain missing items (required):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._missingMaterials.map((material) {
                          final options = _missingReasonOptions[material] ??
                              const <String>[];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownMenu<String>(
                                    initialSelection: _missingReasons[material],
                                    expandedInsets: EdgeInsets.zero,
                                    label: Text(
                                        '${_materialLabel(material)} reason'),
                                    onSelected: (value) {
                                      setState(() {
                                        _missingReasons[material] = value;
                                      });
                                    },
                                    dropdownMenuEntries: options.map((option) {
                                      return DropdownMenuEntry<String>(
                                        value: option,
                                        label: option,
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if ((_missingReasons[material] ?? '')
                                    .trim()
                                    .isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6, left: 12),
                                    child: Text(
                                      'Please select a reason',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        TextFormField(
                          controller: _taskTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Task title (optional)',
                            hintText: 'e.g. Need help getting greens',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _missingDetailsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Additional details (optional)',
                            hintText: 'Any extra context for the task...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Temperature and Moisture
              if (_selectedType == 'Monitor') ...[
                TextFormField(
                  controller: _temperatureController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (°C)',
                    prefixIcon: Icon(Icons.thermostat),
                  ),
                  onChanged: (_) {
                    // Rebuild so _canSubmit reflects temperature changes immediately.
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter temperature';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMoisture,
                  decoration: const InputDecoration(
                    labelText: 'Moisture Level',
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  items: _moistureOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMoisture = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select moisture level';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Activity Details (Optional)',
                  hintText: 'Describe what you added or did...',
                ),
                maxLines: 3,
                enabled: _selectedType != null,
              ),
              const SizedBox(height: 16),

              // Image picker
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Photo (Optional)'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              if (_isBatchMode) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isLoading || !_canSubmit() ? null : _addCurrentToQueue,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Add Activity To List'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _queuedActivities.isEmpty
                        ? null
                        : _submitBatch,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Submit All (${_queuedActivities.length})'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_canSubmit() ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log Activity'),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primaryGreen : AppTheme.primaryGreenLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.white : AppTheme.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
