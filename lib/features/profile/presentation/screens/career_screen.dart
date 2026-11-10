import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class CareerScreen extends StatefulWidget {
  const CareerScreen({super.key});

  @override
  State<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends State<CareerScreen> {
  String _selectedSport = 'All';

  final List<String> _sportsFilter = [
    'All',
    'Football',
    'Cricket',
    'Badminton',
    'Basketball',
  ];

  // All-time personal bests & high records
  final Map<String, List<Map<String, dynamic>>> _personalBestsBySport = {
    'All': [
      {
        'title': 'Most Goals in a Match',
        'value': '4 Goals',
        'sub': 'vs Kickers United (Summer Cup)',
        'icon': Icons.sports_soccer_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'title': 'Highest Cricket Score',
        'value': '68* (24b)',
        'sub': 'SR 283.3 • 6x4, 5x6 (Box League)',
        'icon': Icons.sports_cricket_rounded,
        'color': const Color(0xFFFF9800),
      },
      {
        'title': 'Longest Win Streak',
        'value': '7 Matches',
        'sub': 'All tournaments & turf friendlies',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF5252),
      },
      {
        'title': 'Fastest Goal',
        'value': '42 Seconds',
        'sub': 'From kickoff vs Red Devils FC',
        'icon': Icons.bolt_rounded,
        'color': Colors.amber,
      },
      {
        'title': 'Best Badminton Margin',
        'value': '21 - 8',
        'sub': 'Victory vs Drop Shots (Smash Masters)',
        'icon': Icons.sports_tennis_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Most Points in Hoops',
        'value': '26 Points',
        'sub': '6 Triples • City 3v3 Hoops Slam',
        'icon': Icons.sports_basketball_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Biggest Win Margin',
        'value': '+6 Goals',
        'sub': '7 - 1 Victory (Play Arena)',
        'icon': Icons.military_tech_rounded,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': 'Total Game Time',
        'value': '74 Hours',
        'sub': 'Across 48 certified turf matches',
        'icon': Icons.timer_outlined,
        'color': const Color(0xFFB388FF),
      },
    ],
    'Football': [
      {
        'title': 'Most Goals in a Match',
        'value': '4 Goals',
        'sub': 'vs Kickers United (Summer Cup)',
        'icon': Icons.sports_soccer_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'title': 'Most Assists in a Match',
        'value': '3 Assists',
        'sub': 'vs Storm Strikers (Night Cup)',
        'icon': Icons.sports_soccer_rounded,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': 'Fastest Goal',
        'value': '42 Seconds',
        'sub': 'Direct kickoff strike • Koramangala',
        'icon': Icons.bolt_rounded,
        'color': Colors.amber,
      },
      {
        'title': 'Consecutive Clean Sheets',
        'value': '3 Matches',
        'sub': 'Green Field Arena Tournament',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFB388FF),
      },
      {
        'title': 'Penalty Record',
        'value': '5 / 5 (100%)',
        'sub': '100% Career penalty record',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF00E676),
      },
      {
        'title': 'Max Distance Covered',
        'value': '8.4 km',
        'sub': 'In 70 min 7v7 clash',
        'icon': Icons.directions_run_rounded,
        'color': const Color(0xFFFF9800),
      },
    ],
    'Cricket': [
      {
        'title': 'Highest Individual Score',
        'value': '68* (24b)',
        'sub': '6x4, 5x6 • SR 283.3 (Box League)',
        'icon': Icons.sports_cricket_rounded,
        'color': const Color(0xFFFF9800),
      },
      {
        'title': 'Best Bowling Figures',
        'value': '4 / 12 (2.0 ov)',
        'sub': 'Decathlon Arena Pitch Championship',
        'icon': Icons.sports_baseball_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'title': 'Highest Strike Rate',
        'value': '283.3',
        'sub': 'Minimum 20 runs scored',
        'icon': Icons.speed_rounded,
        'color': Colors.amber,
      },
      {
        'title': 'Most Sixes in an Over',
        'value': '4 Sixes (26 runs)',
        'sub': 'vs Royal Chalks (8th over)',
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFFF5252),
      },
      {
        'title': 'Most Dismissals in a Game',
        'value': '3 Dismissals',
        'sub': '2 Catches, 1 Direct Hit Run-out',
        'icon': Icons.pan_tool_alt_rounded,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': 'Best Partnership',
        'value': '78 Runs (32b)',
        'sub': 'With Rahul K. (Blaster XI)',
        'icon': Icons.group_work_rounded,
        'color': const Color(0xFFB388FF),
      },
    ],
    'Badminton': [
      {
        'title': 'Best Set Margin',
        'value': '21 - 8',
        'sub': 'Smash Masters Open Doubles',
        'icon': Icons.sports_tennis_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Most Smash Winners',
        'value': '24 Winners',
        'sub': '3-set quarter final vs Drop Shots',
        'icon': Icons.flash_on_rounded,
        'color': Colors.amber,
      },
      {
        'title': 'Most Aces in a Match',
        'value': '6 Aces',
        'sub': 'Victory Turf Court A',
        'icon': Icons.star_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'title': 'Longest Rally',
        'value': '46 Shots',
        'sub': 'Match point decider rally',
        'icon': Icons.loop_rounded,
        'color': const Color(0xFFB388FF),
      },
    ],
    'Basketball': [
      {
        'title': 'Highest Points in a Game',
        'value': '26 Points',
        'sub': 'City 3v3 Hoops Slam',
        'icon': Icons.sports_basketball_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Most 3-Pointers',
        'value': '6 Triples',
        'sub': 'Greenfield Arena Court 2',
        'icon': Icons.adjust_rounded,
        'color': const Color(0xFF00E5FF),
      },
      {
        'title': 'Most Steals in a Game',
        'value': '6 Steals',
        'sub': 'vs Slam Dunkers',
        'icon': Icons.front_hand_rounded,
        'color': const Color(0xFF00E676),
      },
      {
        'title': 'Most Rebounds',
        'value': '14 Rebounds',
        'sub': '9 Defensive, 5 Offensive',
        'icon': Icons.height_rounded,
        'color': const Color(0xFFFF5252),
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Career',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Personal records, milestones & stats',
              style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Share Career Records',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Career records card copied to clipboard!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Career Summary Card
              _buildCareerSummaryCard(),

              const SizedBox(height: 18),

              // Key All-Time Records Grid
              _buildKeyRecordsGrid(),

              const SizedBox(height: 22),

              // Sport Filter Header & Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RECORDS BY SPORT',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textGrey,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Filter All-Time Bests',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSportFilterChips(),

              const SizedBox(height: 20),

              // Personal Bests & Highlights Section
              _buildPersonalBestsSection(),

              const SizedBox(height: 24),

              // Sport Detailed Records Breakdown
              _buildSportDetailedRecordsBreakdown(),

              const SizedBox(height: 24),

              // Venue & Pitch Records
              _buildVenueRecordsCard(),

              const SizedBox(height: 24),

              // Career Milestones & Honors Section
              _buildCareerMilestonesCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCareerSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101B13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Player Avatar with Level Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryGreen, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.primaryGreen, size: 36),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lvl 18',
                      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'John Doe',
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                      ],
                    ),
                    Text(
                      'Striker / All-Rounder • Jersey #7',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF9EABA2)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2E21),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🔥 4 Match Win Streak',
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: Color(0xFF1E3524), height: 26),

          // Matches & Win Record Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStatItem('48', 'Played', Colors.white),
              _buildSummaryDivider(),
              _buildSummaryStatItem('34', 'Wins', const Color(0xFF00E676)),
              _buildSummaryDivider(),
              _buildSummaryStatItem('9', 'Losses', const Color(0xFFFF5252)),
              _buildSummaryDivider(),
              _buildSummaryStatItem('5', 'Draws', Colors.amber),
              _buildSummaryDivider(),
              _buildSummaryStatItem('71%', 'Win Rate', AppTheme.primaryGreen),
            ],
          ),

          const SizedBox(height: 14),

          // Visual Win Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: 34,
                  child: Container(height: 7, color: const Color(0xFF00E676)),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 5,
                  child: Container(height: 7, color: Colors.amber),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 9,
                  child: Container(height: 7, color: const Color(0xFFFF5252)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('34 Wins (71%)', style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF00E676))),
              Text('5 Draws (10%)', style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.amber)),
              Text('9 Losses (19%)', style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFFF5252))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFF1E3524),
    );
  }

  Widget _buildSummaryStatItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _buildKeyRecordsGrid() {
    return Row(
      children: [
        Expanded(child: _buildRecordTile('⚽ 28', 'Career Goals', AppTheme.primaryGreen, 'Top 5%')),
        const SizedBox(width: 8),
        Expanded(child: _buildRecordTile('👟 14', 'Total Assists', const Color(0xFF00E5FF), '1.17/gm')),
        const SizedBox(width: 8),
        Expanded(child: _buildRecordTile('⭐ 8', 'MOTM Awards', Colors.amber, '8 Wins')),
        const SizedBox(width: 8),
        Expanded(child: _buildRecordTile('🛡️ 12', 'Clean Sheets', const Color(0xFFB388FF), 'Solid')),
      ],
    );
  }

  Widget _buildRecordTile(String count, String label, Color accent, String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFF8DA394)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _sportsFilter.map((sport) {
          final isSelected = _selectedSport == sport;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              label: Text(sport == 'All' ? 'All Records' : '$sport Records'),
              labelStyle: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              backgroundColor: const Color(0xFF122016),
              selectedColor: AppTheme.primaryGreen,
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1D3223),
                ),
              ),
              onSelected: (_) => setState(() => _selectedSport = sport),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalBestsSection() {
    final bests = _personalBestsBySport[_selectedSport] ?? _personalBestsBySport['All']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              'ALL-TIME PERSONAL BESTS',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bests.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final item = bests[index];
            final color = item['color'] as Color? ?? AppTheme.primaryGreen;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1812),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData? ?? Icons.star, size: 16, color: color),
                      ),
                      const Icon(Icons.verified_outlined, size: 14, color: AppTheme.textGrey),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['value'] as String,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['title'] as String,
                        style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['sub'] as String,
                        style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF8DA394)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSportDetailedRecordsBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'DETAILED SPORT RECORDS',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedSport == 'All' || _selectedSport == 'Football') ...[
          _buildSportCard(
            sportTitle: 'Football Career Record',
            icon: Icons.sports_soccer_rounded,
            accent: const Color(0xFF00E5FF),
            matchesPlayed: '24 Matches',
            winRate: '75.0% (18W - 4L - 2D)',
            stats: [
              {'label': 'Goals Scored', 'val': '28 (1.17/gm)'},
              {'label': 'Assists', 'val': '14'},
              {'label': 'Clean Sheets', 'val': '12'},
              {'label': 'Hat-Tricks', 'val': '2'},
              {'label': 'Penalties Converted', 'val': '5 / 5 (100%)'},
              {'label': 'MOTM Awards', 'val': '5 Times ⭐'},
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedSport == 'All' || _selectedSport == 'Cricket') ...[
          _buildSportCard(
            sportTitle: 'Box Cricket Career Record',
            icon: Icons.sports_cricket_rounded,
            accent: const Color(0xFFFF9800),
            matchesPlayed: '14 Matches',
            winRate: '71.4% (10W - 3L - 1D)',
            stats: [
              {'label': 'Total Runs', 'val': '386 Runs'},
              {'label': 'Batting Average', 'val': '42.8'},
              {'label': 'Strike Rate', 'val': '194.2'},
              {'label': 'Highest Score', 'val': '68* (24 balls)'},
              {'label': 'Wickets Taken', 'val': '16 Wickets'},
              {'label': 'Best Bowling', 'val': '4/12 (2.0 ov)'},
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedSport == 'All' || _selectedSport == 'Badminton') ...[
          _buildSportCard(
            sportTitle: 'Badminton Doubles Record',
            icon: Icons.sports_tennis_rounded,
            accent: const Color(0xFF10B981),
            matchesPlayed: '6 Matches',
            winRate: '66.7% (4W - 2L)',
            stats: [
              {'label': 'Sets Won / Lost', 'val': '13 Won / 4 Lost'},
              {'label': 'Smash Winners', 'val': '64 Winners'},
              {'label': 'Direct Aces', 'val': '18 Aces'},
              {'label': 'Tournament Podiums', 'val': '2 Titles 🏆'},
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedSport == 'All' || _selectedSport == 'Basketball') ...[
          _buildSportCard(
            sportTitle: 'Basketball 3v3 Record',
            icon: Icons.sports_basketball_rounded,
            accent: const Color(0xFFF59E0B),
            matchesPlayed: '4 Matches',
            winRate: '50.0% (2W - 2L)',
            stats: [
              {'label': 'Total Points', 'val': '72 Points (18.0 PPG)'},
              {'label': '3-Pointers Made', 'val': '12 Triples'},
              {'label': 'Total Rebounds', 'val': '22 Rebounds'},
              {'label': 'Steals', 'val': '12 Steals'},
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSportCard({
    required String sportTitle,
    required IconData icon,
    required Color accent,
    required String matchesPlayed,
    required String winRate,
    required List<Map<String, String>> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    sportTitle,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  matchesPlayed,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Win Rate: $winRate',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
          ),
          const Divider(color: Color(0xFF1E3524), height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
            ),
            itemBuilder: (_, i) {
              final s = stats[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['val']!,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    s['label']!,
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVenueRecordsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'VENUE & PITCH PERFORMANCE RECORDS',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildVenueRow('Play Arena, Koramangala', '12 Matches • 11 Wins (91.6% Win Rate)', '🏆 Best Turf'),
          _buildVenueRow('Green Field Arena, Indiranagar', '8 Matches • 6 Wins • 14 Goals Scored', '⚽ High Scoring'),
          _buildVenueRow('Turf Nation Box Pitch, E-City', '16 Matches • 11 Wins • 240 Runs Logged', '📍 Most Played'),
          _buildVenueRow('Decathlon Arena Pitch, Whitefield', '6 Matches • 4 Wins • 10 Wickets Taken', '🎯 Top Bowling'),
        ],
      ),
    );
  }

  Widget _buildVenueRow(String turfName, String recordStats, String tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turfName,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  recordStats,
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8DA394)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF162B1D),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              tag,
              style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerMilestonesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'CAREER MILESTONES & HONORS',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildMilestoneRow(
            '🎖️ Centurion Contender',
            '48 / 50 Matches played across certified turfs',
            progress: 0.96,
            progressText: '48 / 50',
          ),
          _buildMilestoneRow(
            '⚽ Golden Boot Striker',
            '28 Career Goals scored (Top 5% in Bangalore)',
            isCompleted: true,
          ),
          _buildMilestoneRow(
            '🔥 Unstoppable Streak',
            '4 Consecutive tournament match victories',
            isCompleted: true,
          ),
          _buildMilestoneRow(
            '⭐ Hat-trick Hero',
            '3 Goals in a single match against Kickers United',
            isCompleted: true,
          ),
          _buildMilestoneRow(
            '🏏 Century Club Member',
            '386 Career Box Cricket Runs logged',
            isCompleted: true,
          ),
          _buildMilestoneRow(
            '🛡️ Wall of Defense',
            '12 / 15 Clean sheets logged in turf defense',
            progress: 0.80,
            progressText: '12 / 15',
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(
    String title,
    String subtitle, {
    bool isCompleted = false,
    double? progress,
    String? progressText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8DA394)),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14301E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
                )
              else if (progressText != null)
                Text(
                  progressText,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF192A1F),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
