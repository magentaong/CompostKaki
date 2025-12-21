import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/bin_service.dart';
import '../../theme/app_theme.dart';
import 'dart:io';

class LogActivityScreen extends StatefulWidget {
  final String binId;

  const LogActivityScreen({super.key, required this.binId});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final BinService _binService = BinService();
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedType;
  String? _selectedMoisture;
  Map<String, bool> _materials = {
    'greens': false,
    'browns': false,
    'water': false,
  };
  File? _imageFile;
  bool _isLoading = false;
  String? _error;
  String _binName = 'Bin';

  final List<String> _moistureOptions = [
    'Very Dry',
    'Dry',
    'Perfect',
    'Wet',
    'Very Wet',
  ];

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
          _binName = bin['name'] as String? ?? 'Bin';
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      if (type == 'Turn Pile') {
        _contentController.text = 'Turned the pile';
      } else if (type == 'Add Materials') {
        _contentController.text = 'Added materials: greens, browns and water';
      } else if (type == 'Add Water') {
        _contentController.text = 'Added water to the bin';
      } else if (type == 'Monitor') {
        _contentController.text = 'Checked status';
      }
    });
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
      return _materials.values.every((v) => v);
    }
    if (_selectedType == 'Monitor') {
      return _temperatureController.text.isNotEmpty &&
          _selectedMoisture != null;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit() || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _binService.uploadLogImage(_imageFile!, widget.binId);
      }

      await _binService.createBinLog(
        binId: widget.binId,
        type: _selectedType!,
        content: _contentController.text,
        temperature: _temperatureController.text.isNotEmpty
            ? int.tryParse(_temperatureController.text)
            : null,
        moisture: _selectedMoisture,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        image: imageUrl,
      );

      if (mounted) {
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
              // Action buttons
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _ActionButton(
                    label: 'Add Materials',
                    icon: Icons.eco,
                    isSelected: _selectedType == 'Add Materials',
                    onTap: () => _selectType('Add Materials'),
                  ),
                  _ActionButton(
                    label: 'Add Water',
                    icon: Icons.water_drop,
                    isSelected: _selectedType == 'Add Water',
                    onTap: () => _selectType('Add Water'),
                  ),
                  _ActionButton(
                    label: 'Turn Pile',
                    icon: Icons.refresh,
                    isSelected: _selectedType == 'Turn Pile',
                    onTap: () => _selectType('Turn Pile'),
                  ),
                  _ActionButton(
                    label: 'Monitor',
                    icon: Icons.thermostat,
                    isSelected: _selectedType == 'Monitor',
                    onTap: () => _selectType('Monitor'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                          });
                        },
                        activeColor: AppTheme.primaryGreen,
                      ),
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
