import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MvpScreen extends StatelessWidget {
  final Map<String, dynamic>? extra;
  const MvpScreen({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final mvpName = extra?['mvp_player_name'] ?? extra?['mvp'] ?? 'Player of the Match';
    final teamName = extra?['team'] ?? extra?['teamA'] ?? 'Winning Team';
    final notes = extra?['mvp_notes'] ?? extra?['notes'] ?? 'Outstanding Performance';
    final matchId = extra?['matchId']?.toString();
    final goals = extra?['goals']?.toString() ?? '1';
    final assists = extra?['assists']?.toString() ?? '1';
    final sport = extra?['sport'] ?? 'Football';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('MVP / Man of the Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                '👑 MVP OF THE MATCH',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded, size: 70, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 20),
              Text(
                mvpName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                teamName,
                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                notes,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MvpStat(label: 'Sport', val: sport),
                  _MvpStat(label: 'Impact', val: 'Key Player'),
                  _MvpStat(label: 'Status', val: 'Awarded'),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (matchId != null) {
                    context.push('/match-stats/$matchId', extra: extra);
                  } else {
                    context.push('/stats', extra: extra);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('View Full Match Stats', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (matchId != null)
                OutlinedButton(
                  onPressed: () => context.push('/share-match/$matchId'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryGreen),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text('Share Result', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MvpStat extends StatelessWidget {
  final String label;
  final String val;
  const _MvpStat({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
