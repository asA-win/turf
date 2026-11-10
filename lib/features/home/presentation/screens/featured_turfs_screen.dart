import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class FeaturedTurfsScreen extends ConsumerWidget {
  const FeaturedTurfsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Featured Turfs'),
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
              // Premium Turf Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.cardDark, AppTheme.primaryGreen.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Turf Experience',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Book the best turfs with verified premium facilities.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final firstId = turfsAsync.valueOrNull?.firstOrNull?.id ?? 1;
                        context.push('/turf-details/$firstId');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(120, 36),
                      ),
                      child: Text('Explore Now', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Top Picks for You',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              turfsAsync.when(
                data: (turfs) {
                  if (turfs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No featured turfs available', style: GoogleFonts.poppins(color: Colors.white54)),
                      ),
                    );
                  }
                  return Column(
                    children: turfs.map((turf) {
                      final rating = turf.averageRating > 0 ? turf.averageRating.toStringAsFixed(1) : '4.7';
                      final reviews = turf.totalReviews > 0 ? '${turf.totalReviews}' : '124';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: ListTile(
                          onTap: () => context.push('/turf-details/${turf.id}'),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: turf.imageUrl != null
                                ? Image.network(
                                    turf.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: AppTheme.surfaceDark,
                                      child: const Icon(Icons.star, color: Colors.amber),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: AppTheme.surfaceDark,
                                    child: const Icon(Icons.star, color: Colors.amber),
                                  ),
                          ),
                          title: Text(turf.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          subtitle: Text('${turf.location} • ★ $rating ($reviews)', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                          trailing: Text('₹${turf.pricePerHour.toInt()}/hr', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
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
}
