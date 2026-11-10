import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchHighlightsScreen extends StatelessWidget {
  const MatchHighlightsScreen({super.key});

  final List<Map<String, String>> moments = const [
    {'title': '1. J. Thompson Goal', 'time': '02:12'},
    {'title': '2. Incredible Top Save', 'time': '04:31'},
    {'title': '3. B. Smith Goal', 'time': '07:18'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Match Highlights',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Thumbnail Player
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1000'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.black, size: 32),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turf Titans 2 - 1 Kickers United',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  Text(
                    'Summer Cup Final • Play Arena',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Top Moments',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  const SizedBox(height: 12),
                  ...moments.map((moment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.play_circle_outline, color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                moment['title']!,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textWhite),
                              ),
                            ],
                          ),
                          Text(
                            moment['time']!,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Spacer(),

            // CTA Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Watch Full Highlights',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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
