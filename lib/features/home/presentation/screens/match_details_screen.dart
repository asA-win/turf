import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;
  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Text(
          'Match Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Match Stats & Records',
            onPressed: () => context.push('/stats', extra: <String, dynamic>{
              'sport': 'Football',
              'turfName': 'Green Field Arena',
              'teamA': 'Turf Titans',
              'teamB': 'Kickers United',
              'mvp': 'Rahul (Striker)',
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Green Field Arena', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Koramangala, Bangalore • ★ 4.6 (512)', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoCard('18 May 2025', 'Today', Icons.calendar_today),
                  _infoCard('7:00 PM - 8:30 PM', '1.5 Hours', Icons.access_time),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoCard('5 v 5', 'Match Format', Icons.sports_soccer),
                  _infoCard('Intermediate', 'Expected Level', Icons.bar_chart),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Joined Players', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  Text('3 / 10', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _avatar('Rahul'),
                  _avatar('Vignesh'),
                  _avatar('Arun'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Match Fee', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  Text('₹120 per player', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined Match!')));
                        context.push('/scoreboard');
                      },
                      child: const Text('Join Match'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/stats', extra: <String, dynamic>{
                          'sport': 'Football',
                          'turfName': 'Green Field Arena',
                          'teamA': 'Turf Titans',
                          'teamB': 'Kickers United',
                          'mvp': 'Rahul (Striker)',
                        });
                      },
                      icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 18),
                      label: Text(
                        'Stats',
                        style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
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

  Widget _infoCard(String title, String subtitle, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                  Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.surfaceDark,
        child: Text(name[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
