import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class VenueEarningsScreen extends StatelessWidget {
  const VenueEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Earnings'),
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
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Column(
                  children: [
                    Text('Total Earnings', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('₹1,24,800', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('▲ 22.3% vs last month', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Earnings Breakdown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              _item('Bookings', '₹1,05,600', '▲ 20.5%', Colors.green),
              _item('Add-ons', '₹12,800', '▲ 18.2%', Colors.green),
              _item('Cancellations Deducted', '-₹6,200', '▼ 5.3%', Colors.red),
              _item('Platform Fee', '-₹12,400', '▼ 5.5%', Colors.red),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                child: const Text('View Payout History'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String title, String amt, String growth, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
          Row(
            children: [
              Text(amt, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Text(growth, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
