import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TurfGalleryScreen extends StatefulWidget {
  final String turfId;
  const TurfGalleryScreen({super.key, required this.turfId});

  @override
  State<TurfGalleryScreen> createState() => _TurfGalleryScreenState();
}

class _TurfGalleryScreenState extends State<TurfGalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final images = [
    'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=500',
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=500',
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500',
    'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=500',
    'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=500',
    'https://images.unsplash.com/photo-1459865264668-3ac567ac33c1?w=500',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Gallery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Ground'),
            Tab(text: 'Facilities'),
            Tab(text: 'Nights'),
          ],
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.image, color: AppTheme.primaryGreen),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
