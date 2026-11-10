import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.go('/logo-animation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: GestureDetector(
        onTap: () {
          if (mounted) context.go('/logo-animation');
        },
        child: Stack(
          fit: StackFit.expand,
        children: [
          // Background Image Placeholder (Stadium)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              const BYSLogo(fontSize: 80, showTagline: true),
              const SizedBox(height: 48),
              Text(
                'BOOK. PLAY. COMPETE.',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'LOADING...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textGrey,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'v 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    ),
  );
}
}
