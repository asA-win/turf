import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  const SearchResultsScreen({super.key, this.query = 'Football turf in bangalore'});

  @override
  Widget build(BuildContext context) {
    final results = [
      {
        'id': '1',
        'name': 'Green Field Arena',
        'location': 'Indiranagar, Bangalore',
        'rating': '4.8',
        'reviews': '512',
        'distance': '4.5 km',
        'price': '₹1200 - ₹2400/hr',
        'tag': 'Popular',
        'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=500',
      },
      {
        'id': '2',
        'name': 'Play Arena',
        'location': 'Koramangala, Bangalore',
        'rating': '4.6',
        'reviews': '368',
        'distance': '5.2 km',
        'price': '₹1000 - ₹2000/hr',
        'tag': '',
        'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=500',
      },
      {
        'id': '3',
        'name': 'Kick Off Turf',
        'location': 'HSR Layout, Bangalore',
        'rating': '4.5',
        'reviews': '264',
        'distance': '6.1 km',
        'price': '₹800 - ₹1600/hr',
        'tag': '',
        'image': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=500',
      },
      {
        'id': '4',
        'name': 'Victory Turf',
        'location': 'Marathahalli, Bangalore',
        'rating': '4.4',
        'reviews': '198',
        'distance': '7.0 km',
        'price': '₹900 - ₹1800/hr',
        'tag': '',
        'image': 'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=500',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Search Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/search-filters'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '32 results for "$query"',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.swap_vert, size: 16, color: Colors.white),
                        label: Text('Relevance', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.cardBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/search-filters'),
                        icon: const Icon(Icons.filter_list, size: 16, color: AppTheme.primaryGreen),
                        label: Text('Filter', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final turf = results[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/turf-details/${turf['id']}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Image.network(
                                turf['image']!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 150,
                                  color: AppTheme.surfaceDark,
                                  child: const Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                                ),
                              ),
                              if (turf['tag']!.isNotEmpty)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      turf['tag']!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      turf['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${turf['rating']} (${turf['reviews']})',
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: AppTheme.textGrey, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      turf['location']!,
                                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.near_me, color: AppTheme.primaryGreen, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      turf['distance']!,
                                      style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  turf['price']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
