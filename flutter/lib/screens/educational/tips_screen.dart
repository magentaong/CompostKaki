import 'package:flutter/material.dart';
import '../../services/educational_service.dart';
import '../../theme/app_theme.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final EducationalService _educationalService = EducationalService();
  List<Map<String, dynamic>> _tips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tips = await _educationalService.getTips();
      if (mounted) {
        setState(() {
          _tips = tips;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composting Tips'),
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
                        onPressed: _loadTips,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTips,
                  child: _tips.isEmpty
                      ? const Center(child: Text('No tips available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tips.length,
                          itemBuilder: (context, index) {
                            final tip = _tips[index];
                            return _TipCard(tip: tip);
                          },
                        ),
                ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final Map<String, dynamic> tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final title = tip['title'] as String? ?? 'Tip';
    final content =
        tip['content'] as String? ?? tip['description'] as String? ?? '';
    final category = tip['category'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                if (category.isNotEmpty)
                  Chip(
                    label: Text(category),
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
