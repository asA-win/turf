import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class BYSLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool showBall;

  const BYSLogo({
    super.key,
    this.fontSize = 60,
    this.showTagline = true,
    this.showBall = true,
  });

  @override
  Widget build(BuildContext context) {
    final double ballSize = fontSize * 0.7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBall) ...[
          Container(
            width: ballSize,
            height: ballSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(ballSize * 0.08),
              child: Icon(
                Icons.sports_soccer,
                size: ballSize * 0.85,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: fontSize * 0.1),
        ],
        Text(
          'BYS',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            height: 1.0,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.1),
          Text(
            'BOOK YOUR SLOT',
            style: GoogleFonts.poppins(
              fontSize: fontSize * 0.22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              letterSpacing: 3,
            ),
          ),
        ],
      ],
    );
  }
}

class BysHeaderLogo extends StatelessWidget {
  const BysHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'B',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Y',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppTheme.primaryGreen,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'S',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Text(
          'BOOK YOUR SLOT',
          style: GoogleFonts.poppins(
            fontSize: 7,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

