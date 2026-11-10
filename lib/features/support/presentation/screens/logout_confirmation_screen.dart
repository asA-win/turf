import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class LogoutConfirmationScreen extends StatelessWidget {
  const LogoutConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: const Icon(Icons.logout, size: 64, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 32),
              Text(
                'Are you sure you want\nto logout?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You will need to login again to access your account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context.go('/welcome'),
                icon: const Icon(Icons.logout, color: Colors.black),
                label: const Text('Logout'),
              ),
              const SizedBox(height: 12),
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
}
