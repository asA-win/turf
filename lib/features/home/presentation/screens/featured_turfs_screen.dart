import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class FeaturedTurfsScreen extends StatelessWidget {
  const FeaturedTurfsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Featured Turfs'),
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
              // Premium Turf Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.cardDark, AppTheme.primaryGreen.withOpacity(0.2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Turf Experience',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Book the best turfs with premium facilities.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/turf-details/1'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(120, 36),
                      ),
                      child: Text('Explore Now', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Top Picks for You',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _pickItem(context, 'The Football Hub', '4.7 (412)', 'Whitefield', '₹1300 - ₹2500/hr'),
              _pickItem(context, 'Victory Turf', '4.6 (294)', 'Marathahalli', '₹1000 - ₹1900/hr'),
              _pickItem(context, 'Elite Sports Arena', '4.5 (210)', 'HSR Layout', '₹1500 - ₹2800/hr'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickItem(BuildContext context, String title, String rating, String loc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: () => context.push('/turf-details/1'),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star, color: Colors.amber),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        subtitle: Text('$loc • ★ $rating', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        trailing: Text(price, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
