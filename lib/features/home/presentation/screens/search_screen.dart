import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Football turf in bangalore');

  final List<String> _recentSearches = ['Football turf', 'Indiranagar', 'Cricket', 'Koramangala', 'HSR Layout'];
  final List<String> _popularSearches = [
    'Turf near me',
    'Turfs with floodlights',
    'Box cricket turfs',
    'Turfs under ₹2000',
    'Premium turfs',
    'Turf with parking'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search turfs, sports, locations...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textGrey),
              onPressed: () => _searchController.clear(),
            ),
          ),
          onSubmitted: (query) => context.push('/search-results?query=$query'),
        ),
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
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _recentSearches.clear()),
                    child: Text('Clear All', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map((s) => ActionChip(
                          backgroundColor: AppTheme.cardDark,
                          side: const BorderSide(color: AppTheme.cardBorder),
                          label: Text(s, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                          onPressed: () => context.push('/search-results?query=$s'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Popular Searches',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Column(
                children: _popularSearches
                    .map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.search, color: AppTheme.textGrey, size: 20),
                          title: Text(p, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                          trailing: const Icon(Icons.north_west, color: AppTheme.textMuted, size: 16),
                          onTap: () => context.push('/search-results?query=$p'),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Search by Sport',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _sportIcon(Icons.sports_soccer, 'Football'),
                  _sportIcon(Icons.sports_cricket, 'Cricket'),
                  _sportIcon(Icons.sports_tennis, 'Badminton'),
                  _sportIcon(Icons.sports_tennis_outlined, 'Tennis'),
                  _sportIcon(Icons.more_horiz, 'More'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sportIcon(IconData icon, String label) {
    return GestureDetector(
      onTap: () => context.push('/search-results?query=$label'),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}
