import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class PopularTurfsScreen extends ConsumerWidget {
  const PopularTurfsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Popular Turfs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Featured Header
              turfsAsync.when(
                data: (turfs) {
                  final heroTurf = turfs.isNotEmpty ? turfs.first : null;
                  if (heroTurf == null) return const SizedBox.shrink();

                  return GestureDetector(
                    onTap: () => context.push('/turf-details/${heroTurf.id}'),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(heroTurf.imageUrl ?? 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Colors.black87, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heroTurf.name,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '★ ${heroTurf.averageRating > 0 ? heroTurf.averageRating.toStringAsFixed(1) : '4.8'} (${heroTurf.totalReviews > 0 ? heroTurf.totalReviews : 96}) • ${heroTurf.location}',
                              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 13),
                            ),
                            Text(
                              '₹${heroTurf.pricePerHour.toInt()}/hr',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text(
                'Most Booked This Week',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              turfsAsync.when(
                data: (turfs) {
                  if (turfs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No turfs found', style: GoogleFonts.poppins(color: Colors.white54)),
                      ),
                    );
                  }
                  return Column(
                    children: turfs.map((turf) {
                      final rating = turf.averageRating > 0 ? turf.averageRating.toStringAsFixed(1) : '4.6';
                      final reviews = turf.totalReviews > 0 ? '${turf.totalReviews}' : '88';
                      return _turfListItem(
                        context,
                        turf.name,
                        '$rating ($reviews)',
                        turf.location,
                        '₹${turf.pricePerHour.toInt()}/hr',
                        turf.id.toString(),
                        turf.imageUrl,
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                ),
                error: (err, _) => Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error loading turfs', style: GoogleFonts.poppins(color: Colors.white54)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                        onPressed: () => ref.refresh(fetchTurfsProvider(null, null)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _turfListItem(BuildContext context, String name, String rating, String loc, String price, String id, String? imageUrl) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/turf-details/$id'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: AppTheme.surfaceDark,
                    child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: AppTheme.surfaceDark,
                  child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                ),
        ),
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        subtitle: Text('$loc • ★ $rating', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        trailing: Text(price, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
