import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';
import 'join_bin_scanner_screen.dart';

class AddBinScreen extends StatefulWidget {
  const AddBinScreen({super.key});

  @override
  State<AddBinScreen> createState() => _AddBinScreenState();
}

class _AddBinScreenState extends State<AddBinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final BinService _binService = BinService();
  bool _isLoading = false;
  String? _error;
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _showJoinExistingDialog() async {
    final controller = TextEditingController();
    String? dialogError;
    bool joining = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Join a Bin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Paste bin link or ID',
                  hintText: 'https://... or UUID',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final scanned = await Navigator.push<String?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JoinBinScannerScreen(),
                    ),
                  );
                  if (scanned != null) {
                    controller.text = scanned;
                    setState(() {
                      dialogError = null;
                    });
                  }
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Scan QR code'),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: joining ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: joining
                  ? null
                  : () async {
                      final binId = _extractBinId(controller.text);
                      if (binId == null) {
                        setState(() {
                          dialogError =
                              'Please enter a valid bin ID, link, or scan a QR code.';
                        });
                        return;
                      }
                      setState(() {
                        joining = true;
                        dialogError = null;
                      });
                      try {
                        await _binService.joinBin(binId);
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        context.go('/bin/$binId');
                      } catch (e) {
                        setState(() {
                          dialogError = e.toString();
                        });
                      } finally {
                        setState(() => joining = false);
                      }
                    },
              child: joining
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractBinId(String input) {
    final regex = RegExp(
        r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})');
    final match = regex.firstMatch(input);
    return match?.group(1);
  }

  Future<void> _createBin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newBin = await _binService.createBin(
        name: _nameController.text,
        location: _nameController.text,
      );

      if (_imageFile != null) {
        await _binService.updateBinImage(newBin['id'] as String, _imageFile!);
      }
      
      if (mounted) {
        Navigator.pop(context, newBin['id']);
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenLight,
                  border: Border.all(color: AppTheme.primaryGreen),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🪴'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'If your community already has a bin, try joining it instead!',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _showJoinExistingDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Join Bin'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Add New Bin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Name your bin after its location, e.g., Dakota Crescent',
                style: TextStyle(color: AppTheme.textGray),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bin Name',
                  hintText: 'e.g. Dakota Crescent',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a bin name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_imageFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _imageFile = null),
                  child: const Text('Remove photo'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Photo (optional)'),
                ),
              ],
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Bin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

