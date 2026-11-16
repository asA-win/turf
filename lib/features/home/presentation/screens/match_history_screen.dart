import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allMatches = [];
  List<Map<String, dynamic>> _hostedMatches = [];
  List<Map<String, dynamic>> _joinedMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allFuture = MatchRepository.instance.fetchMatches(status: 'completed');
      final myCreatedFuture = MatchRepository.instance.fetchMyMatches(tab: 'created');
      final myJoinedFuture = MatchRepository.instance.fetchMyMatches(tab: 'completed');

      final results = await Future.wait<List<Map<String, dynamic>>>([allFuture, myCreatedFuture, myJoinedFuture]);

      if (mounted) {
        setState(() {
          _allMatches = results[0];
          _hostedMatches = results[1].where((m) => m['status'] == 'completed').toList();
          _joinedMatches = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load match history';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _currentList {
    switch (_tabController.index) {
      case 1:
        return _hostedMatches;
      case 2:
        return _joinedMatches;
      case 0:
      default:
        return _allMatches;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Match History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'All Matches'),
            Tab(text: 'Hosted'),
            Tab(text: 'Joined'),
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
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  )
                : _buildList(_currentList),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1F2F23)),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Completed Matches',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Matches you host or join will appear here with full scores and statistics once concluded.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/create-match'),
                    icon: const Icon(Icons.add, color: Colors.black, size: 18),
                    label: const Text('Create a Match', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final m = list[index];
          final matchId = m['id']?.toString() ?? '';
          final teamA = m['team_a_name'] ?? 'Team A';
          final teamB = m['team_b_name'] ?? 'Team B';
          final scoreA = m['team_a_score'] ?? 0;
          final scoreB = m['team_b_score'] ?? 0;
          final venue = m['venue_name'] ?? m['location'] ?? 'Turf Arena';
          final date = m['match_date'] ?? '';
          final time = m['match_time'] ?? '';
          final sport = (m['sport_type'] ?? 'Match').toString().toUpperCase();

          String outcomeText = 'Draw';
          Color outcomeColor = Colors.orange;
          if (scoreA > scoreB) {
            outcomeText = '$teamA Won';
            outcomeColor = AppTheme.primaryGreen;
          } else if (scoreB > scoreA) {
            outcomeText = '$teamB Won';
            outcomeColor = Colors.lightBlueAccent;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () => context.push('/match-summary/$matchId'),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sport,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGrey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$teamA vs $teamB',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      '$date${time.isNotEmpty ? " • $time" : ""}',
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$scoreA - $scoreB',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: outcomeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      outcomeText,
                      style: GoogleFonts.poppins(color: outcomeColor, fontWeight: FontWeight.bold, fontSize: 10.5),
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
}
