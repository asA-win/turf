import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Delete Account'),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorRed.withOpacity(0.15),
                ),
                child: const Icon(Icons.delete_forever, size: 64, color: AppTheme.errorRed),
              ),
              const SizedBox(height: 20),
              Text(
                "We're sad to see you go! 😔",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will permanently delete:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _bullet('Your profile and personal data'),
                    _bullet('All your bookings and history'),
                    _bullet('Wallet balance and transactions'),
                    _bullet('Team and chat data'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/welcome'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                ),
                child: Text('Delete My Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
        ],
      ),
    );
  }
}
