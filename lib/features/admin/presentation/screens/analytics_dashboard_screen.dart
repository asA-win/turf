import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This Month', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: const [
                  _MetricCard('Total Bookings', '245', '▲ 18.5%', AppTheme.primaryGreen),
                  _MetricCard('Total Revenue', '₹1,24,800', '▲ 22.3%', AppTheme.primaryGreen),
                  _MetricCard('Active Users', '1,250', '▲ 16.4%', AppTheme.primaryGreen),
                  _MetricCard('Matches Played', '320', '▲ 12.7%', AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 24),
              Text('Bookings Overview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Center(
                  child: Text('📈 Revenue & Booking Trend Line Chart', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Top Venues', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              _venueRank('1', 'Green Field Arena', '128 bookings'),
              _venueRank('2', 'Play Arena', '84 bookings'),
              _venueRank('3', 'Kick Off Turf', '64 bookings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _venueRank(String rank, String name, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Text(rank, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          Text(count, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String val;
  final String growth;
  final Color color;
  const _MetricCard(this.title, this.val, this.growth, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(growth, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
