import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Booking Confirmed! 🎉',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "We're excited to see you play.",
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Green Field Arena', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                            Text('Koramangala, Bangalore', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    _infoRow('Date', '18 May 2025'),
                    _infoRow('Time', '7:00 PM - 8:30 PM'),
                    _infoRow('Duration', '1.5 Hours'),
                    _infoRow('Players', '5 Players'),
                    _infoRow('Booking ID', 'BYS2505181234'),
                    _infoRow('Total Paid', '₹2316', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/qr-entry-pass'),
                child: const Text('View Entry Pass'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/invite-players'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Share Booking', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
          Text(val, style: GoogleFonts.poppins(color: isBold ? AppTheme.primaryGreen : Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
