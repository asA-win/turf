import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ShareBookingScreen extends StatelessWidget {
  const ShareBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Share Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                ),
                child: const Icon(Icons.check_circle, size: 60, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text('Booking Confirmed!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Share with your friends', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Text('Green Field Arena', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    Text('Koramangala, Bangalore', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    Text('18 May 2025 • 7:00 PM - 8:30 PM', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                    Text('Football (6 v 6)', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Share via', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialIcon('WhatsApp', Icons.chat, Colors.green),
                  _socialIcon('Instagram', Icons.camera_alt, Colors.purple),
                  _socialIcon('Facebook', Icons.facebook, Colors.blue),
                  _socialIcon('Copy Link', Icons.copy, AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.black),
                label: const Text('Download Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
