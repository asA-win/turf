import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class TurfGalleryScreen extends ConsumerStatefulWidget {
  final String turfId;
  const TurfGalleryScreen({super.key, required this.turfId});

  @override
  ConsumerState<TurfGalleryScreen> createState() => _TurfGalleryScreenState();
}

class _TurfGalleryScreenState extends ConsumerState<TurfGalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numericTurfId = int.tryParse(widget.turfId) ?? 1;
    final turfAsync = ref.watch(fetchTurfByIdProvider(numericTurfId));

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
        child: turfAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load gallery: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (turf) {
            final images = [
              if (turf.imageUrl != null && turf.imageUrl!.isNotEmpty) turf.imageUrl!,
              'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=500',
              'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=500',
              'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500',
            ];

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      color: AppTheme.surfaceDark,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
