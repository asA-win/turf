import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:turf_app/features/booking/presentation/widgets/match_sport_select_sheet.dart';

class MyMatchesScreen extends ConsumerStatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  ConsumerState<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends ConsumerState<MyMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSport = 'All';

  final List<String> _sportsFilter = [
    'All',
    'Football',
    'Cricket',
    'Badminton',
    'Basketball',
    'Tennis',
  ];

  // Played / Past match records
  final List<Map<String, dynamic>> _playedMatches = [
    {
      'id': 'PM-101',
      'turfName': 'Green Field Arena',
      'location': 'Indiranagar, Bengaluru',
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E676),
      'teamA': 'Turf Titans',
      'teamB': 'Kickers United',
      'scoreA': '4',
      'scoreB': '2',
      'scoreDisplay': '4 - 2',
      'date': 'Yesterday • 07:30 PM',
      'result': 'WON',
      'resultColor': const Color(0xFF00E676),
      'mvp': 'Rahul (2 Goals)',
      'status': 'Played',
      'scoreboardConfig': {
        'sport': 'football',
        'turfName': 'Green Field Arena',
        'teamA': 'Turf Titans',
        'teamB': 'Kickers United',
        'scoreA': 4,
        'scoreB': 2,
        'isCompleted': true,
      },
    },
    {
      'id': 'PM-102',
      'turfName': 'Turf Nation Box Pitch',
      'location': 'Electronic City, Bengaluru',
      'sport': 'Cricket',
      'sportIcon': Icons.sports_cricket_rounded,
      'accentColor': const Color(0xFFFF9800),
      'teamA': 'Blaster XI',
      'teamB': 'Royal Chalks',
      'scoreA': '88/4 (8.0 ov)',
      'scoreB': '72/6 (8.0 ov)',
      'scoreDisplay': '88/4 vs 72/6',
      'date': '24 May • 06:00 PM',
      'result': 'WON by 16 runs',
      'resultColor': const Color(0xFF00E676),
      'mvp': 'Amit (34 runs, 2 wkts)',
      'status': 'Played',
      'scoreboardConfig': {
        'sport': 'cricket',
        'turfName': 'Turf Nation Box Pitch',
        'teamA': 'Blaster XI',
        'teamB': 'Royal Chalks',
        'cricketOvers': 8,
        'isCompleted': true,
      },
    },
    {
      'id': 'PM-103',
      'turfName': 'Victory Arena',
      'location': 'Bellandur, Bengaluru',
      'sport': 'Badminton',
      'sportIcon': Icons.sports_tennis_rounded,
      'accentColor': const Color(0xFF29B6F6),
      'teamA': 'Smashers (John & Dev)',
      'teamB': 'Shuttle Pro (Kiran & Raj)',
      'scoreA': '2',
      'scoreB': '1',
      'scoreDisplay': '21-18, 19-21, 21-15',
      'date': '20 May • 08:00 PM',
      'result': 'WON (2-1 sets)',
      'resultColor': const Color(0xFF00E676),
      'mvp': 'John (Match Point Smash)',
      'status': 'Played',
      'scoreboardConfig': {
        'sport': 'badminton',
        'turfName': 'Victory Arena',
        'teamA': 'Smashers',
        'teamB': 'Shuttle Pro',
        'isCompleted': true,
      },
    },
    {
      'id': 'PM-104',
      'turfName': 'Play Arena',
      'location': 'Koramangala, Bengaluru',
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E676),
      'teamA': 'Turf Titans',
      'teamB': 'City Lions FC',
      'scoreA': '1',
      'scoreB': '3',
      'scoreDisplay': '1 - 3',
      'date': '16 May • 09:00 PM',
      'result': 'LOST',
      'resultColor': const Color(0xFFFF5252),
      'mvp': 'Kiran (Opp. Striker)',
      'status': 'Played',
      'scoreboardConfig': {
        'sport': 'football',
        'turfName': 'Play Arena',
        'teamA': 'Turf Titans',
        'teamB': 'City Lions FC',
        'scoreA': 1,
        'scoreB': 3,
        'isCompleted': true,
      },
    },
    {
      'id': 'PM-105',
      'turfName': 'Greenfield Court',
      'location': 'HSR Layout, Bengaluru',
      'sport': 'Basketball',
      'sportIcon': Icons.sports_basketball_rounded,
      'accentColor': const Color(0xFFFF7043),
      'teamA': 'HSR Dunkers',
      'teamB': 'Metro Ballers',
      'scoreA': '48',
      'scoreB': '46',
      'scoreDisplay': '48 - 46',
      'date': '12 May • 07:00 PM',
      'result': 'WON by 2 pts',
      'resultColor': const Color(0xFF00E676),
      'mvp': 'Dev (Game winner 3-pt)',
      'status': 'Played',
      'scoreboardConfig': {
        'sport': 'basketball',
        'turfName': 'Greenfield Court',
        'teamA': 'HSR Dunkers',
        'teamB': 'Metro Ballers',
        'isCompleted': true,
      },
    },
  ];

  // Active / Ongoing Live Match
  final Map<String, dynamic> _liveMatch = {
    'id': 'LIVE-99',
    'turfName': 'Play Arena Koramangala',
    'location': 'Koramangala, Bengaluru',
    'sport': 'Football',
    'sportIcon': Icons.sports_soccer_rounded,
    'accentColor': const Color(0xFF00E676),
    'teamA': 'Turf Titans',
    'teamB': 'Kickers United',
    'scoreA': '2',
    'scoreB': '1',
    'scoreDisplay': '2 - 1',
    'minute': "68' (2nd Half)",
    'status': 'LIVE',
    'scoreboardConfig': {
      'sport': 'football',
      'turfName': 'Play Arena Koramangala',
      'teamA': 'Turf Titans',
      'teamB': 'Kickers United',
      'scoreA': 2,
      'scoreB': 1,
      'footballHalfMinutes': 20,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Real user bookings from repository or demo fallback
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);
    final allBookings = bookingsAsync.valueOrNull ?? demoSampleBookings;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final bookedMatches = allBookings.where((b) {
      return b.status != 'cancelled' &&
          (b.bookingDate.isAfter(today) || b.bookingDate.isAtSameMomentAs(today));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C140F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Matches',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Played & booked matches with live scoreboards',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Match Stats & Top Scorers',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.scoreboard_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Launch Scoreboard',
            onPressed: () => MatchSportSelectSheet.show(context),
          ),
          const BysProfileAvatar(size: 34),
          const SizedBox(width: 14),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: const Color(0xFF8E9E94),
          isScrollable: true,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'All Matches'),
            Tab(text: 'Booked (${bookedMatches.length})'),
            Tab(text: 'Played (${_playedMatches.length})'),
            const Tab(text: 'Live Score (1)'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. Sport Filter Chips (Horizontal)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sportsFilter.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sport = _sportsFilter[index];
                  final isSelected = _selectedSport == sport;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSport = sport),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFF101912),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1B2C20),
                        ),
                      ),
                      child: Text(
                        sport,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black : const Color(0xFFCFDBD2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // 2. Tab Bar Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: All Matches
                  _buildAllMatchesView(bookedMatches),

                  // Tab 1: Booked Matches
                  _buildBookedMatchesView(bookedMatches),

                  // Tab 2: Played Matches
                  _buildPlayedMatchesView(),

                  // Tab 3: Live Score Matches
                  _buildLiveMatchesView(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: -1),
    );
  }

  // Quick Scoreboard Hero Banner
  Widget _buildQuickScoreboardBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F351D), Color(0xFF174C2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.scoreboard_rounded, color: AppTheme.primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Instant Scoreboard',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Keep live score for Football, Cricket, Badminton & more',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFB5C8BC),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => MatchSportSelectSheet.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Open',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 0: All Matches
  Widget _buildAllMatchesView(List<Booking> bookedMatches) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickScoreboardBanner(),

          // Live Match Widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ongoing Match (Live)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE SCORING',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLiveMatchCard(_liveMatch),
          ),

          const SizedBox(height: 20),

          // Booked Matches Section
          if (bookedMatches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booked Matches (${bookedMatches.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tap "Scoreboard" to score',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final booking in bookedMatches) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildBookedMatchCard(booking),
              ),
            ],
            const SizedBox(height: 20),
          ],

          // Played Matches Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Played Matches (${_filteredPlayedMatches.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final match in _filteredPlayedMatches) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: _buildPlayedMatchCard(match),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 1: Booked Matches
  Widget _buildBookedMatchesView(List<Booking> bookedMatches) {
    if (bookedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_outlined, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              'No upcoming booked matches',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Book a turf slot to schedule and score your next match',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/home'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              child: const Text('Book a Turf Now'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          _buildQuickScoreboardBanner(),
          for (final booking in bookedMatches) ...[
            _buildBookedMatchCard(booking),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // TAB 2: Played Matches
  List<Map<String, dynamic>> get _filteredPlayedMatches {
    if (_selectedSport == 'All') return _playedMatches;
    return _playedMatches.where((m) => m['sport'] == _selectedSport).toList();
  }

  Widget _buildPlayedMatchesView() {
    final matches = _filteredPlayedMatches;
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_rounded, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(
              'No played matches in $_selectedSport',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Switch sport filter to see other completed games',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildPlayedMatchCard(matches[index]),
    );
  }

  // TAB 3: Live Matches
  Widget _buildLiveMatchesView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickScoreboardBanner(),
          Text(
            'Active Match in Progress',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildLiveMatchCard(_liveMatch),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1C2C20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Live Turf Scoring',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Whenever you are at the turf, use the Scoreboard to track goals, fouls, overs, wickets, or rally sets. All match stats are automatically saved to your profile and team rankings!',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textGrey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 1: Booked Match Card (with Scoreboard Button!)
  Widget _buildBookedMatchCard(Booking booking) {
    final turfName = booking.turf?.name ?? 'Turf #${booking.turfId}';
    final location = booking.turf?.location ?? 'Bengaluru';
    final sport = booking.turf?.sportTypes?.split(',').first.trim() ?? 'Football';
    final dateStr = DateFormat('EEE, dd MMM • 07:00 PM').format(booking.bookingDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B2C20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF142217),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_added_rounded, color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'BOOKED TURF MATCH',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sport,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turfName,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF8E9E94)),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFCFDBD2), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    // Primary: Open Scoreboard Button
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () => MatchSportSelectSheet.show(
                          context,
                          booking: booking,
                          turfName: turfName,
                          bookingId: booking.id.toString(),
                        ),
                        icon: const Icon(Icons.scoreboard_rounded, color: Colors.black, size: 16),
                        label: Text(
                          'Open Scoreboard',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Secondary: Invite / Details
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => context.push('/invite-players'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF263D2D)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Invite Squad',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Played Match Card (with Scoreboard & Stats Button)
  Widget _buildPlayedMatchCard(Map<String, dynamic> match) {
    final result = match['result'] as String;
    final resultColor = match['resultColor'] as Color;
    final sportColor = match['accentColor'] as Color;
    final config = match['scoreboardConfig'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B2C20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(match['sportIcon'] as IconData, size: 14, color: sportColor),
                    const SizedBox(width: 6),
                    Text(
                      match['sport'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sportColor,
                      ),
                    ),
                    Text(
                      ' • ${match['turfName']}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: resultColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    result,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scoreboard Display Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C140F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A2B1E)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match['teamA'] as String,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152219),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match['scoreDisplay'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match['teamB'] as String,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MVP: ${match['mvp']}',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFFFD600), fontWeight: FontWeight.w600),
                ),
                Text(
                  match['date'] as String,
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF19281D), height: 1),

          // Action Buttons: Scoreboard & Stats
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Launch Scoreboard configured for this match
                      context.push('/scoreboard', extra: config);
                    },
                    icon: const Icon(Icons.scoreboard_rounded, size: 14, color: AppTheme.primaryGreen),
                    label: Text(
                      'View Scoreboard',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E3A25)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/stats', extra: match),
                    icon: const Icon(Icons.analytics_outlined, size: 14, color: Colors.white70),
                    label: Text(
                      'Match Stats',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E2F22)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Live Ongoing Match Card (with Resume Scoreboard Button)
  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final config = match['scoreboardConfig'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF261012),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CURRENTLY PLAYING • ${match['minute']}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                Text(
                  match['turfName'] as String,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          match['teamA'] as String,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match['scoreA'] as String,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    Text('VS', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
                    Column(
                      children: [
                        Text(
                          match['teamB'] as String,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match['scoreB'] as String,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/scoreboard', extra: config);
                          },
                          icon: const Icon(Icons.sports_score_rounded, color: Colors.black, size: 18),
                          label: Text(
                            'Scoreboard',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/stats', extra: match);
                          },
                          icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 16),
                          label: Text(
                            'Live Stats',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2A4232)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
