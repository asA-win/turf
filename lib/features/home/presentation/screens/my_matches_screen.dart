import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/presentation/widgets/match_sport_select_sheet.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final dio = ref.read(dioClientProvider);
    final user = ref.read(currentUserProvider);
    final userId = user?.id;

    MatchRepository.instance.fetchMatches(dio: dio, currentUserId: userId);
    MatchRepository.instance.fetchMyMatches(dio: dio, currentUserId: userId);
    MatchRepository.instance.connectScoreboardWebSocket(currentUserId: userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MatchRepository.instance;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final all = _filterBySport(repo.allMatches);
        final live = _filterBySport(repo.liveMatches);
        final upcoming = _filterBySport(repo.upcomingMatches);
        final completed = _filterBySport(repo.completedMatches);
        final myCreated = _filterBySport(repo.myCreatedMatches);

        return Scaffold(
          backgroundColor: const Color(0xFF070B08),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C140F),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Matches & Scoreboard',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Live games, creator dashboard & scorecards',
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                tooltip: 'Create Match',
                onPressed: () async {
                  await context.push('/create-match');
                  _loadData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Refresh',
                onPressed: _loadData,
              ),
              const BysProfileAvatar(size: 32),
              const SizedBox(width: 12),
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
                Tab(text: 'All (${all.length})'),
                Tab(text: 'Live (${live.length})'),
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Completed (${completed.length})'),
                Tab(text: 'Created by Me (${myCreated.length})'),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // 1. Sport Filter Chips
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
                  child: repo.isLoading && all.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMatchesList(all, emptyTitle: 'No matches found', emptySubtitle: 'Create a match or explore open games to play!'),
                            _buildMatchesList(live, emptyTitle: 'No live matches right now', emptySubtitle: 'Start a match scoreboard to see it live!'),
                            _buildMatchesList(upcoming, emptyTitle: 'No upcoming scheduled matches', emptySubtitle: 'Host a game and invite players!'),
                            _buildMatchesList(completed, emptyTitle: 'No completed match records', emptySubtitle: 'Finished matches and scores will appear here.'),
                            _buildMatchesList(myCreated, isCreatorTab: true, emptyTitle: 'You have not created any matches yet', emptySubtitle: 'Tap "Create Match" above to host your first game!'),
                          ],
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const BysBottomNavBar(currentIndex: -1),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterBySport(List<Map<String, dynamic>> list) {
    if (_selectedSport == 'All') return list;
    return list.where((m) => (m['sport']?.toString().toLowerCase() == _selectedSport.toLowerCase())).toList();
  }

  Widget _buildMatchesList(
    List<Map<String, dynamic>> matches, {
    bool isCreatorTab = false,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_soccer_rounded, color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/create-match');
                  _loadData();
                },
                icon: const Icon(Icons.add, color: Colors.black, size: 18),
                label: Text(
                  'Create a Match',
                  style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: AppTheme.primaryGreen,
      backgroundColor: const Color(0xFF101912),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: matches.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildQuickScoreboardBanner();
          }
          final match = matches[index - 1];
          final isLive = match['isLive'] == true;
          if (isLive) {
            return _buildLiveMatchCard(match);
          }
          return _buildStandardMatchCard(match, isCreatorTab: isCreatorTab);
        },
      ),
    );
  }

  // Quick Scoreboard Hero Banner
  Widget _buildQuickScoreboardBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  'Launch Instant Scoreboard',
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

  // Live Match Card
  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final isCreator = match['isCreator'] == true;
    final config = Map<String, dynamic>.from(match['scoreboardConfig'] as Map? ?? {});
    config['id'] = match['backendId'];
    config['backendId'] = match['backendId'];
    config['isCreator'] = isCreator;
    config['isViewOnly'] = !isCreator;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
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
                      'MATCH IN PROGRESS • LIVE',
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
                  match['turfName']?.toString() ?? 'Play Arena',
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
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match['teamA']?.toString() ?? 'Team A',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match['scoreA']?.toString() ?? '0',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2F22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('VS', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match['teamB']?.toString() ?? 'Team B',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match['scoreB']?.toString() ?? '0',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/scoreboard', extra: config);
                          },
                          icon: Icon(
                            isCreator ? Icons.edit_note_rounded : Icons.visibility_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                          label: Text(
                            isCreator ? 'Manage Scoreboard' : 'Spectate Live Match',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/match-details/${match['backendId']}');
                          },
                          icon: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                          label: Text(
                            'Details',
                            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2A4232)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Standard Match Card (Upcoming or Completed)
  Widget _buildStandardMatchCard(Map<String, dynamic> match, {bool isCreatorTab = false}) {
    final isCompleted = match['isCompleted'] == true;
    final isCreator = match['isCreator'] == true;
    final sportColor = match['accentColor'] as Color? ?? AppTheme.primaryGreen;
    final icon = match['sportIcon'] as IconData? ?? Icons.sports_soccer_rounded;
    final title = match['title']?.toString() ?? 'Match';
    final dateStr = match['date']?.toString() ?? 'Upcoming';
    final venue = match['turfName']?.toString() ?? 'Play Arena';
    final result = match['result']?.toString() ?? 'SCHEDULED';
    final resultColor = match['resultColor'] as Color? ?? const Color(0xFF29B6F6);

    final config = Map<String, dynamic>.from(match['scoreboardConfig'] as Map? ?? {});
    config['id'] = match['backendId'];
    config['backendId'] = match['backendId'];
    config['isCreator'] = isCreator;
    config['isViewOnly'] = !isCreator;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCreatorTab ? AppTheme.primaryGreen.withValues(alpha: 0.5) : const Color(0xFF1B2C20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: sportColor),
                    const SizedBox(width: 6),
                    Text(
                      match['sport']?.toString() ?? 'Sport',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: sportColor),
                    ),
                    Text(' • $venue', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    result,
                    style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: resultColor),
                  ),
                ),
              ],
            ),
          ),

          // Teams and Score Row
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
                    match['teamA']?.toString() ?? 'Team Alpha',
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
                    isCompleted ? (match['scoreDisplay']?.toString() ?? '0 - 0') : 'VS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? AppTheme.primaryGreen : const Color(0xFF8E9E94),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match['teamB']?.toString() ?? 'Team Beta',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCompleted && match['mvp'] != null
                      ? '⭐ MVP: ${match['mvp']}'
                      : 'Roster: ${match['currentPlayers'] ?? 1}/${match['maxPlayers'] ?? 10} Players',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: isCompleted ? const Color(0xFFFFD600) : const Color(0xFF8E9E94),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(dateStr, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey)),
              ],
            ),
          ),

          const Divider(color: Color(0xFF19281D), height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/scoreboard', extra: config);
                    },
                    icon: Icon(
                      isCreator ? Icons.edit_note_rounded : Icons.scoreboard_rounded,
                      size: 15,
                      color: AppTheme.primaryGreen,
                    ),
                    label: Text(
                      isCreator ? 'Manage Scoreboard' : 'Scoreboard',
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
                    onPressed: () {
                      context.push('/match-details/${match['backendId']}');
                    },
                    icon: const Icon(Icons.info_outline, size: 15, color: Colors.white70),
                    label: Text(
                      'Match Details',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E2F22)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (isCreator) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    tooltip: 'Delete Match',
                    onPressed: () => _confirmDeleteMatch(match['backendId']),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMatch(dynamic matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Match', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete this match?',
          style: GoogleFonts.poppins(color: const Color(0xFFCFDBD2), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final dio = ref.read(dioClientProvider);
                await MatchRepository.instance.deleteMatch(matchId, dio: dio);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
