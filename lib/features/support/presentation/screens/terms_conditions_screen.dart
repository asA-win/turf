import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terms & Conditions', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Last updated: 10 May 2025', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to BYS (Book Your Slot). By using our app, you agree to the following terms and conditions.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _section('1. Bookings', 'All bookings are subject to availability. Booking confirmations will be sent to your registered email and app notifications.'),
                    _section('2. Payments', 'All payments must be made in advance. We accept various payment methods as displayed in the app.'),
                    _section('3. Cancellations & Refunds', 'Cancellations made within the allowed timeframe are eligible for a refund as per our refund policy.'),
                    _section('4. User Conduct', 'Users must behave responsibly and follow the rules of the venue and the app.'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('I Agree'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
