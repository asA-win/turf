import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/tournament/data/tournament_repository.dart';

class TournamentHubScreen extends StatefulWidget {
  final Map<String, dynamic>? tournamentData;
  const TournamentHubScreen({super.key, this.tournamentData});

  @override
  State<TournamentHubScreen> createState() => _TournamentHubScreenState();
}

class _TournamentHubScreenState extends State<TournamentHubScreen> {
  // Tabs: 0: Teams, 1: Fixtures, 2: Standings, 3: Brackets, 4: Results
  int _selectedTab = 0;
  bool _organizerModeOverride = false;
  String _teamSearchQuery = '';
  String _fixtureFilter = 'All';

  @override
  void initState() {
    super.initState();
    final initTab = widget.tournamentData?['initialTab'] as int?;
    if (initTab != null && initTab >= 0 && initTab < 5) {
      _selectedTab = initTab;
    } else {
      // Default to Teams tab so players see the team roster
      _selectedTab = 0;
    }
  }

  void _showRegisterTeamDialog(Map<String, dynamic> tournament) {
    context.push('/tournament-register', extra: tournament);
  }

  Color _getColorFromJersey(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'neon green':
        return const Color(0xFF00E676);
      case 'royal blue':
        return const Color(0xFF2979FF);
      case 'fire red':
        return const Color(0xFFFF5252);
      case 'sun yellow':
        return const Color(0xFFFFD600);
      case 'midnight black':
        return const Color(0xFF424242);
      case 'clean white':
        return const Color(0xFFECEFF1);
      case 'purple':
        return const Color(0xFFAB47BC);
      case 'orange':
        return const Color(0xFFFF9100);
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournId = widget.tournamentData?['id'] as String?;

    return ListenableBuilder(
      listenable: TournamentRepository.instance,
      builder: (context, _) {
        final liveTournament =
            TournamentRepository.instance.getTournamentById(tournId) ??
                widget.tournamentData ??
                {};

        final tournamentTitle =
            liveTournament['name'] as String? ?? 'Tournament Championship';
        final tournamentFormat =
            liveTournament['format'] as String? ?? 'Knockout Format';
        final prizePool =
            liveTournament['prizePool'] as String? ?? '₹1,000,000';
        final status = liveTournament['status'] as String? ?? 'Open Entry';
        final spotsFilled = (liveTournament['spotsFilled'] as num?)?.toInt() ?? 0;
        final totalSpots = (liveTournament['totalSpots'] as num?)?.toInt() ?? 16;
        final isRegisteredByYou = liveTournament['isRegisteredByYou'] == true;

        final bool isCreator = (liveTournament['createdBy'] == 'You') ||
            (liveTournament['isCreator'] == true) ||
            _organizerModeOverride;

        final bool isBeforeStart = status != 'Completed' &&
            status != 'Ongoing (Live)' &&
            status != 'Live';

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            backgroundColor: AppTheme.backgroundBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/tournaments');
                }
              },
            ),
            title: Text(
              tournamentTitle,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Creator / Organizer toggle chip
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isCreator
                      ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                      : const Color(0xFF1E2822),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCreator
                        ? AppTheme.primaryGreen
                        : const Color(0xFF2C3E33),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _organizerModeOverride = !_organizerModeOverride;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _organizerModeOverride || isCreator
                              ? 'Organizer Mode: ON (AI Fixture privileges enabled)'
                              : 'Player View active',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.9),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCreator ? Icons.shield_rounded : Icons.person_rounded,
                        size: 13,
                        color: isCreator ? AppTheme.primaryGreen : AppTheme.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCreator ? 'Organizer' : 'Player',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCreator
                              ? AppTheme.primaryGreen
                              : AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const BysProfileAvatar(size: 32),
              const SizedBox(width: 14),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Banner
                  _buildHeaderBanner(
                    liveTournament,
                    tournamentTitle,
                    tournamentFormat,
                    prizePool,
                    spotsFilled,
                    totalSpots,
                  ),
                  const SizedBox(height: 14),

                  // Organizer AI Banner (If Creator before tournament start)
                  if (isCreator && isBeforeStart)
                    _buildOrganizerAIBanner(liveTournament),

                  const SizedBox(height: 14),

                  // Tab Buttons Navigation Bar (Teams, Fixtures, Standings, Brackets, Results)
                  _buildTabsRow(liveTournament),
                  const SizedBox(height: 18),

                  // Dynamic Tab Content
                  _buildTabContent(liveTournament, isCreator, isBeforeStart),

