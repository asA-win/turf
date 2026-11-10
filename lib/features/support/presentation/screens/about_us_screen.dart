import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('About Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: const Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text('BYS', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('BOOK YOUR SLOT', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(
                'Your ultimate platform for booking turfs, joining matches, and connecting with players across the city.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              _card('Our Mission', 'To make sports accessible to everyone by simplifying the way people play.', Icons.flag_outlined),
              _card('Our Vision', 'To build the largest sports community where everyone can play, connect and grow together.', Icons.remove_red_eye_outlined),
              _card('Why BYS?', 'Easy bookings, real-time matches, secure payments, and a seamless sports experience.', Icons.workspace_premium_outlined),
              const SizedBox(height: 32),
              Text('Made with ❤️ for all sports lovers', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
              Text('Version 1.0.0', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
