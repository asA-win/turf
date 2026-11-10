import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PeakHoursScreen extends StatelessWidget {
  const PeakHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Peak Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bar_chart, color: AppTheme.primaryGreen, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Book smart. Save more.',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Avoid peak hours and get the best prices.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hourly Traffic',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Hourly Traffic Bar Graph
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _trafficBar('6 AM', 0.2, Colors.green),
                    _trafficBar('9 AM', 0.3, Colors.green),
                    _trafficBar('12 PM', 0.4, Colors.orange),
                    _trafficBar('3 PM', 0.5, Colors.orange),
                    _trafficBar('6 PM', 0.95, Colors.red, isHighlight: true),
                    _trafficBar('9 PM', 0.8, Colors.red),
                    _trafficBar('12 AM', 0.1, Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppTheme.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Best Time to Book', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('9:00 AM - 12:00 PM (Low demand • Better prices)', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.percent, color: AppTheme.primaryGreen, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Save up to 20%', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                          Text('Book during low traffic hours to enjoy exclusive off-peak discounts.', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trafficBar(String label, double heightFactor, Color color, {bool isHighlight = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isHighlight)
          Text('High', style: GoogleFonts.poppins(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
        Container(
          width: 24,
          height: 110 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}
