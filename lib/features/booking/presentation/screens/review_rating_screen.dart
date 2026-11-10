import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ReviewRatingScreen extends StatefulWidget {
  const ReviewRatingScreen({super.key});

  @override
  State<ReviewRatingScreen> createState() => _ReviewRatingScreenState();
}

class _ReviewRatingScreenState extends State<ReviewRatingScreen> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController(text: 'Great turf! Well maintained and awesome experience. Will book again.');

  @override
  Widget build(BuildContext context) {
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
                'How was your experience at\nGreen Field Arena?',
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your review!')),
                  );
                  context.pop();
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
