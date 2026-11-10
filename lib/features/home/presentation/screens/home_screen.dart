import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/providers/location_provider.dart';
import 'package:turf_app/core/widgets/bys_logo.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedSport = 'Football';
  String _selectedTurfMode = 'book'; // 'book' (Book Turf) or 'join' (Join Turf)
  final Set<int> _favoriteTurfIds = {};

  final List<Map<String, dynamic>> _sports = [
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Tennis', 'icon': Icons.sports_baseball},
    {'name': 'More', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> _featuredTurfs = [
    {
      'id': 1,
      'name': 'Play Arena',
      'tag': 'PREMIUM',
      'rating': '4.8',
      'reviews': '128',
      'distance': '2.1 km',
      'location': 'Koramangala, Bengaluru',
      'price': '₹1,200',
      'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
    },
    {
      'id': 2,
      'name': 'Greenfield Arena',
      'tag': 'POPULAR',
      'rating': '4.6',
      'reviews': '96',
      'distance': '3.4 km',
      'location': 'HSR Layout, Bengaluru',
      'price': '₹1,000',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    },
    {
      'id': 3,
      'name': 'Turf Nation',
      'tag': 'BUDGET',
      'rating': '4.3',
      'reviews': '75',
      'distance': '4.6 km',
      'location': 'Electronic City, Bengaluru',
      'price': '₹800',
      'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800',
    },
  ];

  final List<Map<String, dynamic>> _joinTurfs = [
    {
      'id': 1,
      'name': 'Play Arena',
      'sport': 'Football',
      'format': '5v5 Friendly',
      'spotsLeft': 3,
      'totalSpots': 10,
      'joinedCount': 7,
      'time': 'Today • 7:00 PM',
      'distance': '2.1 km',
      'location': 'Koramangala, Bengaluru',
      'pricePerPerson': '₹150',
      'host': 'Alex R.',
      'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
    },
    {
      'id': 2,
      'name': 'Greenfield Arena',
      'sport': 'Football',
      'format': '7v7 Match',
      'spotsLeft': 2,
      'totalSpots': 14,
      'joinedCount': 12,
      'time': 'Today • 8:30 PM',
      'distance': '3.4 km',
      'location': 'HSR Layout, Bengaluru',
      'pricePerPerson': '₹180',
      'host': 'Praveen K.',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
    },
    {
      'id': 3,
      'name': 'Turf Nation',
      'sport': 'Cricket',
      'format': 'Box 6v6',
      'spotsLeft': 4,
      'totalSpots': 12,
      'joinedCount': 8,
      'time': 'Tomorrow • 6:30 AM',
      'distance': '4.6 km',
      'location': 'Electronic City, Bengaluru',
      'pricePerPerson': '₹120',
      'host': 'Rohit S.',
      'image': 'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800',
    },
    {
      'id': 4,
      'name': 'Victory Turf',
      'sport': 'Badminton',
      'format': 'Doubles Rally',
      'spotsLeft': 1,
      'totalSpots': 4,
      'joinedCount': 3,
      'time': 'Today • 9:00 PM',
      'distance': '5.2 km',
      'location': 'Bellandur, Bengaluru',
      'pricePerPerson': '₹100',
      'host': 'Siddharth M.',
      'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800',
    },
  ];

  final List<Map<String, dynamic>> _activeMatches = [
    {
      'id': 101,
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'teamA': 'Turf Titans',
      'teamB': 'Kickers United',
      'scoreA': '2',
      'scoreB': '1',
      'minute': "68'",
      'status': 'LIVE 2nd Half',
      'venue': 'Play Arena',
      'court': 'Pitch 1',
      'location': 'Koramangala, Bengaluru',
      'playersCount': 10,
      'event': "Goal by Rahul 54'",
      'scoreboardConfig': {
        'sport': 'football',
        'turfName': 'Play Arena',
        'teamA': 'Turf Titans',
        'teamB': 'Kickers United',
        'isViewOnly': true,
        'readOnly': true,
      },
    },
    {
      'id': 102,
      'sport': 'Cricket',
      'sportIcon': Icons.sports_cricket_rounded,
      'accentColor': const Color(0xFFFF9800),
      'teamA': 'Blaster XI',
      'teamB': 'Royal Chalks',
      'scoreA': '78/3',
      'scoreB': '62/5',
      'minute': '6.4 ov',
      'status': 'LIVE 2nd Innings',
      'venue': 'Turf Nation',
      'court': 'Box 2',
      'location': 'Electronic City, Bengaluru',
      'playersCount': 12,
      'event': 'Target: 79 • Req: 17 off 8b',
      'scoreboardConfig': {
        'sport': 'cricket',
        'turfName': 'Turf Nation',
        'teamA': 'Blaster XI',
        'teamB': 'Royal Chalks',
        'cricketOvers': 8,
        'isViewOnly': true,
        'readOnly': true,
      },
    },
    {
      'id': 103,
      'sport': 'Badminton',
      'sportIcon': Icons.sports_tennis_rounded,
      'accentColor': const Color(0xFF10B981),
      'teamA': 'Smash Kings',
      'teamB': 'Drop Shots',
      'scoreA': '14',
      'scoreB': '11',
      'minute': 'Set 3',
      'status': 'LIVE Decider',
      'venue': 'Victory Turf',
      'court': 'Court A',
      'location': 'Bellandur, Bengaluru',
      'playersCount': 4,
      'event': 'Decider Game in progress',
      'scoreboardConfig': {
        'sport': 'badminton',
        'turfName': 'Victory Turf',
        'teamA': 'Smash Kings',
        'teamB': 'Drop Shots',
        'badmintonPoints': 21,
        'isViewOnly': true,
        'readOnly': true,
      },
    },
    {
      'id': 104,
      'sport': 'Basketball',
      'sportIcon': Icons.sports_basketball_rounded,
      'accentColor': const Color(0xFFF59E0B),
      'teamA': 'Hoop Stars',
      'teamB': 'Slam Dunkers',
      'scoreA': '42',
      'scoreB': '38',
      'minute': 'Q3 02:45',
      'status': 'LIVE Q3',
      'venue': 'Greenfield Arena',
      'court': 'Court 2',
      'location': 'HSR Layout, Bengaluru',
      'playersCount': 10,
      'event': '3-Pointer by Sameer',
      'scoreboardConfig': {
        'sport': 'basketball',
        'turfName': 'Greenfield Arena',
        'teamA': 'Hoop Stars',
        'teamB': 'Slam Dunkers',
        'isViewOnly': true,
        'readOnly': true,
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    final locationNameAsync = ref.watch(locationNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar Header
              _buildTopBar(locationNameAsync),
              const SizedBox(height: 14),

              // 2. Search Bar and Scoreboard Option
              _buildSearchAndScoreboardRow(context),
              const SizedBox(height: 16),

              // 3. Sports Categories Row
              _buildSportsRow(),
              const SizedBox(height: 18),

              // 3.5. Book Turf and Join Turf Options
              _buildTurfModeSelector(context),
              const SizedBox(height: 12),

              // 3.6. Active Matches Option (Live ongoing matches ticker & cards)
              _buildActiveMatchesOption(context),
              const SizedBox(height: 20),

              // 4. Featured Turfs / Join Turfs / Active Matches Section
              _buildTurfSectionHeader(context),
              const SizedBox(height: 12),
              _buildTurfSectionContent(context),
              const SizedBox(height: 20),

              // 5. BYS Pro Banner
              _buildBysProBanner(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 0),
    );
  }

  // Top Bar matching reference
  Widget _buildTopBar(AsyncValue<String> locationNameAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Location Selector
        Flexible(
          child: GestureDetector(
            onTap: () => context.push('/search-filters'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Koramangala',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: AppTheme.textWhite, size: 18),
                        ],
                      ),
                      Text(
                        'Bengaluru, Karnataka',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF8E9E94),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Center Logo
        const BysHeaderLogo(),

        // Right side: Notification Bell and Profile Avatar
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 24),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '3',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const BysProfileAvatar(size: 34),
          ],
        ),
      ],
    );
  }

  // Search Bar and Scoreboard Row
  Widget _buildSearchAndScoreboardRow(BuildContext context) {
    return Row(
      children: [
        // Reduced Search Bar
        Expanded(
          child: _buildSearchBar(context),
        ),
        const SizedBox(width: 8),
        // Scoreboard Option Button
        _buildScoreboardOptionButton(context),
      ],
    );
  }

  // Reduced Search Bar with AI Search and Mic
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6F8275), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search-filters'),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Search turfs, sports...',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6F8275),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // AI Search Button (compact)
          GestureDetector(
            onTap: () => context.push('/ai-slot-recommendation'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2516),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 12),
                  const SizedBox(width: 3),
                  Text(
                    'AI',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.mic_none_rounded, color: Color(0xFF8E9E94), size: 18),
        ],
      ),
    );
  }

  // Scoreboard Option Button next to Search Box
  Widget _buildScoreboardOptionButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/scoreboard-setup'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1F14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.sports_score_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E676),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                'Scoreboard',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sports Horizontal Selector Row
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
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1C2C20),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sport['icon'] as IconData,
                  color: isSelected ? AppTheme.primaryGreen : Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  sport['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
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

  // Book Turf and Join Turf Mode Selector
  Widget _buildTurfModeSelector(BuildContext context) {
    final isBook = _selectedTurfMode == 'book';
    final isJoin = _selectedTurfMode == 'join';

    return Row(
      children: [
        // 1. Book Turf Option (Normally book turfs)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTurfMode = 'book';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isBook ? const Color(0xFF0F2618) : const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBook ? AppTheme.primaryGreen : const Color(0xFF1B2C20),
                  width: isBook ? 1.6 : 1,
                ),
                boxShadow: isBook
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isBook
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : const Color(0xFF18261C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sports_soccer_rounded,
                          color: isBook ? AppTheme.primaryGreen : const Color(0xFF7A9382),
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isBook
                              ? AppTheme.primaryGreen.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'FULL VENUE',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isBook ? AppTheme.primaryGreen : const Color(0xFF7A9382),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Book Turf',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isBook ? Colors.white : const Color(0xFFCFDBD2),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Reserve full turf or hourly slots for your squad',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.25,
                      color: const Color(0xFF8B9E91),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Normal Booking',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isBook ? AppTheme.primaryGreen : const Color(0xFF63786A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/discover'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isBook ? AppTheme.primaryGreen : const Color(0xFF1B2C20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isBook ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Join Turf Option (Join existing turfs with spaces left)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTurfMode = 'join';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isJoin ? const Color(0xFF0F2524) : const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isJoin ? const Color(0xFF00E5FF) : const Color(0xFF1B2C20),
                  width: isJoin ? 1.6 : 1,
                ),
                boxShadow: isJoin
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isJoin
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                              : const Color(0xFF18261C),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.group_add_rounded,
                          color: isJoin ? const Color(0xFF00E5FF) : const Color(0xFF7A9382),
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF9800),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SPACES LEFT',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: const Color(0xFFFFB74D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Join Turf',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isJoin ? Colors.white : const Color(0xFFCFDBD2),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Join existing turfs & matches with space left',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.25,
                      color: const Color(0xFF8B9E91),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Split & Play',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isJoin ? const Color(0xFF00E5FF) : const Color(0xFF63786A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/join-match'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isJoin ? const Color(0xFF00E5FF) : const Color(0xFF1B2C20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isJoin ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Active Matches Option (Live ongoing matches ticker & cards)
  Widget _buildActiveMatchesOption(BuildContext context) {
    final isActiveMode = _selectedTurfMode == 'active';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTurfMode = 'active';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActiveMode ? const Color(0xFF131A14) : const Color(0xFF0F1812),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActiveMode ? const Color(0xFFFF3B30) : const Color(0xFF1C2C20),
            width: isActiveMode ? 1.5 : 1,
          ),
          boxShadow: isActiveMode
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Live icon + Active Matches title + LIVE badge + Count Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.35)),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFFFF3B30),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Active Matches',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.5), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF3B30),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: const Color(0xFFFF5247),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Live scores & updates from ongoing turf games',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF8B9E91),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/active-matches'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_activeMatches.length} Live',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6961),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFFFF6961),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live Matches Horizontal Scroll Inside Option
            SizedBox(
              height: 114,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _activeMatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final match = _activeMatches[index];
                  final accent = match['accentColor'] as Color;

                  return GestureDetector(
                    onTap: () {
                      final config = match['scoreboardConfig'] as Map<String, dynamic>? ?? {};
                      context.push('/scoreboard', extra: <String, dynamic>{
                        ...config,
                        'isViewOnly': true,
                        'readOnly': true,
                      });
                    },
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09120B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF18281C),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top row: Sport icon + Venue + Minute badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(match['sportIcon'] as IconData, size: 13, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    match['venue'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB0C2B5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  match['minute'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF6961),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Middle row: Teams & Live Score
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match['teamA'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'vs ${match['teamB']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFF889B8D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF132216),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${match['scoreA']} - ${match['scoreB']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bottom row: Latest event & Tap to scoreboard
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt, size: 12, color: Color(0xFFFFD600)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        match['event'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: const Color(0xFF8B9E91),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View Scorecard',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF00E5FF),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 12, color: Color(0xFF00E5FF)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Footer link
            GestureDetector(
              onTap: () => context.push('/active-matches'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap any match to view live scorecard • View All',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      color: const Color(0xFF7E9283),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primaryGreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Section Header based on active mode
  Widget _buildTurfSectionHeader(BuildContext context) {
    if (_selectedTurfMode == 'active') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Live Matches In Action',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${_activeMatches.length} LIVE NOW',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF453A),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Live scores, real-time match events & ongoing play',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF8E9E94),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/active-matches'),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF453A),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: Color(0xFFFF453A), size: 16),
              ],
            ),
          ),
        ],
      );
    }

    if (_selectedTurfMode == 'join') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Turfs With Space Left',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_joinTurfs.length} OPEN',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFB74D),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Join existing games & split the cost',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF8E9E94),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/join-match'),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: Color(0xFF00E5FF), size: 16),
              ],
            ),
          ),
        ],
      );
    }

    // Default 'book' mode
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Featured Turfs',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Normal Turf Booking • Reserve whole venue',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/discover'),
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
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Dynamic Section Content
  Widget _buildTurfSectionContent(BuildContext context) {
    if (_selectedTurfMode == 'active') {
      return _buildActiveMatchesList(context);
    }
    if (_selectedTurfMode == 'join') {
      return _buildJoinTurfsList(context);
    }
    return _buildFeaturedTurfsList(context);
  }

  // Active Matches Horizontal List for main feed when 'active' mode is selected
  Widget _buildActiveMatchesList(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _activeMatches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final match = _activeMatches[index];
          final accent = match['accentColor'] as Color;

          return GestureDetector(
            onTap: () {
              final config = match['scoreboardConfig'] as Map<String, dynamic>? ?? {};
              context.push('/scoreboard', extra: <String, dynamic>{
                ...config,
                'isViewOnly': true,
                'readOnly': true,
              });
            },
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B2A1F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Venue & Live Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(match['sportIcon'] as IconData, size: 15, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            match['sport'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          match['minute'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6961),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Venue name & location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match['venue']} • ${match['court']}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        match['location'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF8E9E94),
                        ),
                      ),
                    ],
                  ),

                  // Teams & Big Score Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09120B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1C2F20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            match['teamA'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16271A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${match['scoreA']}  -  ${match['scoreB']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            match['teamB'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live commentary & Action button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match['event'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF889B8D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.scoreboard_outlined, size: 12, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'View Score',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Featured Turfs Horizontal List
  Widget _buildFeaturedTurfsList(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _featuredTurfs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final turf = _featuredTurfs[index];
          final id = turf['id'] as int;
          final isFav = _favoriteTurfIds.contains(id);

          return GestureDetector(
            onTap: () => context.push('/turf-details/$id'),
            child: Container(
              width: 175,
              decoration: BoxDecoration(
                color: const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B2A1F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with Tag & Heart
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          turf['image'] as String,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 105,
                            color: const Color(0xFF16251B),
                            child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text(
                            turf['tag'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
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
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turf['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB300), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${turf['rating']} (${turf['reviews']})',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFFA0B2A5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              turf['distance'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFFA0B2A5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF7E8F83), size: 11),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                turf['location'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: const Color(0xFF7E8F83),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${turf['price']} /hr',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
    );
  }

  // Join Turfs (Turfs with Space Left) Horizontal List
  Widget _buildJoinTurfsList(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _joinTurfs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final turf = _joinTurfs[index];
          final totalSpots = turf['totalSpots'] as int;
          final joinedCount = turf['joinedCount'] as int;
          final spotsLeft = turf['spotsLeft'] as int;
          final progress = joinedCount / totalSpots;

          return GestureDetector(
            onTap: () => _showJoinConfirmationDialog(context, turf),
            child: Container(
              width: 195,
              decoration: BoxDecoration(
                color: const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B2A1F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with Space Left Tag & Price
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          turf['image'] as String,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 105,
                            color: const Color(0xFF16251B),
                            child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFF9800), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on, color: Color(0xFFFF9800), size: 11),
                              const SizedBox(width: 2),
                              Text(
                                '$spotsLeft SPOTS LEFT',
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFB74D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${turf['pricePerPerson']} / player',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turf['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.sports_soccer, color: Color(0xFF8E9E94), size: 11),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${turf['sport']} • ${turf['format']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  color: const Color(0xFFA0B2A5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFF7E8F83), size: 11),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${turf['time']} • ${turf['location']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: const Color(0xFF7E8F83),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Capacity progress bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$joinedCount/$totalSpots Joined',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD0DCD4),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: const Color(0xFF1E2E22),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Join Button
                        SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () => _showJoinConfirmationDialog(context, turf),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.group_add_rounded, size: 13, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  'Join Turf',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  // Bottom Sheet for Joining a Turf / Slot with space left
  void _showJoinConfirmationDialog(BuildContext context, Map<String, dynamic> turf) {
    final spotsLeft = turf['spotsLeft'] as int;
    final totalSpots = turf['totalSpots'] as int;
    final joinedCount = turf['joinedCount'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1712),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                '$spotsLeft SPOTS LEFT',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFB74D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              turf['sport'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          turf['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          turf['pricePerPerson'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                        Text(
                          'per player',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFFA0B2A5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E2E22)),
              const SizedBox(height: 12),

              // Match & Turf Details Grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF142017),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F3224)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Time & Date: ',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                        ),
                        Text(
                          turf['time'] as String,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Location: ',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                        ),
                        Expanded(
                          child: Text(
                            turf['location'] as String,
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Organized by: ',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                        ),
                        Text(
                          turf['host'] as String,
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: AppTheme.primaryGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Player Slots: ',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                        ),
                        Text(
                          '$joinedCount of $totalSpots Filled ($spotsLeft spots remaining)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.push('/turf-details/${turf['id']}');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2A4232)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Turf Details',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.push('/slot-selection/${turf['id']}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Confirm & Join Slot',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom BYS Pro Banner matching reference
  Widget _buildBysProBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13150F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4C3D12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A0F),
            const Color(0xFF282210).withValues(alpha: 0.6),
            const Color(0xFF13150F),
          ],
        ),
      ),
      child: Row(
        children: [
          // Left Pro Icon
          Column(
            children: [
              const Icon(Icons.military_tech_outlined, color: Color(0xFFFFD700), size: 28),
              Text(
                'BYS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              Text(
                '– PRO –',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Center Text and Perks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAY MORE. PAY LESS.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFE066),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Unlock exclusive benefits with BYS Pro',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    color: const Color(0xFFB5A77B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _proPerk(Icons.verified_user_outlined, 'Priority\nBooking'),
                    _proPerk(Icons.discount_outlined, 'Special\nDiscounts'),
                    _proPerk(Icons.sports_soccer_outlined, 'Free\nEquipment'),
                    _proPerk(Icons.auto_awesome, 'And\nMore'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Upgrade Button & Trophy
          Column(
            children: [
              ElevatedButton(
                onPressed: () => context.push('/offers-promotions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: Colors.black, size: 12),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _proPerk(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 7, color: const Color(0xFFDFD3AA), height: 1.1),
        ),
      ],
    );
  }
}
