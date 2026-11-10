import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class NearbyTurfsScreen extends StatelessWidget {
  const NearbyTurfsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final turfs = [
      {'name': 'Play Arena', 'distance': '1.2 km', 'rating': '4.6', 'reviews': '368', 'location': 'Koramangala, Bangalore', 'price': '₹1200 - ₹2000/hr'},
      {'name': 'Kick Off Turf', 'distance': '2.1 km', 'rating': '4.5', 'reviews': '264', 'location': 'HSR Layout, Bangalore', 'price': '₹800 - ₹1600/hr'},
      {'name': 'Champions Turf', 'distance': '2.8 km', 'rating': '4.4', 'reviews': '216', 'location': 'Koramangala, Bangalore', 'price': '₹1100 - ₹2100/hr'},
      {'name': 'Goal Arena', 'distance': '3.3 km', 'rating': '4.3', 'reviews': '184', 'location': 'BTM Layout, Bangalore', 'price': '₹900 - ₹1700/hr'},
      {'name': 'The Football Hub', 'distance': '3.7 km', 'rating': '4.2', 'reviews': '132', 'location': 'Koramangala, Bangalore', 'price': '₹1000 - ₹1800/hr'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Nearby Turfs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/wishlist'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing turfs near Koramangala',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/map-view'),
                    icon: const Icon(Icons.map, size: 16, color: AppTheme.primaryGreen),
                    label: Text('View on Map', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: turfs.length,
                itemBuilder: (context, index) {
                  final t = turfs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 32),
                      ),
                      title: Text(
                        t['name']!,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('${t['rating']} (${t['reviews']})', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.near_me, color: AppTheme.primaryGreen, size: 14),
                              const SizedBox(width: 2),
                              Text(t['distance']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(t['location']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(t['price']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppTheme.textGrey),
                        onPressed: () {},
                      ),
                      onTap: () => context.push('/turf-details/${index + 1}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
