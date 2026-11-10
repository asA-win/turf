import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class SimilarTurfsScreen extends ConsumerWidget {
  final String turfId;
  const SimilarTurfsScreen({super.key, required this.turfId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));
    final currentId = int.tryParse(turfId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Similar Turfs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: turfsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load turfs: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (turfs) {
            final similarTurfs = turfs.where((t) => t.id != currentId).toList();
            if (similarTurfs.isEmpty) {
              return Center(
                child: Text('No other turfs found.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: similarTurfs.length,
                    itemBuilder: (context, index) {
                      final item = similarTurfs[index];
                      final image = item.imageUrl;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: ListTile(
                          onTap: () => context.push('/turf-details/${item.id}'),
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: image != null
                                ? Image.network(
                                    image,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppTheme.surfaceDark,
                                      child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: AppTheme.surfaceDark,
                                    child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                                  ),
                          ),
                          title: Text(
                            item.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(item.location, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${item.averageRating}', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  Text('₹${item.pricePerHour.toInt()}/hr', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 14),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.push('/discover'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceDark,
                        foregroundColor: AppTheme.textWhite,
                        side: BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View All Turfs in Discover', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
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
