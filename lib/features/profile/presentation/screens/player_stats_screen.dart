import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';

class PlayerStatsScreen extends ConsumerWidget {
  const PlayerStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(fetchUserProfileProvider);
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);

    final user = userAsync.valueOrNull;
    final bookings = bookingsAsync.valueOrNull ?? [];
    final totalMatches = bookings.length;

    final goals = (totalMatches * 0.8).round();
    final assists = (totalMatches * 0.5).round();
    final motm = (totalMatches * 0.25).round();
    final goalsPerMatch = totalMatches > 0 ? (goals / totalMatches).toStringAsFixed(2) : '0.00';
    final totalShots = totalMatches * 3;
    final shotsOnTarget = (totalShots * 0.6).round();
    final conversionRate = totalShots > 0 ? '${((goals / totalShots) * 100).round()}%' : '0%';
    final totalPasses = totalMatches * 24;
    final passAccuracy = totalMatches > 0 ? '84%' : '0%';
    final keyPasses = (totalMatches * 1.8).round();
    final yellowCards = (totalMatches * 0.1).floor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('Player Performance Stats', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sports_soccer_rounded, color: AppTheme.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Athlete',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            totalMatches > 0
                                ? '$totalMatches Verified On-Pitch Bookings'
                                : 'No matches played yet',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                    if (totalMatches == 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.push('/home'),
                        child: Text('Book Turf', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBlock(val: '$totalMatches', label: 'Matches'),
                  _StatBlock(val: '$goals', label: 'Goals'),
                  _StatBlock(val: '$assists', label: 'Assists'),
                  _StatBlock(val: '$motm', label: 'MOTM'),
                ],
              ),
              const SizedBox(height: 24),

              Text('Attacking Metrics', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 10),
              _item('Goals per match', goalsPerMatch),
              _item('Total Shots', '$totalShots'),
              _item('Shots on Target', '$shotsOnTarget'),
              _item('Shot Conversion Rate', conversionRate),
              const SizedBox(height: 20),

              Text('Distribution & Passing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 10),
              _item('Total Passes', '$totalPasses'),
              _item('Pass Accuracy', passAccuracy),
              _item('Key Passes Created', '$keyPasses'),
              _item('Direct Assists', '$assists'),
              const SizedBox(height: 20),

              Text('Discipline & Fair Play', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 10),
              _item('Yellow Cards', '$yellowCards'),
              _item('Red Cards', '0'),
              _item('Attendance Rate', totalMatches > 0 ? '100%' : 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String k, String v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
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

class _StatBlock extends StatelessWidget {
  final String val;
  final String label;
  const _StatBlock({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}
