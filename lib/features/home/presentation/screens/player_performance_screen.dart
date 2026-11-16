import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class PlayerPerformanceScreen extends StatefulWidget {
  final String matchId;
  const PlayerPerformanceScreen({super.key, required this.matchId});

  @override
  State<PlayerPerformanceScreen> createState() => _PlayerPerformanceScreenState();
}

class _PlayerPerformanceScreenState extends State<PlayerPerformanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _matchDetails;
  Map<String, dynamic>? _matchStats;
  List<Map<String, dynamic>> _teamAPlayers = [];
  List<Map<String, dynamic>> _teamBPlayers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detailsFuture = MatchRepository.instance.fetchMatchDetails(widget.matchId);
      final statsFuture = MatchRepository.instance.fetchMatchStats(widget.matchId);

      final results = await Future.wait<Map<String, dynamic>?>([detailsFuture, statsFuture]);
      final details = results[0];
      final stats = results[1];

      if (mounted) {
        final participants = (details?['participants'] as List?) ?? [];
        List<Map<String, dynamic>> teamA = [];
        List<Map<String, dynamic>> teamB = [];

        for (final p in participants) {
          if (p is Map) {
            final team = (p['team'] ?? 'Team A').toString().toLowerCase();
            final name = p['player_name'] ?? 'Player';
            final role = p['player_role'] ?? 'Player';
            final jersey = p['jersey_number'] ?? '';

            final pMap = {
              'name': name,
              'role': role,
              'jersey': jersey,
              'goals': 0,
              'assists': 0,
              'points': 0,
            };

            if (team.contains('b')) {
              teamB.add(pMap);
            } else {
              teamA.add(pMap);
            }
          }
        }

        // Cross-reference with timeline/stats scorers if available
        final topScorers = (stats?['top_scorers'] as List?) ?? [];
        for (final sc in topScorers) {
          if (sc is Map) {
            final scName = (sc['player_name'] ?? '').toString();
            final goals = sc['goals'] ?? 0;
            for (final p in teamA) {
              if (p['name'] == scName) p['goals'] = goals;
            }
            for (final p in teamB) {
              if (p['name'] == scName) p['goals'] = goals;
            }
          }
        }

        setState(() {
          _matchDetails = details;
          _matchStats = stats;
          _teamAPlayers = teamA;
          _teamBPlayers = teamB;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load player performance';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamAName = _matchDetails?['team_a_name'] ?? 'Team A';
    final teamBName = _matchDetails?['team_b_name'] ?? 'Team B';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Player Performance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: [
            Tab(text: teamAName),
            Tab(text: teamBName),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: GoogleFonts.poppins(color: Colors.white70)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlayerList(_teamAPlayers, teamAName),
                      _buildPlayerList(_teamBPlayers, teamBName),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPlayerList(List<Map<String, dynamic>> players, String teamName) {
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No players registered in $teamName',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: AppTheme.surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Player', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
              Expanded(flex: 2, child: Text('Role', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
              Expanded(flex: 1, child: Text('Score', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final name = p['name'] ?? 'Player';
                final role = p['role'] ?? 'Player';
                final score = p['goals'] ?? 0;
                final jersey = p['jersey']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        child: Text(
                          jersey.isNotEmpty ? jersey : '${index + 1}',
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          role,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '$score',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
