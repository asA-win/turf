import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PlayerStatsScreen extends StatelessWidget {
  const PlayerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Statistics'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This Season', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatBlock(val: '32', label: 'Matches'),
                  _StatBlock(val: '18', label: 'Goals'),
                  _StatBlock(val: '12', label: 'Assists'),
                  _StatBlock(val: '5', label: 'MOTM'),
                ],
              ),
              const SizedBox(height: 24),
              Text('Attack', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              _item('Goals per match', '0.75'),
              _item('Total Shots', '56'),
              _item('Shots on Target', '34'),
              _item('Conversion Rate', '32%'),
              const SizedBox(height: 24),
              Text('Passes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              _item('Total Passes', '412'),
              _item('Pass Accuracy', '82%'),
              _item('Key Passes', '28'),
              _item('Assists', '12'),
              const SizedBox(height: 24),
              Text('Discipline', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              _item('Yellow Cards', '3'),
              _item('Red Cards', '0'),
              _item('Fouls Committed', '18'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
