import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String matchId;
  const MatchSummaryScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Match Summary'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Text('Green Field Arena', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                    Text('5v5 • 18 May 2025, 7:00 PM', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Turf Titans', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        Text('2 - 1', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 28)),
                        Text('Goal Diggers', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push('/stats', extra: <String, dynamic>{
                  'sport': 'Football',
                  'turfName': 'Green Field Arena',
                  'teamA': 'Turf Titans',
                  'teamB': 'Goal Diggers',
                  'scoreDisplay': '2 - 1',
                  'result': '🏆 Turf Titans won 2-1',
                  'mvp': 'Rahul Sharma (2 Goals)',
                }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryGreen),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: AppTheme.primaryGreen, child: Icon(Icons.person, color: Colors.black)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Man of the Match', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          Text('Rahul Sharma', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _row('Total Players', '10'),
              _row('Duration', '1.5 Hours'),
              _row('Weather', 'Clear, 28°C'),
              _row('Fair Play Rating', '★ 4.7 / 5'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/share-match/1'),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryGreen)),
                      child: Text('Share Summary', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/stats', extra: <String, dynamic>{
                        'sport': 'Football',
                        'turfName': 'Green Field Arena',
                        'teamA': 'Turf Titans',
                        'teamB': 'Goal Diggers',
                        'scoreDisplay': '2 - 1',
                        'result': '🏆 Turf Titans won 2-1',
                        'mvp': 'Rahul Sharma (2 Goals)',
                      }),
                      child: const Text('Full Statistics'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
          Text(v, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
