import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/educational_service.dart';
import '../../theme/app_theme.dart';

class GuidesListScreen extends StatefulWidget {
  const GuidesListScreen({super.key});

  @override
  State<GuidesListScreen> createState() => _GuidesListScreenState();
}

class _GuidesListScreenState extends State<GuidesListScreen> {
  final EducationalService _educationalService = EducationalService();
  List<Map<String, dynamic>> _guides = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guides = await _educationalService.getGuides();
      if (mounted) {
        setState(() {
          _guides = guides;
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

  List<Map<String, dynamic>> get _filteredGuides {
    return _guides.where((guide) {
      final matchesSearch = _searchQuery.isEmpty ||
          (guide['title'] as String? ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (guide['description'] as String? ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          (guide['category'] as String? ?? '') == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final categories = _guides
        .map((g) => g['category'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    return ['All', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Composting Guides'),
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
                        onPressed: _loadGuides,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGuides,
                  child: CustomScrollView(
                    slivers: [
                      // Search bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search guides...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ),
                      // Category filter
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  selectedColor: AppTheme.primaryGreen,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textGray,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Guides list
                      if (_filteredGuides.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text('No guides found.'),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final guide = _filteredGuides[index];
                                return _GuideCard(
                                  guide: guide,
                                  onTap: () {
                                    context.push('/guides/${guide['id']}');
                                  },
                                );
                              },
                              childCount: _filteredGuides.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final Map<String, dynamic> guide;
  final VoidCallback onTap;

  const _GuideCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = guide['title'] as String? ?? 'Untitled Guide';
    final description = guide['description'] as String? ?? '';
    final category = guide['category'] as String? ?? '';
    final imageUrl = guide['image'] as String?;
    final likes = (guide['likes'] as int?) ?? 0;
    final views = (guide['views'] as int?) ?? 0;
    final readTime = guide['read_time'] as String? ?? '5 min';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppTheme.backgroundGray,
                    child: const Icon(Icons.image,
                        size: 64, color: AppTheme.textGray),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Chip(
                        label: Text(category),
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppTheme.textGray),
                          const SizedBox(width: 4),
                          Text(
                            readTime,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.visibility,
                              size: 16, color: AppTheme.textGray),
                          const SizedBox(width: 4),
                          Text(
                            '$views',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$likes',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray),
                          ),
                        ],
                      ),
                    ],
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
