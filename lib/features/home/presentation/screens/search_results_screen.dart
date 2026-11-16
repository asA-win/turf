import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/favorite_repository.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String query;
  const SearchResultsScreen({super.key, this.query = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanQuery = query.trim().isEmpty ? null : query.trim();
    final turfsAsync = ref.watch(fetchTurfsProvider(cleanQuery, null));
    final favoritesAsync = ref.watch(fetchMyFavoritesProvider);
    final favoriteTurfIds = (favoritesAsync.valueOrNull ?? [])
        .where((f) => (f as dynamic).turf != null)
        .map((f) => f.turf.id)
        .toSet();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          cleanQuery != null ? 'Results for "$cleanQuery"' : 'All Turfs',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/search-filters'),
          ),
        ],
      ),
      body: SafeArea(
        child: turfsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load search results',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(fetchTurfsProvider(cleanQuery, null)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: Text('Retry', style: GoogleFonts.poppins(color: Colors.black)),
                ),
              ],
            ),
          ),
          data: (turfs) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${turfs.length} ${turfs.length == 1 ? "result" : "results"}${cleanQuery != null ? " for \"$cleanQuery\"" : ""}',
                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => ref.refresh(fetchTurfsProvider(cleanQuery, null)),
                            icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                            label: Text('Refresh', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.cardBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/search-filters'),
                            icon: const Icon(Icons.filter_list, size: 16, color: AppTheme.primaryGreen),
                            label: Text('Filter', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (turfs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No turfs found',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cleanQuery != null ? 'No venues match "$cleanQuery"' : 'No venues currently available',
                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: turfs.length,
                      itemBuilder: (context, index) {
                        final turf = turfs[index];
                        final isFavorite = favoriteTurfIds.contains(turf.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () => context.push('/turf-details/${turf.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Image.network(
                                      (turf.imageUrl != null && turf.imageUrl!.trim().startsWith('http'))
                                          ? turf.imageUrl!.trim()
                                          : 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 160,
                                        color: AppTheme.surfaceDark,
                                        child: const Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                                      ),
                                    ),
                                    if (turf.sportTypes != null && turf.sportTypes!.trim().isNotEmpty)
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            turf.sportTypes!.split(',').first.trim().isNotEmpty
                                                ? turf.sportTypes!.split(',').first.trim()
                                                : 'Turf',
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await ref.read(favoriteRepositoryProvider).toggleFavorite(turf.id);
                                          ref.invalidate(fetchMyFavoritesProvider);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isFavorite ? Icons.favorite : Icons.favorite_border,
                                            color: isFavorite ? Colors.redAccent : Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              turf.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${turf.averageRating.toStringAsFixed(1)} (${turf.totalReviews})',
                                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: AppTheme.textGrey, size: 14),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              turf.location,
                                              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₹${turf.pricePerHour.toStringAsFixed(0)} / hr',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryGreen,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardBorder.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Book Now',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
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
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
