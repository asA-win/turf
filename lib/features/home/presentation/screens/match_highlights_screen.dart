import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchHighlightsScreen extends StatelessWidget {
  final Map<String, dynamic>? matchData;
  const MatchHighlightsScreen({super.key, this.matchData});

  @override
  Widget build(BuildContext context) {
    final teamA = matchData?['team_a_name'] ?? matchData?['teamA'] ?? 'Team A';
    final teamB = matchData?['team_b_name'] ?? matchData?['teamB'] ?? 'Team B';
    final scoreA = matchData?['team_a_score'] ?? matchData?['scoreA'] ?? 0;
    final scoreB = matchData?['team_b_score'] ?? matchData?['scoreB'] ?? 0;
    final venue = matchData?['venue_name'] ?? matchData?['venue'] ?? 'Turf Arena';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Match Highlights',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: AppTheme.surfaceDark,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_outlined, size: 56, color: AppTheme.primaryGreen),
                      const SizedBox(height: 10),
                      Text(
                        'Match Video Feed',
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textGrey),
                      ),
                    ],
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
                      '$teamA $scoreA - $scoreB $teamB',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    Text(
                      venue,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Top Moments & Replays',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.slow_motion_video_rounded, color: AppTheme.textMuted, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'No Replay Clips Uploaded',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Key highlights recorded by the turf or organizer will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
