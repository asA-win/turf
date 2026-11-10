import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MvpScreen extends StatelessWidget {
  const MvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('MVP Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('Rahul Sharma', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Turf Titans', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _MvpStat(label: 'Goals', val: '1'),
                  _MvpStat(label: 'Assists', val: '1'),
                  _MvpStat(label: 'Accuracy', val: '92%'),
                  _MvpStat(label: 'Rating', val: '8.7'),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/stats', extra: <String, dynamic>{
                  'sport': 'Football',
                  'teamA': 'Turf Titans',
                  'teamB': 'Kickers United',
                  'mvp': 'Rahul Sharma (Goals: 1, Assists: 1)',
                  'result': '🏆 Turf Titans Won',
                }),
                child: const Text('View Full Stats'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/share-match/1'),
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
        Text(val, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
