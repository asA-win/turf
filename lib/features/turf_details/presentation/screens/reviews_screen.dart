import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ReviewsScreen extends StatelessWidget {
  final String turfId;
  const ReviewsScreen({super.key, required this.turfId});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        'name': 'Rahul Sharma',
        'rating': '5.0',
        'date': '2 days ago',
        'text': 'Great turf! Well maintained and good lighting. Perfect for night matches.',
      },
      {
        'name': 'Vignesh K',
        'rating': '4.0',
        'date': '1 week ago',
        'text': 'Nice place, parking is spacious. Changing rooms can be cleaner.',
      },
    ];

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
        child: Column(
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
                          '4.6',
                          style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.amber, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Excellent', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('512 reviews', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ratingBar('5 ★', 0.72),
                    _ratingBar('4 ★', 0.20),
                    _ratingBar('3 ★', 0.06),
                    _ratingBar('2 ★', 0.01),
                    _ratingBar('1 ★', 0.01),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('All (512)', true),
                          _chip('Excellent (388)', false),
                          _chip('Good (112)', false),
                          _chip('Average (28)', false),
                          _chip('Poor (4)', false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...reviews.map((r) => Container(
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
                                    child: Text(r['name']![0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(r['date']!, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(r['rating']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(r['text']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/review-rating'),
                child: const Text('Write a Review'),
              ),
            ),
          ],
        ),
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
              value: factor,
              backgroundColor: AppTheme.cardDark,
              color: AppTheme.primaryGreen,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected) {
    return Container(
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
    );
  }
}
