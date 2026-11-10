import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PopularTurfsScreen extends StatelessWidget {
  const PopularTurfsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Popular Turfs'),
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
              // Hero Featured Header
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Green Field Arena',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '★ 4.8 (512) • Indiranagar',
                        style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 13),
                      ),
                      Text(
                        '₹1200 - ₹2400/hr',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Most Booked This Week',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _turfListItem(context, 'Play Arena', '4.6 (368)', 'Koramangala', '₹1000 - ₹2200/hr', '1'),
              _turfListItem(context, 'Kick Off Turf', '4.5 (264)', 'HSR Layout', '₹800 - ₹1500/hr', '2'),
              _turfListItem(context, 'Champions Turf', '4.4 (216)', 'Koramangala', '₹1100 - ₹2100/hr', '3'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _turfListItem(BuildContext context, String name, String rating, String loc, String price, String id) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => context.push('/turf-details/$id'),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
        ),
        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        subtitle: Text('$loc • ★ $rating', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        trailing: Text(price, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
