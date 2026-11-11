import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/review_repository.dart';

class VenueReviewsScreen extends ConsumerStatefulWidget {
  const VenueReviewsScreen({super.key});

  @override
  ConsumerState<VenueReviewsScreen> createState() => _VenueReviewsScreenState();
}

class _VenueReviewsScreenState extends ConsumerState<VenueReviewsScreen> {
  StreamSubscription<Map<String, dynamic>>? _reviewsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _reviewsSub = ref.read(realtimeServiceProvider).connectToChannel('reviews/1').listen((_) {
          if (mounted) ref.invalidate(fetchTurfReviewsProvider(1));
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _reviewsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(fetchTurfReviewsProvider(1));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Venue Reviews'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load venue reviews: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (reviews) {
            final total = reviews.length;
            final double avgRating = total > 0
                ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / total
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        total > 0 ? avgRating.toStringAsFixed(1) : 'New',
                        style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            total > 0 ? (avgRating >= 4.0 ? 'Excellent' : 'Good') : 'No Reviews Yet',
                            style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '$total ${total == 1 ? "Review" : "Reviews"}',
                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('No reviews for this venue yet.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                      ),
                    )
                  else
                    ...reviews.map((r) {
                      final name = (r.user.fullName != null && r.user.fullName!.isNotEmpty)
                          ? r.user.fullName!
                          : (r.user.email != null && r.user.email!.isNotEmpty ? r.user.email!.split('@').first : 'Player');
                      return _reviewCard(name, '${r.rating}.0', r.comment ?? 'Great venue experience!');
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _reviewCard(String name, String rating, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(rating, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
        ],
      ),
    );
  }
}
