import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.shield_outlined, size: 64, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'We Care About\nYour Privacy',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _privacyItem(Icons.no_accounts_outlined, 'We never sell your personal data'),
              _privacyItem(Icons.lock_outline, 'Your data is encrypted and 100% secure'),
              _privacyItem(Icons.control_camera, 'You have full control over your information'),
              _privacyItem(Icons.delete_outline, 'You can request data deletion anytime'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('I Understand'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
