import 'package:flutter/material.dart';
import '../../services/educational_service.dart';
import '../../theme/app_theme.dart';

class BinFoodWasteGuideScreen extends StatefulWidget {
  final String binId;
  final bool isOwner;

  const BinFoodWasteGuideScreen({
    super.key,
    required this.binId,
    required this.isOwner,
  });

  @override
  State<BinFoodWasteGuideScreen> createState() =>
      _BinFoodWasteGuideScreenState();
}

class _BinFoodWasteGuideScreenState extends State<BinFoodWasteGuideScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Waste Guidelines'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                                  // Add new item (admin only)
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
                                            onSubmitted: (_) =>
                                                _addCanAddItem(),
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
                                  // Items list
                                  if (_canAddItems.isEmpty)
                                    const Text(
                                      'No items specified yet.',
                                      style:
                                          TextStyle(color: AppTheme.textGray),
                                    )
                                  else
                                    ..._canAddItems.map((item) => _ItemTile(
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
                                  // Add new item (admin only)
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
                                  // Items list
                                  if (_cannotAddItems.isEmpty)
                                    const Text(
                                      'No items specified yet.',
                                      style:
                                          TextStyle(color: AppTheme.textGray),
                                    )
                                  else
                                    ..._cannotAddItems.map((item) => _ItemTile(
                                          item: item,
                                          color: widget.isOwner
                                              ? Colors.red
                                              : Colors.black87,
                                          isOwner: widget.isOwner,
                                          isCanAdd: false,
                                          onDelete: widget.isOwner
                                              ? () => _removeCannotAddItem(item)
                                              : null,
                                        )),
                                ],
                              ),
                            ),
                          ),
                          // Notes Section
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
                                      style:
                                          TextStyle(color: AppTheme.textGray),
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
                ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String item;
  final Color color;
  final bool isOwner;
  final bool isCanAdd;
  final VoidCallback? onDelete;

  const _ItemTile({
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
