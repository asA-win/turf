import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class DiscoverTurfScreen extends ConsumerStatefulWidget {
  const DiscoverTurfScreen({super.key});

  @override
  ConsumerState<DiscoverTurfScreen> createState() => _DiscoverTurfScreenState();
}

class _DiscoverTurfScreenState extends ConsumerState<DiscoverTurfScreen> {
  String _selectedSport = 'Football';
  String _selectedFilterChip = 'Popular';
  final Set<int> _favoriteTurfIds = {};
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _sports = [
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'More', 'icon': Icons.grid_view_rounded},
  ];

  final List<Map<String, String>> _filterChips = [
    {'name': 'Popular', 'icon': '🔥'},
    {'name': 'Nearest', 'icon': '🎯'},
    {'name': 'Top Rated', 'icon': '⭐'},
    {'name': 'Premium', 'icon': '👑'},
    {'name': 'Open Now', 'icon': '🟢'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar Header (Discover Turfs + Map & Filter buttons)
              _buildHeader(context),
              const SizedBox(height: 14),

              // 2. Search Bar
              _buildSearchBar(),
              const SizedBox(height: 14),

              // 3. Sports Categories Row
              _buildSportsRow(),
              const SizedBox(height: 16),

              // 4. Subheader: Popular Near You
              _buildSubheader(context),
              const SizedBox(height: 12),

              // 5. Horizontal Filter Chips (Popular, Nearest, etc.)
              _buildFilterChips(),
              const SizedBox(height: 16),

              // 6. List of Turfs
              _buildTurfList(context),
              const SizedBox(height: 16),

              // 7. Bottom AI Assistant Banner
              _buildAiAssistantBanner(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 1),
    );
  }

  // Header matching reference
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Discover ',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: 'Turfs',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Find and book the perfect turf',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF8E9E94),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Right side: Favorites, Map, Filters, and Profile buttons
        Row(
          children: [
            // Favorites button with heart symbol
            GestureDetector(
              onTap: () => context.push('/favorites'),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A13),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E2E22)),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Favorites',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Map button
            GestureDetector(
              onTap: () => context.push('/map-view'),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A13),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E2E22)),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Map',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Filters button with green dot
            GestureDetector(
              onTap: () => context.push('/search-filters'),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111A13),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E2E22)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                      ),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Profile button
            Column(
              children: [
                const BysProfileAvatar(size: 36),
                const SizedBox(height: 2),
                Text(
                  'Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF8E9E94),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6F8275), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search turfs, locations, or areas...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6F8275),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
        ],
      ),
    );
  }

  // Sports Row
  Widget _buildSportsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _sports.map((sport) {
        final isSelected = _selectedSport == sport['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSport = sport['name'] as String;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1C2C20),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sport['icon'] as IconData,
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  sport['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFFC0CEC5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Subheader: Popular Near You
  Widget _buildSubheader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Near You',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 13),
                const SizedBox(width: 2),
                Text(
                  'Koramangala, Bengaluru',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF8E9E94),
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Filter Chips Row
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filterChips.map((chip) {
          final isSelected = _selectedFilterChip == chip['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilterChip = chip['name']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F2618) : const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
                  ),
                ),
                child: Row(
                  children: [
                    Text(chip['icon']!, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      chip['name']!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFC0CEC5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Turf Cards List (Vertical)
  Widget _buildTurfList(BuildContext context) {
    final sportParam = (_selectedSport == 'All' || _selectedSport == 'More') ? null : _selectedSport;
    final searchParam = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
    final turfsAsync = ref.watch(fetchTurfsProvider(searchParam, sportParam));

    return turfsAsync.when(
      data: (turfs) {
        if (turfs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.sports_soccer_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'No turfs found for your search',
                    style: GoogleFonts.poppins(color: const Color(0xFFA0B2A5), fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: turfs.map((item) {
            final id = item.id;
            final isFav = _favoriteTurfIds.contains(id);
            final turf = {
              'id': item.id,
              'name': item.name,
              'tag': item.turfType ?? (item.averageRating >= 4.5 ? 'PREMIUM' : 'VERIFIED'),
              'rating': item.averageRating > 0 ? item.averageRating.toStringAsFixed(1) : '4.6',
              'reviews': item.totalReviews > 0 ? '${item.totalReviews}' : '96',
              'distance': '2.1 km',
              'location': item.location,
              'price': '₹${item.pricePerHour.toInt()}',
              'features': (item.amenities != null && item.amenities!.isNotEmpty)
                  ? item.amenities!.split(',').take(4).map((s) => s.trim()).toList()
                  : ['7v7', 'Flood Lights', 'Parking', '+2'],
              'image': item.imageUrl ?? 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
            };
            final features = turf['features'] as List<String>;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: GestureDetector(
            onTap: () => context.push('/turf-details/$id'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B2A1F)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Turf Image with Tag & Heart
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          turf['image'] as String,
                          width: 120,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 110,
                            color: const Color(0xFF16251B),
                            child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            turf['tag'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFav) {
                                _favoriteTurfIds.remove(id);
                              } else {
                                _favoriteTurfIds.add(id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                turf['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 15),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF7E8F83), size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${turf['location']} • ${turf['distance']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  color: const Color(0xFF7E8F83),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB300), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${turf['rating']} (${turf['reviews']})',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: Colors.white24, fontSize: 10)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_user_outlined, color: Color(0xFFA0B2A5), size: 11),
                            const SizedBox(width: 2),
                            Text(
                              'Verified Turf',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: const Color(0xFFA0B2A5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Tags Row
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: features.map((feat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16221A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF223528)),
                              ),
                              child: Text(
                                feat,
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  color: const Color(0xFFC0CEC5),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),

                        // Price & View Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${turf['price']} /hr',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2618),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'View Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 13),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  },
  loading: () => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
    ),
  ),
  error: (err, _) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Failed to load turfs', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: () => ref.refresh(fetchTurfsProvider(searchParam, sportParam)),
          ),
        ],
      ),
    ),
  ),
);
  }

  // Bottom AI Assistant Banner
  Widget _buildAiAssistantBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai-slot-recommendation'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E3524)),
        ),
        child: Row(
          children: [
            // Circuit AI Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2516),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
              ),
              child: Center(
                child: Text(
                  'AI',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let AI Find The Best Slot For You!',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Get smart recommendations based on weather, demand and price.',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // CTA
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 12),
                const SizedBox(width: 2),
                Text(
                  'Try AI Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
