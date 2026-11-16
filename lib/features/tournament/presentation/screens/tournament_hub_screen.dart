import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/tournament/data/tournament_repository.dart';

class TournamentHubScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? tournamentData;
  final String? tournamentId;

  const TournamentHubScreen({
    super.key,
    this.tournamentData,
    this.tournamentId,
  });

  @override
  ConsumerState<TournamentHubScreen> createState() => _TournamentHubScreenState();
}

class _TournamentHubScreenState extends ConsumerState<TournamentHubScreen> {
  // Tabs: 0: Teams, 1: Fixtures, 2: Standings, 3: Brackets, 4: Results
  int _selectedTab = 0;
  String _teamSearchQuery = '';
  String _fixtureFilter = 'All';
  bool _isLoading = false;
  StreamSubscription<Map<String, dynamic>>? _tournamentsSub;
  StreamSubscription<Map<String, dynamic>>? _scoreboardSub;

  String? get _resolvedTournId {
    final fromData = widget.tournamentData?['id']?.toString() ??
        widget.tournamentData?['backendId']?.toString();
    return widget.tournamentId ?? fromData;
  }

  @override
  void initState() {
    super.initState();
    TournamentRepository.instance.addListener(_onRepoChanged);
    final initTab = widget.tournamentData?['initialTab'] as int?;
    if (initTab != null && initTab >= 0 && initTab < 5) {
      _selectedTab = initTab;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTournamentDetails();
      _setupRealtimeSubscriptions();

      // Check if opened with manageDirectly flag
      if (widget.tournamentData?['manageDirectly'] == true) {
        final tourn = _getLiveTournament();
        _showEditTournamentDialog(tourn);
      }
    });
  }

  @override
  void dispose() {
    _tournamentsSub?.cancel();
    _scoreboardSub?.cancel();
    TournamentRepository.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _setupRealtimeSubscriptions() {
    try {
      final realtime = ref.read(realtimeServiceProvider);
      _tournamentsSub = realtime.connectToChannel('tournaments').listen((event) {
        _handleIncomingRealtimeEvent(event);
      });
      _scoreboardSub = realtime.connectToChannel('scoreboard').listen((event) {
        _handleIncomingRealtimeEvent(event);
      });
    } catch (e) {
      debugPrint('[HUB REALTIME] Error subscribing: $e');
    }
  }

  void _handleIncomingRealtimeEvent(Map<String, dynamic> event) {
    final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
    TournamentRepository.instance.handleRealtimeEvent(event, currentUserId: currentUserId);

    final tournIdStr = event['tournament_id']?.toString();
    final currentId = _resolvedTournId;
    if (tournIdStr != null && currentId != null &&
        (tournIdStr == currentId || 'tourn_$tournIdStr' == currentId || currentId.endsWith(tournIdStr))) {
      _fetchTournamentDetails(silent: true);
    }
  }

  Future<void> _fetchTournamentDetails({bool silent = false}) async {
    final targetId = _resolvedTournId;
    if (targetId == null) return;

    if (!silent) setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
      await TournamentRepository.instance.fetchTournamentDetails(
        dio,
        targetId,
        currentUserId: currentUserId,
      );
    } catch (e) {
      debugPrint('[HUB] Error fetching details: $e');
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getLiveTournament() {
    final id = _resolvedTournId;
    final live = TournamentRepository.instance.getTournamentById(id);
    if (live != null) return live;
    return widget.tournamentData ?? {};
  }

  bool _isCurrentUserCreator(Map<String, dynamic> tournament) {
    final userProfile = ref.watch(fetchUserProfileProvider).valueOrNull;
    if (userProfile == null) return tournament['isCreator'] == true || tournament['createdBy'] == 'You';

    final creatorId = tournament['creator_id'];
    if (creatorId != null && creatorId == userProfile.id) return true;
    if (tournament['createdBy'] == 'You' || tournament['isCreator'] == true) return true;
    return false;
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
    final liveTournament = _getLiveTournament();
    final bool isCreator = _isCurrentUserCreator(liveTournament);

    final tournamentTitle = liveTournament['name'] as String? ?? 'Tournament Championship';
    final tournamentFormat = liveTournament['format'] as String? ?? 'Knockout Format';
    final prizePool = liveTournament['prizePool'] as String? ?? '₹1,00,000';
    final status = liveTournament['status'] as String? ?? 'Open Entry';
    final spotsFilled = (liveTournament['spotsFilled'] as num?)?.toInt() ?? 0;
    final totalSpots = (liveTournament['totalSpots'] as num?)?.toInt() ?? 16;
    final isRegisteredByYou = liveTournament['isRegisteredByYou'] == true;
    final fixturesGenerated = liveTournament['fixturesGenerated'] == true ||
        (liveTournament['fixtures'] as List? ?? []).isNotEmpty;

    final bool isBeforeStart = status != 'Completed' &&
        status != 'Ongoing (Live)' &&
        status != 'Live' &&
        status != 'Cancelled';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
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
          if (isCreator) ...[
            // Dedicated Creator Management Action
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: () => _showEditTournamentDialog(liveTournament),
                icon: const Icon(Icons.tune_rounded, size: 14, color: Colors.black),
                label: Text(
                  'Manage',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
              color: const Color(0xFF142217),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditTournamentDialog(liveTournament);
                } else if (val == 'delete') {
                  _showDeleteTournamentDialog(liveTournament);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Text('Edit Details', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text('Cancel / Delete', style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 4),
          const BysProfileAvatar(size: 32),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : RefreshIndicator(
                onRefresh: () => _fetchTournamentDetails(silent: true),
                color: AppTheme.primaryGreen,
                backgroundColor: const Color(0xFF101912),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tournament Header Banner
                      _buildHeaderBanner(
                        liveTournament,
                        tournamentTitle,
                        tournamentFormat,
                        prizePool,
                        spotsFilled,
                        totalSpots,
                        isCreator,
                      ),
                      const SizedBox(height: 14),

                      // Organizer AI Fixture Banner (If Creator before tournament start and no fixtures yet)
                      if (isCreator && isBeforeStart && !fixturesGenerated)
                        _buildOrganizerAIBanner(liveTournament),

                      const SizedBox(height: 14),

                      // Tab Buttons Navigation Bar (Teams, Fixtures, Standings, Brackets, Results)
                      _buildTabsRow(liveTournament),
                      const SizedBox(height: 18),

                      // Dynamic Tab Content
                      _buildTabContent(liveTournament, isCreator, isBeforeStart),

                      const SizedBox(height: 24),

                      // Bottom Action CTA for Non-creator participants
                      if (!isCreator && !isRegisteredByYou && isBeforeStart && status != 'Completed')
                        _buildRegisterButton(liveTournament, spotsFilled, totalSpots)
                      else if (!isCreator && isRegisteredByYou)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF132218),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'You Are Registered in this Tournament',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 2),
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
    bool isCreator,
  ) {
    final dates = tournament['dates'] as String? ?? 'Upcoming Dates';
    final venue = tournament['venue'] as String? ?? 'Bengaluru Turf';
    final status = tournament['status'] as String? ?? 'Open Entry';

    Color statusColor = AppTheme.primaryGreen;
    if (status == 'Completed') statusColor = Colors.blueAccent;
    if (status == 'Ongoing (Live)' || status == 'Live') statusColor = const Color(0xFFFF9800);
    if (status == 'Cancelled') statusColor = Colors.redAccent;

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
                    fontSize: 19,
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
          Row(
            children: [
              Text(
                '$format • 📍 $venue',
                style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF9EABA2)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date & Spots Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryGreen, size: 14),
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
                    color: spotsFilled >= totalSpots ? Colors.redAccent : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Organizer Fixtures Banner
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
                child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOURNAMENT FIXTURE GENERATOR',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      hasFixtures
                          ? '${fixtures.length} matches generated from registered teams.'
                          : 'Generate fair match fixtures & knockout tree from approved teams.',
                      style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF9EABA2)),
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
                hasFixtures ? 'Regenerate Match Fixtures' : 'Generate Match Fixtures',
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.18) : AppTheme.cardDark,
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
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFF2A3D30),
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
  Widget _buildTabContent(Map<String, dynamic> tournament, bool isCreator, bool isBeforeStart) {
    switch (_selectedTab) {
      case 0:
        return _buildTeamsTab(tournament, isCreator);
      case 1:
        return _buildFixturesTab(tournament, isCreator, isBeforeStart);
      case 2:
        return _buildStandingsTab(tournament);
      case 3:
        return _buildBracketsTab(tournament);
      case 4:
        return _buildResultsTab(tournament);
      default:
        return _buildTeamsTab(tournament, isCreator);
    }
  }

  // ==========================================
  // TAB 0: TEAMS (REGISTERED TEAMS & MANAGEMENT)
  // ==========================================
  Widget _buildTeamsTab(Map<String, dynamic> tournament, bool isCreator) {
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
        // Capacity card
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
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '$spotsRemaining spots left',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
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
                '$spotsFilled of $totalSpots registered teams in database.',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // User's Registered Team Card
        if (userTeam != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2618),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
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
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmCancelRegistration(tournament, userTeam),
                      icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.redAccent),
                      label: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _getColorFromJersey(userTeam['jerseyColor']),
                      child: Text(
                        (userTeam['teamTag'] as String? ?? 'YOU').takeFirstLetters(3),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userTeam['teamName'] as String? ?? 'My Squad FC',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Captain: ${userTeam['captainName']} • ${userTeam['playersCount'] ?? 7} Players',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9EABA2)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen),
                      tooltip: 'View Roster',
                      onPressed: () => _showSquadRosterDialog(userTeam),
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

        // List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Registered Teams (${filteredTeams.length})',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (isCreator)
              Text(
                'Creator Management Active',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredTeams.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined, size: 40, color: AppTheme.textGrey),
                const SizedBox(height: 10),
                Text(
                  rawTeams.isEmpty
                      ? 'No teams registered yet.\nTeams will appear here once registered.'
                      : 'No teams found matching "$_teamSearchQuery"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                ),
              ],
            ),
          )
        else
          ...otherTeams.asMap().entries.map((entry) {
            final idx = entry.key;
            final team = entry.value;
            return _buildTeamCard(tournament, team, idx + 1, isCreator);
          }),
      ],
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> tournament, Map<String, dynamic> team, int rank, bool isCreator) {
    final teamName = team['teamName'] as String? ?? 'Team $rank';
    final teamTag = team['teamTag'] as String? ?? 'TM';
    final captain = team['captainName'] as String? ?? 'Captain';
    final color = _getColorFromJersey(team['jerseyColor'] as String?);
    final playersCount = team['playersCount'] ?? 7;
    final skill = team['skillLevel'] as String? ?? 'Open';
    final status = team['status'] as String? ?? 'Approved';
    final regId = team['backendId'] ?? team['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: Text(
                  teamTag.takeFirstLetters(3),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 11),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capt. $captain • $playersCount Players • $skill',
                      style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8E9E94)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.textGrey),
                tooltip: 'View Squad',
                onPressed: () => _showSquadRosterDialog(team),
              ),
            ],
          ),
          if (isCreator && status == 'Pending') ...[
            const Divider(color: Color(0xFF1E3224), height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateTeamStatus(tournament, regId, 'Rejected'),
                  child: Text('Reject', style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateTeamStatus(tournament, regId, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  child: Text('Approve', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateTeamStatus(Map<String, dynamic> tournament, dynamic regId, String newStatus) async {
    try {
      final dio = ref.read(dioClientProvider);
      final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
      await TournamentRepository.instance.updateRegistrationStatusOnBackend(
        dio,
        tournament['backendId'] ?? tournament['id'],
        regId,
        newStatus,
        currentUserId: currentUserId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration marked as $newStatus'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _confirmCancelRegistration(Map<String, dynamic> tournament, Map<String, dynamic> userTeam) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Registration?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to cancel your team "${userTeam['teamName']}" registration?',
          style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Registration', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Yes, Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(dioClientProvider);
        final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
        final regId = userTeam['backendId'] ?? userTeam['id'];
        await TournamentRepository.instance.cancelRegistrationOnBackend(
          dio,
          tournament['backendId'] ?? tournament['id'],
          regId,
          currentUserId: currentUserId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration cancelled successfully.'), backgroundColor: AppTheme.primaryGreen),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling registration: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ==========================================
  // TAB 1: FIXTURES (SHOW MATCHES & SCORE UPDATE)
  // ==========================================
  Widget _buildFixturesTab(Map<String, dynamic> tournament, bool isCreator, bool isBeforeStart) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

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
              child: const Icon(Icons.psychology_rounded, color: AppTheme.primaryGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'No Match Fixtures Generated Yet',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isCreator
                  ? 'As the creator/organizer, generate the tournament fixtures once registered teams are ready.'
                  : 'The tournament organizer will generate the match fixtures before the tournament begins.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94)),
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
                    'Generate Match Fixtures',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final filteredFixtures = fixtures.where((f) {
      if (_fixtureFilter == 'All') return true;
      if (_fixtureFilter == 'My Matches') return f['isUserMatch'] == true;
      return f['stageGroup'] == _fixtureFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips
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

        if (filteredFixtures.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No matches found in "$_fixtureFilter"',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
            ),
          )
        else
          ...filteredFixtures.map((f) => _buildFixtureCard(tournament, f, isCreator)),
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

  Widget _buildFixtureCard(Map<String, dynamic> tournament, Map<String, dynamic> f, bool isCreator) {
    final matchNo = f['matchNumber'];
    final stage = f['stage'] as String? ?? 'Match $matchNo';
    final time = f['time'] as String? ?? 'TBD';
    final venue = f['venue'] as String? ?? 'Pitch A';
    final t1 = f['t1'] as String? ?? 'Team 1';
    final t2 = f['t2'] as String? ?? 'Team 2';
    final t1Score = f['t1Score'];
    final t2Score = f['t2Score'];
    final winnerName = f['winnerName'] as String?;
    final matchStatus = f['status'] as String? ?? 'upcoming';
    final isCompleted = matchStatus == 'completed' || winnerName != null;
    final isUserMatch = f['isUserMatch'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUserMatch ? const Color(0xFF102619) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUserMatch ? AppTheme.primaryGreen : AppTheme.cardBorder,
          width: isUserMatch ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stage, Match #, Time, Status
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.blueAccent.withValues(alpha: 0.15)
                      : matchStatus == 'live'
                          ? Colors.orangeAccent.withValues(alpha: 0.15)
                          : const Color(0xFF1E3224),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.blueAccent
                        : matchStatus == 'live'
                            ? Colors.orangeAccent
                            : AppTheme.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : matchStatus == 'live' ? 'LIVE' : 'UPCOMING',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.blueAccent
                        : matchStatus == 'live'
                            ? Colors.orangeAccent
                            : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams Clash: T1 vs T2 with scores
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
                        (f['t1Tag'] as String? ?? 'T1').takeFirstLetters(3),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
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
                        color: winnerName == t1 ? AppTheme.primaryGreen : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // VS Chip / Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    if (t1Score != null && t2Score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
                        ),
                        child: Text(
                          '$t1Score - $t2Score',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      )
                    else
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
                    if (winnerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Winner: $winnerName',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
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
                        (f['t2Tag'] as String? ?? 'T2').takeFirstLetters(3),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black),
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
                        color: winnerName == t2 ? AppTheme.primaryGreen : Colors.white,
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
                const Icon(Icons.access_time_filled_rounded, color: AppTheme.primaryGreen, size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$time  •  $venue',
                    style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8E9E94)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Creator Score Entry Action
          if (isCreator) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () => _showUpdateScoreDialog(tournament, f),
                icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primaryGreen),
                label: Text(
                  isCompleted ? 'Edit Score & Outcome' : 'Enter Match Score',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: STANDINGS
  // ==========================================
  Widget _buildStandingsTab(Map<String, dynamic> tournament) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

    final completedMatches = fixtures.where((f) => f['status'] == 'completed' || f['winnerName'] != null).toList();

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
              Text('Tournament Standings',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '${completedMatches.length} Matches Concluded',
                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(color: AppTheme.cardBorder, height: 20),
          if (completedMatches.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.leaderboard_outlined, size: 36, color: AppTheme.textGrey),
                    const SizedBox(height: 8),
                    Text(
                      'No matches completed yet.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    Text(
                      'Live match standings and winner points will update here as matches are played.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF6E7E74)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...completedMatches.map((m) {
              final t1 = m['t1'] as String? ?? 'Team 1';
              final t2 = m['t2'] as String? ?? 'Team 2';
              final s1 = m['t1Score'] ?? 0;
              final s2 = m['t2Score'] ?? 0;
              final winner = m['winnerName'] as String? ?? (s1 > s2 ? t1 : t2);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF142419),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$t1 vs $t2',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$s1 - $s2 ($winner Wins)',
                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: BRACKETS (DYNAMIC BACKEND KNOCKOUT TREE)
  // ==========================================
  Widget _buildBracketsTab(Map<String, dynamic> tournament) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

    if (fixtures.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_tree_outlined, size: 40, color: AppTheme.textGrey),
            const SizedBox(height: 10),
            Text(
              'Brackets not generated yet.',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Once the tournament organizer generates fixtures, the live bracket tree will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

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
                style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Bracket',
                  style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quarter Finals
          if (qfMatches.isNotEmpty) ...[
            Text('QUARTER FINALS',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            ...qfMatches.map((m) => _bracketMatch(
                  m['stage'] as String? ?? 'QF',
                  m['t1'] as String? ?? 'Team 1',
                  m['t2'] as String? ?? 'Team 2',
                  winner: m['winnerName'] as String?,
                )),
            const Divider(color: AppTheme.primaryGreen, height: 28),
          ],

          // Semi Finals
          if (sfMatches.isNotEmpty) ...[
            Text('SEMI FINALS',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            ...sfMatches.map((m) => _bracketMatch(
                  m['stage'] as String? ?? 'SF',
                  m['t1'] as String? ?? 'Winner QF',
                  m['t2'] as String? ?? 'Winner QF',
                  winner: m['winnerName'] as String?,
                )),
            const Divider(color: AppTheme.primaryGreen, height: 28),
          ],

          // Grand Final
          Text('GRAND CHAMPIONSHIP FINAL',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 8),
          _bracketMatch(
            'FINAL',
            finalMatch?['t1'] as String? ?? 'Winner SF 1',
            finalMatch?['t2'] as String? ?? 'Winner SF 2',
            winner: finalMatch?['winnerName'] as String?,
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
    String? winner,
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? AppTheme.primaryGreen : AppTheme.cardBorder,
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
          if (winner != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Winner: $winner',
                style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: RESULTS (REAL COMPLETED MATCHES)
  // ==========================================
  Widget _buildResultsTab(Map<String, dynamic> tournament) {
    final fixtures = (tournament['fixtures'] as List? ?? [])
        .map((f) => Map<String, dynamic>.from(f as Map))
        .toList();

    final completed = fixtures.where((f) => f['status'] == 'completed' || f['winnerName'] != null).toList();

    if (completed.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.verified_outlined, size: 40, color: AppTheme.textGrey),
            const SizedBox(height: 10),
            Text(
              'No completed matches yet.',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Final match scores, winners, and MVP stats will display here once matches finish.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: completed.map((r) {
        final t1 = r['t1'] as String? ?? 'Team 1';
        final t2 = r['t2'] as String? ?? 'Team 2';
        final s1 = r['t1Score'] ?? 0;
        final s2 = r['t2Score'] ?? 0;
        final winner = r['winnerName'] as String? ?? (s1 > s2 ? t1 : t2);
        final stage = r['stage'] as String? ?? 'Match';

        return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$t1 vs $t2',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$stage • Winner: $winner',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$s1 - $s2',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Register Team Button
  Widget _buildRegisterButton(Map<String, dynamic> tournament, int filled, int total) {
    final isFull = filled >= total;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isFull
            ? null
            : () {
                context.push('/tournament-register', extra: tournament);
              },
        icon: Icon(
          isFull ? Icons.block : Icons.app_registration_rounded,
          color: isFull ? Colors.white38 : Colors.black,
          size: 20,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFull ? const Color(0xFF223026) : AppTheme.primaryGreen,
          foregroundColor: isFull ? Colors.white38 : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        label: Text(
          isFull ? 'Tournament Slots Full' : 'Register Your Team Now',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: ROSTER
  // ==========================================
  void _showSquadRosterDialog(Map<String, dynamic> team) {
    final teamName = team['teamName'] as String? ?? 'Team Squad';
    final captain = team['captainName'] as String? ?? 'Captain';
    final tag = team['teamTag'] as String? ?? 'TM';
    final jersey = team['jerseyColor'] as String? ?? 'Neon Green';
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
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamName, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Captain: $captain', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E3224), height: 24),
              Text('Squad Members (${players.length})', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: players.length,
                  itemBuilder: (_, i) {
                    final p = players[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1B3022),
                        child: Text('${i + 1}', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(p['name'] as String? ?? 'Player ${i + 1}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5)),
                      subtitle: Text(p['role'] as String? ?? 'Player', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10.5)),
                      trailing: Text('#${p['jersey'] ?? '-'}', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
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
  // MODAL: AI FIXTURE GENERATOR (CREATOR ONLY)
  // ==========================================
  void _showAIFixtureDialog(Map<String, dynamic> tournament) {
    String selectedStrategy = 'balanced';
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1B13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Generate Match Fixtures', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Generates real matches in database from approved teams', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94))),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E3224), height: 24),
              if (isGenerating) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryGreen),
                        SizedBox(height: 16),
                        Text('Generating fixtures in database...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Text('Fixture Strategy', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: selectedStrategy == 'balanced' ? const Color(0xFF183321) : Colors.transparent,
                  title: Text('Balanced Parity (Recommended)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Pairs teams of closest registered level', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                  leading: Radio<String>(
                    value: 'balanced',
                    groupValue: selectedStrategy,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setDialogState(() => selectedStrategy = v!),
                  ),
                  onTap: () => setDialogState(() => selectedStrategy = 'balanced'),
                ),
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: selectedStrategy == 'random' ? const Color(0xFF183321) : Colors.transparent,
                  title: Text('Random Draw', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Standard unseeded knockout pairings', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                  leading: Radio<String>(
                    value: 'random',
                    groupValue: selectedStrategy,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setDialogState(() => selectedStrategy = v!),
                  ),
                  onTap: () => setDialogState(() => selectedStrategy = 'random'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isGenerating = true);
                      try {
                        final dio = ref.read(dioClientProvider);
                        final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
                        final tournId = tournament['backendId'] ?? tournament['id'];
                        final newFixtures = await TournamentRepository.instance.generateFixturesOnBackend(
                          dio,
                          tournId,
                          strategy: selectedStrategy,
                          currentUserId: currentUserId,
                        );

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        setState(() => _selectedTab = 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 ${newFixtures.length} match fixtures generated successfully!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isGenerating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Generate & Save Fixtures', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: UPDATE MATCH SCORE (CREATOR ONLY)
  // ==========================================
  void _showUpdateScoreDialog(Map<String, dynamic> tournament, Map<String, dynamic> match) {
    final t1 = match['t1'] as String? ?? 'Team 1';
    final t2 = match['t2'] as String? ?? 'Team 2';
    final s1Ctrl = TextEditingController(text: '${match['t1Score'] ?? 0}');
    final s2Ctrl = TextEditingController(text: '${match['t2Score'] ?? 0}');
    String selectedStatus = match['status'] as String? ?? 'completed';
    if (selectedStatus != 'live' && selectedStatus != 'completed') selectedStatus = 'completed';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF101912),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Update Match Score', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Match #${match['matchNumber']} • ${match['stage']}',
                  style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11.5)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t1, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        TextField(
                          controller: s1Ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF182A1D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white54)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t2, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        TextField(
                          controller: s2Ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF182A1D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Match Status', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Live Match', style: GoogleFonts.poppins(fontSize: 11, color: selectedStatus == 'live' ? Colors.black : Colors.white)),
                    selected: selectedStatus == 'live',
                    selectedColor: Colors.orangeAccent,
                    onSelected: (v) => setDlgState(() => selectedStatus = 'live'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Completed', style: GoogleFonts.poppins(fontSize: 11, color: selectedStatus == 'completed' ? Colors.black : Colors.white)),
                    selected: selectedStatus == 'completed',
                    selectedColor: AppTheme.primaryGreen,
                    onSelected: (v) => setDlgState(() => selectedStatus = 'completed'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dlgCtx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDlgState(() => isSaving = true);
                      final score1 = int.tryParse(s1Ctrl.text.trim()) ?? 0;
                      final score2 = int.tryParse(s2Ctrl.text.trim()) ?? 0;
                      String? winner;
                      if (selectedStatus == 'completed') {
                        winner = score1 >= score2 ? t1 : t2;
                      }

                      try {
                        final dio = ref.read(dioClientProvider);
                        final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
                        final tournId = tournament['backendId'] ?? tournament['id'];
                        final matchId = match['backendId'] ?? match['id'];
                        await TournamentRepository.instance.updateMatchScoreOnBackend(
                          dio,
                          tournId,
                          matchId,
                          teamAScore: score1,
                          teamBScore: score2,
                          winnerName: winner,
                          status: selectedStatus,
                          currentUserId: currentUserId,
                        );
                        if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Match score updated and winner advanced!'), backgroundColor: AppTheme.primaryGreen),
                        );
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: Text(isSaving ? 'Saving...' : 'Save Score', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: EDIT TOURNAMENT DETAILS (CREATOR ONLY)
  // ==========================================
  void _showEditTournamentDialog(Map<String, dynamic> tournament) {
    final titleCtrl = TextEditingController(text: tournament['name'] ?? '');
    final venueCtrl = TextEditingController(text: tournament['venue'] ?? '');
    final prizeCtrl = TextEditingController(text: '${tournament['prizePoolAmount'] ?? 50000}');
    final feeCtrl = TextEditingController(text: '${tournament['entryFeeAmount'] ?? 0}');
    final rulesCtrl = TextEditingController(text: tournament['rules'] ?? '');
    String selectedStatus = tournament['status'] ?? 'Open Entry';
    bool isSaving = false;

    final statuses = ['Open Entry', 'Upcoming', 'Ongoing (Live)', 'Completed', 'Cancelled'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1B13),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (editCtx) => StatefulBuilder(
        builder: (editCtx, setEditState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(editCtx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manage & Edit Tournament', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(editCtx),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E3224)),
                const SizedBox(height: 8),

                // Name
                Text('Tournament Name', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                const SizedBox(height: 4),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF182A1D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Venue
                Text('Venue / Location', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                const SizedBox(height: 4),
                TextField(
                  controller: venueCtrl,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF182A1D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Status
                Text('Tournament Status', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: statuses.map((st) {
                    final sel = selectedStatus == st;
                    return ChoiceChip(
                      label: Text(st, style: GoogleFonts.poppins(fontSize: 10.5, color: sel ? Colors.black : Colors.white)),
                      selected: sel,
                      selectedColor: AppTheme.primaryGreen,
                      onSelected: (v) => setEditState(() => selectedStatus = st),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Prize Pool & Entry Fee
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Prize Pool (₹)', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: prizeCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF182A1D),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entry Fee (₹)', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: feeCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF182A1D),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rules
                Text('Tournament Rules', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94))),
                const SizedBox(height: 4),
                TextField(
                  controller: rulesCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF182A1D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setEditState(() => isSaving = true);
                            try {
                              final dio = ref.read(dioClientProvider);
                              final currentUserId = ref.read(fetchUserProfileProvider).valueOrNull?.id;
                              final tournId = tournament['backendId'] ?? tournament['id'];
                              final updates = {
                                'title': titleCtrl.text.trim(),
                                'venue': venueCtrl.text.trim(),
                                'prize_pool': double.tryParse(prizeCtrl.text.trim()) ?? 50000.0,
                                'entry_fee': double.tryParse(feeCtrl.text.trim()) ?? 0.0,
                                'status': selectedStatus,
                                'rules': rulesCtrl.text.trim(),
                              };
                              await TournamentRepository.instance.updateTournamentOnBackend(
                                dio,
                                tournId,
                                updates,
                                currentUserId: currentUserId,
                              );
                              if (editCtx.mounted) Navigator.pop(editCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tournament updated successfully!'), backgroundColor: AppTheme.primaryGreen),
                              );
                            } catch (e) {
                              setEditState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error updating tournament: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSaving ? 'Saving Updates...' : 'Save Tournament Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL: DELETE / CANCEL TOURNAMENT (CREATOR ONLY)
  // ==========================================
  void _showDeleteTournamentDialog(Map<String, dynamic> tournament) {
    showDialog(
      context: context,
      builder: (delCtx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Tournament?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete or cancel "${tournament['name']}"? If matches have already been generated, it will be marked as Cancelled.',
          style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(delCtx),
            child: Text('Dismiss', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(delCtx);
              try {
                final dio = ref.read(dioClientProvider);
                final tournId = tournament['backendId'] ?? tournament['id'];
                await TournamentRepository.instance.deleteOrCancelTournament(dio, tournId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tournament removed or cancelled.'), backgroundColor: AppTheme.primaryGreen),
                  );
                  context.go('/tournaments');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Yes, Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
