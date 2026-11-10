import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class NearbyTurfsScreen extends ConsumerWidget {
  const NearbyTurfsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Nearby Turfs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/wishlist'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing turfs near you',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/map-view'),
                    icon: const Icon(Icons.map, size: 16, color: AppTheme.primaryGreen),
                    label: Text('View on Map', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: turfsAsync.when(
                data: (turfs) {
                  if (turfs.isEmpty) {
                    return Center(
                      child: Text('No turfs found nearby', style: GoogleFonts.poppins(color: Colors.white54)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: turfs.length,
                    itemBuilder: (context, index) {
                      final t = turfs[index];
                      final rating = t.averageRating > 0 ? t.averageRating.toStringAsFixed(1) : '4.6';
                      final reviews = t.totalReviews > 0 ? '${t.totalReviews}' : '98';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: t.imageUrl != null
                                ? Image.network(
                                    t.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppTheme.surfaceDark,
                                      child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 30),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: AppTheme.surfaceDark,
                                    child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 30),
                                  ),
                          ),
                          title: Text(
                            t.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$rating ($reviews)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.near_me, color: AppTheme.primaryGreen, size: 14),
                                  const SizedBox(width: 2),
                                  Text('2.1 km', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(t.location, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('₹${t.pricePerHour.toInt()}/hr', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite_border, color: AppTheme.textGrey),
                            onPressed: () {},
                          ),
                          onTap: () => context.push('/turf-details/${t.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
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
            ),
          ],
        ),
      ),
    );
  }
}