                  const SizedBox(height: 24),

                  // Bottom Action CTA if user hasn't registered yet
                  if (!isRegisteredByYou && isBeforeStart)
                    _buildRegisterButton(liveTournament),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BysBottomNavBar(currentIndex: 2),
        );
      },
    );
  }

  // Header Banner with Gradient
  Widget _buildHeaderBanner(
    Map<String, dynamic> tournament,
    String title,
    String format,
    String prizePool,
    int spotsFilled,
    int totalSpots,
  ) {
    final dates = tournament['dates'] as String? ?? 'Upcoming Dates';
    final venue = tournament['venue'] as String? ?? 'Bengaluru Turf';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F381E), Color(0xFF144525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      prizePool,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$format • 📍 $venue',
            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF9EABA2)),
          ),
          const SizedBox(height: 12),

          // Date & Spots Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.primaryGreen, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    dates,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2E21),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$spotsFilled / $totalSpots Teams Joined',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: spotsFilled >= totalSpots
                        ? Colors.redAccent
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Organizer AI Console Highlight Banner
  Widget _buildOrganizerAIBanner(Map<String, dynamic> tournament) {
    final fixtures = tournament['fixtures'] as List? ?? [];
    final hasFixtures = fixtures.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2618),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORGANIZER AI FIXTURE ASSISTANT',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      hasFixtures
                          ? 'AI has assigned ${fixtures.length} balanced matches. You can re-run before start.'
                          : 'Assign fair match fixtures, pitch slots & knockout tree using AI before start.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF9EABA2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _showAIFixtureDialog(tournament),
              icon: Icon(
                hasFixtures ? Icons.refresh_rounded : Icons.psychology_rounded,
                size: 16,
                color: Colors.black,
              ),
              label: Text(
                hasFixtures ? 'Re-run AI Fixtures' : 'Generate AI Match Fixtures',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5 Tab Navigation Bar
  Widget _buildTabsRow(Map<String, dynamic> tournament) {
    final registeredTeams = tournament['registeredTeams'] as List? ?? [];
    final fixtures = tournament['fixtures'] as List? ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _hubButton(0, Icons.groups_rounded, 'Teams', badge: '${registeredTeams.length}'),
          const SizedBox(width: 8),
          _hubButton(1, Icons.calendar_month_rounded, 'Fixtures', badge: fixtures.isNotEmpty ? '${fixtures.length}' : null),
          const SizedBox(width: 8),
          _hubButton(2, Icons.leaderboard_rounded, 'Standings'),
          const SizedBox(width: 8),
          _hubButton(3, Icons.account_tree_rounded, 'Brackets'),
          const SizedBox(width: 8),
          _hubButton(4, Icons.verified_rounded, 'Results'),
        ],
      ),
    );
  }

  Widget _hubButton(int index, IconData icon, String title, {String? badge}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.18)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : const Color(0xFF2A3D30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Tab Content Switcher
  Widget _buildTabContent(
    Map<String, dynamic> tournament,
    bool isCreator,
    bool isBeforeStart,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildTeamsTab(tournament);
      case 1:
        return _buildFixturesTab(tournament, isCreator, isBeforeStart);
      case 2:
        return _buildStandingsTab(tournament);
      case 3:
        return _buildBracketsTab(tournament);
      case 4:
        return _buildResultsTab(tournament);
      default:
        return _buildTeamsTab(tournament);
    }
  }

  // ==========================================
  // TAB 0: TEAMS (LIST OF REGISTERED TEAMS)
  // ==========================================
  Widget _buildTeamsTab(Map<String, dynamic> tournament) {
    final rawTeams = (tournament['registeredTeams'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final filteredTeams = rawTeams.where((t) {
      final name = (t['teamName'] as String? ?? '').toLowerCase();
      final capt = (t['captainName'] as String? ?? '').toLowerCase();
      final q = _teamSearchQuery.toLowerCase();
      return name.contains(q) || capt.contains(q);
    }).toList();

    final userTeam = rawTeams.where((t) => t['isUserTeam'] == true).firstOrNull;
    final otherTeams = filteredTeams.where((t) => t['isUserTeam'] != true).toList();

    final totalSpots = (tournament['totalSpots'] as num?)?.toInt() ?? 16;
    final spotsFilled = rawTeams.length;
    final spotsRemaining = (totalSpots - spotsFilled).clamp(0, totalSpots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Capacity progress card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Participating Squads',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$spotsRemaining spots left',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalSpots > 0 ? (spotsFilled / totalSpots).clamp(0.0, 1.0) : 0,
                  backgroundColor: const Color(0xFF1A2B20),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$spotsFilled of $totalSpots registered teams verified for tournament draw.',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // If user registered, show their squad prominently
        if (userTeam != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2618),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            'YOUR REGISTERED TEAM',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Status: Confirmed',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getColorFromJersey(userTeam['jerseyColor']),
                      child: Text(
                        (userTeam['teamTag'] as String? ?? 'YOU')
                            .takeFirstLetters(3),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userTeam['teamName'] as String? ?? 'My Squad FC',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Captain: ${userTeam['captainName']} • ${userTeam['playersCount'] ?? 7} Players',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF9EABA2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryGreen),
                      tooltip: 'View Roster',
                      onPressed: () => _showSquadRosterDialog(userTeam),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _teamTag(
                      'Jersey: ${userTeam['jerseyColor'] ?? 'Neon'}',
                      AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    _teamTag(
                      userTeam['skillLevel'] as String? ?? 'Club',
                      const Color(0xFF00E5FF),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showSquadRosterDialog(userTeam),
                      icon: const Icon(Icons.groups, size: 16, color: AppTheme.primaryGreen),
                      label: Text(
                        'View Roster',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Search Bar
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppTheme.textGrey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search registered teams or captains...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _teamSearchQuery = val),
                ),
              ),
              if (_teamSearchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _teamSearchQuery = ''),
                  child: const Icon(Icons.close_rounded, color: AppTheme.textGrey, size: 16),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // List of Teams Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Teams (${filteredTeams.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Draw Seeding: Active',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredTeams.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 40, color: AppTheme.textGrey),
                const SizedBox(height: 10),
                Text(
                  'No teams found matching "$_teamSearchQuery"',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                ),
              ],
            ),
          )
        else
          ...otherTeams.asMap().entries.map((entry) {
            final idx = entry.key;
            final team = entry.value;
            return _buildTeamCard(team, idx + 1);
          }),
      ],
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team, int rank) {
    final teamName = team['teamName'] as String? ?? 'Team $rank';
    final teamTag = team['teamTag'] as String? ?? 'TM';
    final captain = team['captainName'] as String? ?? 'Captain';
    final color = _getColorFromJersey(team['jerseyColor'] as String?);
    final rating = (team['rating'] as num?)?.toDouble() ?? 4.5;
    final playersCount = team['playersCount'] ?? 7;
    final skill = team['skillLevel'] as String? ?? 'Open';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Team Avatar with Rank badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Text(
                  teamTag.takeFirstLetters(3),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                  ),
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.poppins(fontSize: 8.5, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teamName,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Capt. $captain • $playersCount Players',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF8E9E94),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $skill',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Action to view squad
          IconButton(
            icon: const Icon(Icons.visibility_outlined,
                size: 18, color: AppTheme.textGrey),
            tooltip: 'View Squad',
            onPressed: () => _showSquadRosterDialog(team),
          ),
        ],
      ),
    );
  }

  Widget _teamTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: FIXTURES (SHOW ALL MATCH FIXTURES)
  // ==========================================
  Widget _buildFixturesTab(
    Map<String, dynamic> tournament,
    bool isCreator,
    bool isBeforeStart,
  ) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

    // If no fixtures yet
    if (fixtures.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: AppTheme.primaryGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'No Match Fixtures Generated Yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCreator
                  ? 'As the organizer, use the AI Fixture generator to automatically schedule balanced matches, court slots, and the knockout tree.'
                  : 'The tournament organizer will generate the AI match schedule before the tournament begins.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF8E9E94),
              ),
            ),
            const SizedBox(height: 20),
            if (isCreator && isBeforeStart)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _showAIFixtureDialog(tournament),
                  icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                  label: Text(
                    'Generate AI Match Fixtures',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Filter fixtures
    final filteredFixtures = fixtures.where((f) {
      if (_fixtureFilter == 'All') return true;
      if (_fixtureFilter == 'My Matches') return f['isUserMatch'] == true;
      return f['stageGroup'] == _fixtureFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Generated schedule banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2618),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI ASSIGNED FIXTURES (95.6% BALANCE PARITY)',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      '${fixtures.length} matches optimized for turf slots and team rest intervals.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF9EABA2),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCreator && isBeforeStart)
                TextButton(
                  onPressed: () => _showAIFixtureDialog(tournament),
                  child: Text(
                    'Re-run AI',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips: All, My Matches, Quarter Finals, Semi Finals, Final
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _fixtureFilterChip('All (${fixtures.length})', 'All'),
              const SizedBox(width: 8),
              _fixtureFilterChip('My Matches', 'My Matches'),
              const SizedBox(width: 8),
              _fixtureFilterChip('Quarter Finals', 'Quarter Finals'),
              const SizedBox(width: 8),
              _fixtureFilterChip('Semi Finals', 'Semi Finals'),
              const SizedBox(width: 8),
              _fixtureFilterChip('Final', 'Final'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // List of all match fixtures
        if (filteredFixtures.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            child: Text(
              'No matches found in "$_fixtureFilter"',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
            ),
          )
        else
          ...filteredFixtures.map((f) => _buildFixtureCard(f)),
      ],
    );
  }

  Widget _fixtureFilterChip(String label, String value) {
    final isSelected = _fixtureFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _fixtureFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildFixtureCard(Map<String, dynamic> f) {
    final matchNo = f['matchNumber'];
    final stage = f['stage'] as String? ?? 'Match $matchNo';
    final time = f['time'] as String? ?? 'TBD';
    final venue = f['venue'] as String? ?? 'Pitch A';
    final t1 = f['t1'] as String? ?? 'Team 1';
    final t2 = f['t2'] as String? ?? 'Team 2';
    final t1Tag = (f['t1Tag'] as String? ?? 'T1');
    final t2Tag = (f['t2Tag'] as String? ?? 'T2');
    final isUserMatch = f['isUserMatch'] == true;
    final balanceScore = f['aiBalanceScore'] ?? 95;
    final t1Prob = f['t1WinProb'] ?? 50;
    final t2Prob = f['t2WinProb'] ?? 50;
    final note = f['aiNote'] as String? ?? 'Balanced competitive fixture.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUserMatch ? const Color(0xFF102619) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUserMatch
              ? AppTheme.primaryGreen
              : AppTheme.cardBorder,
          width: isUserMatch ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stage, Match #, Time, User Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3224),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MATCH #$matchNo',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stage,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (isUserMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: Colors.black),
                      const SizedBox(width: 3),
                      Text(
                        'YOUR MATCH',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams Clash: T1 vs T2
          Row(
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getColorFromJersey(f['t1Color'] as String?),
                      child: Text(
                        t1Tag.takeFirstLetters(3),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t1,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Win Prob: $t1Prob%',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF8E9E94),
                      ),
                    ),
                  ],
                ),
              ),

              // VS Chip with Parity
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen, width: 1),
                      ),
                      child: Text(
                        'VS',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$balanceScore% Parity',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getColorFromJersey(f['t2Color'] as String?),
                      child: Text(
                        t2Tag.takeFirstLetters(3),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Win Prob: $t2Prob%',
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
          const SizedBox(height: 12),

          // Venue & Time slot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF142017),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded,
                    color: AppTheme.primaryGreen, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$time  •  $venue',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF8E9E94),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'AI Scheduled',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // AI Insight
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 12, color: AppTheme.primaryGreen),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  note,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF7E8E84),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: STANDINGS
  // ==========================================
  Widget _buildStandingsTab(Map<String, dynamic> tournament) {
    final registeredTeams = tournament['registeredTeams'] as List? ?? [];
    final teams = registeredTeams.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text('Team',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
              Text('P',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text('W',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Text('PTS',
                  style: GoogleFonts.poppins(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: AppTheme.cardBorder, height: 20),
          ...teams.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            final name = t['teamName'] as String? ?? 'Team ${idx + 1}';
            final isUser = t['isUserTeam'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text('${idx + 1}',
                      style: GoogleFonts.poppins(
                          color: isUser ? AppTheme.primaryGreen : AppTheme.textWhite,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: isUser ? AppTheme.primaryGreen : AppTheme.textWhite,
                            fontWeight: isUser ? FontWeight.bold : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'YOU',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text('${3 - (idx ~/ 3)}',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                  const SizedBox(width: 20),
                  Text('${(3 - idx).clamp(0, 3)}',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                  const SizedBox(width: 20),
                  Text('${(9 - idx * 2).clamp(1, 9)}',
                      style: GoogleFonts.poppins(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: BRACKETS (DYNAMIC AI KNOCKOUT TREE)
  // ==========================================
  Widget _buildBracketsTab(Map<String, dynamic> tournament) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

    final qfMatches = fixtures.where((f) => f['stageGroup'] == 'Quarter Finals').toList();
    final sfMatches = fixtures.where((f) => f['stageGroup'] == 'Semi Finals').toList();
    final finalMatch = fixtures.where((f) => f['stageGroup'] == 'Final').firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Knockout Bracket Tree',
                style: GoogleFonts.poppins(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fixtures.isNotEmpty ? 'AI Bracket Active' : 'Default Draw',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quarter Finals
          Text(
            'QUARTER FINALS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          if (qfMatches.isNotEmpty)
            ...qfMatches.map((m) => _bracketMatch(
                  m['stage'] as String? ?? 'QF',
                  m['t1'] as String? ?? 'Team 1',
                  m['t2'] as String? ?? 'Team 2',
                  isUserMatch: m['isUserMatch'] == true,
                ))
          else ...[
            _bracketMatch('QF 1', 'Koramangala Titans', 'Apex Predators FC'),
            _bracketMatch('QF 2', 'Green Blitz United', 'Indiranagar Hawks'),
            _bracketMatch('QF 3', 'Urban Kickers FC', 'Velocity Sports FC'),
            _bracketMatch('QF 4', 'Spartans Arena', 'Thunderbolts FC'),
          ],

          const Divider(color: AppTheme.primaryGreen, height: 28),

          // Semi Finals
          Text(
            'SEMI FINALS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          if (sfMatches.isNotEmpty)
            ...sfMatches.map((m) => _bracketMatch(
                  m['stage'] as String? ?? 'SF',
                  m['t1'] as String? ?? 'Winner QF 1',
                  m['t2'] as String? ?? 'Winner QF 2',
                ))
          else ...[
            _bracketMatch('SF 1', 'Winner QF 1', 'Winner QF 2'),
            _bracketMatch('SF 2', 'Winner QF 3', 'Winner QF 4'),
          ],

          const Divider(color: AppTheme.primaryGreen, height: 28),

          // Grand Final
          Text(
            'GRAND CHAMPIONSHIP FINAL',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          _bracketMatch(
            'FINAL',
            finalMatch?['t1'] as String? ?? 'Winner SF 1',
            finalMatch?['t2'] as String? ?? 'Winner SF 2',
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _bracketMatch(
    String stage,
    String t1,
    String t2, {
    bool isHighlight = false,
    bool isUserMatch = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppTheme.primaryGreen.withValues(alpha: 0.15)
            : isUserMatch
                ? const Color(0xFF14291B)
                : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? AppTheme.primaryGreen
              : isUserMatch
                  ? AppTheme.primaryGreen
                  : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isHighlight ? AppTheme.primaryGreen : const Color(0xFF223028),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stage,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.black : AppTheme.textGrey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$t1   vs   $t2',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppTheme.primaryGreen : AppTheme.textWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUserMatch)
            const Icon(Icons.star, color: AppTheme.primaryGreen, size: 14),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: RESULTS
  // ==========================================
  Widget _buildResultsTab(Map<String, dynamic> tournament) {
    final results = [
      {'t1': 'Koramangala Titans', 'score': '4 - 2', 't2': 'Urban Kickers FC', 'date': 'Yesterday', 'mvp': 'Vikram R.'},
      {'t1': 'Apex Predators FC', 'score': '3 - 1', 't2': 'Green Blitz United', 'date': '2 days ago', 'mvp': 'Rahul S.'},
    ];

    return Column(
      children: results.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['t1']} vs ${r['t2']}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MVP: ${r['mvp']} • ${r['date']}',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r['score']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // Register Team Button
  Widget _buildRegisterButton(Map<String, dynamic> tournament) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _showRegisterTeamDialog(tournament),
        icon: const Icon(Icons.app_registration_rounded, color: Colors.black, size: 20),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        label: Text(
          'Register Your Team Now',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL 1: SQUAD ROSTER BOTTOM SHEET
  // ==========================================
  void _showSquadRosterDialog(Map<String, dynamic> team) {
    final teamName = team['teamName'] as String? ?? 'Team Squad';
    final captain = team['captainName'] as String? ?? 'Captain';
    final tag = team['teamTag'] as String? ?? 'TM';
    final jersey = team['jerseyColor'] as String? ?? 'Neon Green';
    final skill = team['skillLevel'] as String? ?? 'Club';
    final players = (team['players'] as List? ?? []).map((p) => Map<String, dynamic>.from(p as Map)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101B14),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _getColorFromJersey(jersey),
                    child: Text(
                      tag.takeFirstLetters(3),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teamName,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Captain: $captain • Jersey: $jersey',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9EABA2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _teamTag(skill, AppTheme.primaryGreen),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Squad Lineup (${players.length} Players)',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Color(0xFF1E3224), height: 20),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF19281E), height: 1),
                  itemBuilder: (_, i) {
                    final p = players[i];
                    final name = p['name'] as String? ?? 'Player ${i + 1}';
                    final role = p['role'] as String? ?? 'Player';
                    final jerseyNo = p['jersey'] as String? ?? '${i + 1}';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1F3526),
                        child: Text(
                          jerseyNo,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        role,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                      ),
                      trailing: role.toLowerCase().contains('captain')
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'CAPTAIN',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL 2: AI FIXTURE GENERATOR DIALOG
  // ==========================================
  void _showAIFixtureDialog(Map<String, dynamic> tournament) {
    String selectedStrategy = 'balanced';
    bool isGenerating = false;
    String statusStep = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C1910),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Tournament Fixture Generator',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Automated balanced matchups & schedule builder',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF8E9E94),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF1E3224), height: 24),

                  if (isGenerating) ...[
                    // Animated AI Loading Experience
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF122217),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            statusStep,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Optimizing turf courts, rest intervals & knockout bracket...',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF8E9E94),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'AI Balancing Strategy',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Strategy Options
                    _strategyTile(
                      dialogCtx,
                      setDialogState,
                      title: 'Balanced Parity Matchup (Recommended)',
                      desc: 'AI pairs teams of closest skill level for maximum competition excitement.',
                      val: 'balanced',
                      selected: selectedStrategy,
                      onSelect: (v) => setDialogState(() => selectedStrategy = v),
                    ),
                    const SizedBox(height: 8),
                    _strategyTile(
                      dialogCtx,
                      setDialogState,
                      title: 'Seeded Tournament Draw',
                      desc: 'Top-rated teams placed on opposite bracket halves for a grand finale.',
                      val: 'seeded',
                      selected: selectedStrategy,
                      onSelect: (v) => setDialogState(() => selectedStrategy = v),
                    ),
                    const SizedBox(height: 8),
                    _strategyTile(
                      dialogCtx,
                      setDialogState,
                      title: 'Random Draw',
                      desc: 'Standard unseeded random knockout pairings.',
                      val: 'random',
                      selected: selectedStrategy,
                      onSelect: (v) => setDialogState(() => selectedStrategy = v),
                    ),
                    const SizedBox(height: 16),

                    // Pitch Assignment details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF142017),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-schedules time slots across Main Arena & Turf Courts with zero slot clashes.',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: const Color(0xFF9EABA2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Run AI Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setDialogState(() {
                            isGenerating = true;
                            statusStep = 'Analyzing registered team skill levels & rosters...';
                          });

                          await Future.delayed(const Duration(milliseconds: 700));
                          if (dialogCtx.mounted) {
                            setDialogState(() {
                              statusStep = 'Simulating competitive parity & win probabilities...';
                            });
                          }

                          await Future.delayed(const Duration(milliseconds: 700));
                          if (dialogCtx.mounted) {
                            setDialogState(() {
                              statusStep = 'Assigning turf court pitches & rest intervals...';
                            });
                          }

                          await Future.delayed(const Duration(milliseconds: 600));

                          final tournId = tournament['id'] as String? ?? 'tourn_1';
                          final fixtures = TournamentRepository.instance
                              .generateAIFixtures(tournId, strategy: selectedStrategy);

                          if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
                            Navigator.pop(dialogCtx);
                          }

                          if (!mounted) return;
                          setState(() {
                            _selectedTab = 1; // Automatically switch to Fixtures tab!
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 AI Fixtures Generated! ${fixtures.length} matches assigned successfully.',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppTheme.primaryGreen,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                        label: Text(
                          'Run AI Matchmaker & Generate Fixtures',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _strategyTile(
    BuildContext ctx,
    StateSetter setDialogState, {
    required String title,
    required String desc,
    required String val,
    required String selected,
    required Function(String) onSelect,
  }) {
    final isSelected = selected == val;
    return GestureDetector(
      onTap: () => onSelect(val),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtensions on String {
  String takeFirstLetters(int count) {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return substring(0, length >= count ? count : length).toUpperCase();
  }
}
