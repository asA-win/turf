import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/review_repository.dart';

class ReviewRatingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const ReviewRatingScreen({super.key, this.data});

  @override
  ConsumerState<ReviewRatingScreen> createState() => _ReviewRatingScreenState();
}

class _ReviewRatingScreenState extends ConsumerState<ReviewRatingScreen> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController(text: 'Great turf! Well maintained and awesome experience. Will book again.');

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfId = (widget.data?['turfId'] as int?) ??
        (widget.data?['turf_id'] as int?) ??
        int.tryParse(widget.data?['turfId']?.toString() ?? '') ??
        int.tryParse(widget.data?['turf_id']?.toString() ?? '') ??
        1;
    final turfName = widget.data?['turfName'] as String? ??
        widget.data?['turf_name'] as String? ??
        'the venue';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Review & Rating'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                ),
                child: const Icon(Icons.thumb_up_alt_outlined, size: 64, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 20),
              Text(
                'How was your experience at\n$turfName?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text('Your feedback helps us improve.', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    iconSize: 36,
                    icon: Icon(
                      starVal <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _rating = starVal),
                  );
                }),
              ),
              Text('Excellent', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 24),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Write a Review (Optional)',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioClientProvider);
                    await dio.post('/reviews/', data: {
                      'turf_id': turfId,
                      'rating': _rating,
                      'comment': _reviewController.text.trim(),
                    });
                  } catch (e) {
                    debugPrint('[SUBMIT REVIEW ERROR] $e');
                  }

                  try {
                    ref.read(realtimeServiceProvider).emit('reviews/$turfId', {
                      'type': 'new_review',
                      'turf_id': turfId,
                      'rating': _rating,
                      'comment': _reviewController.text.trim(),
                    });
                    ref.read(realtimeServiceProvider).emit('booking_updates', {
                      'type': 'new_review',
                      'turf_id': turfId,
                    });
                  } catch (_) {}

                  ref.invalidate(fetchTurfReviewsProvider(turfId));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your review!')),
                    );
                    context.pop();
                  }
                },
                child: const Text('Submit Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
