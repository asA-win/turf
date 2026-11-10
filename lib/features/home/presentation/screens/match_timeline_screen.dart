import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchTimelineScreen extends StatelessWidget {
  final String matchId;
  const MatchTimelineScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    final events = [
      {'min': "32'", 'event': 'Goal!', 'player': 'Rahul Sharma', 'type': 'goal'},
      {'min': "23'", 'event': 'Yellow Card', 'player': 'Arun Prasad', 'type': 'card'},
      {'min': "21'", 'event': 'Goal!', 'player': 'Vignesh K', 'type': 'goal'},
      {'min': "18'", 'event': 'Substitution', 'player': 'Manoj George in / Karthik M out', 'type': 'sub'},
      {'min': "10'", 'event': 'Yellow Card', 'player': 'Karthik M', 'type': 'card'},
      {'min': "05'", 'event': 'Goal!', 'player': 'Alex Morgan', 'type': 'goal'},
      {'min': "00'", 'event': 'Match Started', 'player': '', 'type': 'start'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Text(
          'Match Timeline',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final ev = events[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    ev['min']!,
                    style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                    ),
                    if (index < events.length - 1)
                      Container(width: 2, height: 50, color: AppTheme.cardBorder),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        _iconForType(ev['type']!),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev['event']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            if (ev['player']!.isNotEmpty)
                              Text(ev['player']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          ],
                        ),
                      ],
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

  Widget _iconForType(String type) {
    if (type == 'goal') return const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 20);
    if (type == 'card') return const Icon(Icons.square, color: Colors.amber, size: 18);
    if (type == 'sub') return const Icon(Icons.swap_horiz, color: Colors.blue, size: 20);
    return const Icon(Icons.play_circle_outline, color: AppTheme.textGrey, size: 20);
  }
}
