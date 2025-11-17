import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';

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
                            onPressed: () {
                              // Show join bin dialog
                            },
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

