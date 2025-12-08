import 'package:flutter/material.dart';
import '../../services/educational_service.dart';
import '../../theme/app_theme.dart';

class GuideDetailScreen extends StatefulWidget {
  final String guideId;

  const GuideDetailScreen({super.key, required this.guideId});

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  final EducationalService _educationalService = EducationalService();
  Map<String, dynamic>? _guide;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guide = await _educationalService.getGuide(widget.guideId);
      if (mounted) {
        setState(() {
          _guide = guide;
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

  Future<void> _likeGuide() async {
    try {
      await _educationalService.likeGuide(widget.guideId);
      await _loadGuide(); // Reload to get updated likes count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like guide: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Details'),
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
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGuide,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _guide == null
                  ? const Center(child: Text('Guide not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero image
                          if (_guide!['image'] != null)
                            Image.network(
                              _guide!['image'] as String,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: AppTheme.backgroundGray,
                                child: const Icon(Icons.image, size: 64, color: AppTheme.textGray),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category badge
                                if (_guide!['category'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Chip(
                                      label: Text(_guide!['category'] as String),
                                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                                      labelStyle: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                // Title
                                Text(
                                  _guide!['title'] as String? ?? 'Untitled Guide',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Meta info
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: AppTheme.textGray),
                                    const SizedBox(width: 4),
                                    Text(
                                      _guide!['read_time'] as String? ?? '5 min',
                                      style: const TextStyle(color: AppTheme.textGray),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.visibility, size: 16, color: AppTheme.textGray),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_guide!['views'] ?? 0} views',
                                      style: const TextStyle(color: AppTheme.textGray),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Description
                                Text(
                                  _guide!['description'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textGray,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Sections (if available)
                                if (_guide!['sections'] != null && (_guide!['sections'] as List).isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Table of Contents',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...((_guide!['sections'] as List).map((section) {
                                        final sectionMap = section as Map<String, dynamic>;
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: const Icon(Icons.book, color: AppTheme.primaryGreen),
                                            title: Text(
                                              sectionMap['title'] as String? ?? 'Section',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: sectionMap['content'] != null
                                                ? Text(
                                                    sectionMap['content'] as String,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  )
                                                : null,
                                          ),
                                        );
                                      })),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                // Like button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _likeGuide,
                                    icon: const Icon(Icons.favorite),
                                    label: Text('Like (${_guide!['likes'] ?? 0})'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

