import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SimilarTurfsScreen extends StatelessWidget {
  final String turfId;
  const SimilarTurfsScreen({super.key, required this.turfId});

  @override
  Widget build(BuildContext context) {
    final list = [
      {'name': 'Play Arena', 'loc': 'HSR Layout, Bangalore', 'dist': '1.2 km', 'rating': '4.5 (388)', 'price': '₹1000 - ₹2200/hr'},
      {'name': 'Kick Off Turf', 'loc': 'BTM Layout, Bangalore', 'dist': '1.8 km', 'rating': '4.3 (214)', 'price': '₹800 - ₹2000/hr'},
      {'name': 'Champions Turf', 'loc': 'Koramangala, Bangalore', 'dist': '2.0 km', 'rating': '4.6 (266)', 'price': '₹1100 - ₹2100/hr'},
      {'name': 'Victory Turf', 'loc': 'Marathahalli, Bangalore', 'dist': '2.4 km', 'rating': '4.2 (198)', 'price': '₹900 - ₹1800/hr'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Similar Turfs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      onTap: () => context.push('/turf-details/${index + 1}'),
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                      ),
                      title: Text(item['name']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['loc']} • ${item['dist']}', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          Text('★ ${item['rating']}', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 11)),
                          Text(item['price']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/discover'),
                child: const Text('View All Turfs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
