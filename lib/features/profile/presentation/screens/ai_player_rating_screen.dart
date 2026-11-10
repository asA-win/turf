import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AiPlayerRatingScreen extends StatelessWidget {
  const AiPlayerRatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'AI Player Rating',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Rating Badge Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '8.6',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Advanced Player',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Radar Chart Canvas
              Container(
                height: 260,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: CustomPaint(
                  painter: _RadarChartPainter(),
                ),
              ),
              const SizedBox(height: 28),

              // Skills Breakdown Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Strengths',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(height: 8),
                          _bulletPoint('Passing (8.7)'),
                          _bulletPoint('Defense (8.9)'),
                          _bulletPoint('Positioning'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Needs Improvement',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                          ),
                          const SizedBox(height: 8),
                          _bulletPoint('Stamina (7.6)'),
                          _bulletPoint('Dribbling (8.2)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 8, color: AppTheme.textGrey),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite)),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.5;

    final gridPaint = Paint()
      ..color = AppTheme.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final dataPaint = Paint()
      ..color = AppTheme.primaryGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const int sides = 5;
    final List<double> values = [0.86, 0.87, 0.82, 0.89, 0.76]; // Shooting, Passing, Dribbling, Defense, Physical
    final List<String> labels = ['Shooting\n8.6', 'Passing\n8.7', 'Dribbling\n8.2', 'Defense\n8.9', 'Physical\n7.6'];

    // Draw background concentric web
    for (int step = 1; step <= 4; step++) {
      final r = radius * (step / 4);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * pi / sides) - (pi / 2);
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw Data Polygon
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final r = radius * values[i];
      final angle = (i * 2 * pi / sides) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, outlinePaint);

    // Draw Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - (pi / 2);
      final x = center.dx + (radius + 22) * cos(angle);
      final y = center.dy + (radius + 22) * sin(angle);

      textPainter.text = TextSpan(
        text: labels[i],
        style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
