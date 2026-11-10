import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class WeatherScreen extends StatelessWidget {
  final String? turfName;
  final String? location;

  const WeatherScreen({
    super.key,
    this.turfName,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          turfName != null ? 'Turf Weather' : 'AI Weather Center',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Location / Turf Title
                      if (turfName != null) ...[
                        Text(
                          turfName!,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            location ?? 'Bengaluru',
                            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Weather Temperature Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_queue, color: AppTheme.primaryGreen, size: 60),
                            const SizedBox(height: 12),
                            Text(
                              '28°C',
                              style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            Text(
                              'Partly Cloudy • Feels like 31°C',
                              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey),
                            ),
                            const SizedBox(height: 20),

                            // Weather Metrics Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _metricCol(Icons.water_drop_outlined, 'Humidity', '68%'),
                                _metricCol(Icons.air, 'Wind', '14 km/h'),
                                _metricCol(Icons.wb_sunny_outlined, 'UV Index', '3'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // AI Recommendation Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppTheme.backgroundBlack,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Recommendation',
                                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    turfName != null
                                        ? 'Perfect weather for playing at $turfName! Pitch is dry with clear visibility and optimal temperature.'
                                        : 'Perfect weather for football! Good visibility and less humidity.',
                                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textWhite),
                                  ),
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

              // Forecast CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'View 7 Day Forecast',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCol(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
      ],
    );
  }
}
