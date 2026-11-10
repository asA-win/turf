import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/review_repository.dart';
import 'package:turf_app/features/turf_details/domain/models/review.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  final String turfId;
  const ReviewsScreen({super.key, required this.turfId});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  int _selectedFilter = 0; // 0: All, 1: 5★, 2: 4★, 3: 3★, 4: 2★, 5: 1★

  void _showWriteReviewDialog(int numericTurfId) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Write a Review',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Rating:', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = starIndex),
                    icon: Icon(
                      starIndex <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share your experience at this turf...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                  fillColor: AppTheme.surfaceDark,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(reviewRepositoryProvider).createReview(numericTurfId, rating, comment);
                  ref.invalidate(fetchTurfReviewsProvider(numericTurfId));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted successfully!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit review: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: Text('Submit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numericTurfId = int.tryParse(widget.turfId) ?? 1;
    final reviewsAsync = ref.watch(fetchTurfReviewsProvider(numericTurfId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load reviews: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (reviews) {
            final totalReviews = reviews.length;
            final double avgRating = totalReviews > 0
                ? reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews
                : 0.0;

            final starCounts = {
              5: reviews.where((r) => r.rating == 5).length,
              4: reviews.where((r) => r.rating == 4).length,
              3: reviews.where((r) => r.rating == 3).length,
              2: reviews.where((r) => r.rating == 2).length,
              1: reviews.where((r) => r.rating == 1).length,
            };

            final filteredReviews = _selectedFilter == 0
                ? reviews
                : reviews.where((r) => r.rating == (6 - _selectedFilter)).toList();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              totalReviews > 0 ? avgRating.toStringAsFixed(1) : 'New',
                              style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  totalReviews > 0 ? (avgRating >= 4.0 ? 'Excellent' : 'Good') : 'No Reviews Yet',
                                  style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '$totalReviews ${totalReviews == 1 ? "review" : "reviews"}',
                                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ratingBar('5 ★', totalReviews > 0 ? (starCounts[5]! / totalReviews) : 0.0),
                        _ratingBar('4 ★', totalReviews > 0 ? (starCounts[4]! / totalReviews) : 0.0),
                        _ratingBar('3 ★', totalReviews > 0 ? (starCounts[3]! / totalReviews) : 0.0),
                        _ratingBar('2 ★', totalReviews > 0 ? (starCounts[2]! / totalReviews) : 0.0),
                        _ratingBar('1 ★', totalReviews > 0 ? (starCounts[1]! / totalReviews) : 0.0),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('All ($totalReviews)', 0),
                              _filterChip('5 ★ (${starCounts[5]})', 1),
                              _filterChip('4 ★ (${starCounts[4]})', 2),
                              _filterChip('3 ★ (${starCounts[3]})', 3),
                              _filterChip('2 ★ (${starCounts[2]})', 4),
                              _filterChip('1 ★ (${starCounts[1]})', 5),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (filteredReviews.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                totalReviews == 0 ? 'Be the first to review this turf!' : 'No reviews match this filter.',
                                style: GoogleFonts.poppins(color: AppTheme.textGrey),
                              ),
                            ),
                          )
                        else
                          ...filteredReviews.map((r) => _buildReviewCard(r)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _showWriteReviewDialog(numericTurfId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Write a Review', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildReviewCard(Review r) {
    final author = (r.user.fullName != null && r.user.fullName!.isNotEmpty)
        ? r.user.fullName!
        : (r.user.email != null && r.user.email!.isNotEmpty ? r.user.email!.split('@').first : 'Player');
    final formattedDate = DateFormat.yMMMd().format(r.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.surfaceDark,
                child: Text(
                  author[0].toUpperCase(),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(formattedDate, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text('${r.rating}.0', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(r.comment!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _ratingBar(String label, double factor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11))),
          Expanded(
            child: LinearProgressIndicator(
              value: factor.clamp(0.0, 1.0),
              backgroundColor: AppTheme.cardDark,
              color: AppTheme.primaryGreen,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int filterIndex) {
    final isSelected = _selectedFilter == filterIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterIndex),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
