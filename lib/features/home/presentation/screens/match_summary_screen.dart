import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class MatchSummaryScreen extends StatefulWidget {
  final String matchId;
  const MatchSummaryScreen({super.key, required this.matchId});

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _match;

  @override
  void initState() {
    super.initState();
    _loadMatchSummary();
  }

  Future<void> _loadMatchSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await MatchRepository.instance.fetchMatchDetails(widget.matchId);
      if (mounted) {
        setState(() {
          _match = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load match summary';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Match Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null || _match == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'Match not found', style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMatchSummary,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    final venue = _match!['venue_name'] ?? _match!['location'] ?? 'Turf Arena';
    final teamA = _match!['team_a_name'] ?? 'Team A';
    final teamB = _match!['team_b_name'] ?? 'Team B';
    final scoreA = _match!['team_a_score'] ?? 0;
    final scoreB = _match!['team_b_score'] ?? 0;
    final sport = _match!['sport_type'] ?? 'Sports';
    final format = _match!['format'] ?? 'Friendly';
    final date = _match!['match_date'] ?? '';
    final time = _match!['match_time'] ?? '';
    final mvp = _match!['mvp_player_name'] ?? 'Not awarded';
    final mvpNotes = _match!['mvp_notes'] ?? '';
    final players = '${_match!['current_players_count'] ?? 0} / ${_match!['max_players'] ?? 0}';
    final duration = '${_match!['duration_minutes'] ?? 60} Mins';
    final status = (_match!['status'] ?? 'Scheduled').toString().toUpperCase();

    return RefreshIndicator(
      onRefresh: _loadMatchSummary,
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    venue,
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$sport • $format${date.isNotEmpty ? " • $date $time" : ""}',
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Text(
                          teamA,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Text(
                        '$scoreA - $scoreB',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 28),
                      ),
                      Expanded(
                        child: Text(
                          teamB,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.push('/stats', extra: <String, dynamic>{
                'sport': sport,
                'turfName': venue,
                'teamA': teamA,
                'teamB': teamB,
                'scoreDisplay': '$scoreA - $scoreB',
                'result': scoreA > scoreB ? '🏆 $teamA Won' : (scoreB > scoreA ? '🏆 $teamB Won' : 'Draw'),
                'mvp': mvpNotes.isNotEmpty ? '$mvp ($mvpNotes)' : mvp,
              }),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Icon(Icons.star_rounded, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Man of the Match / MVP', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                        Text(mvp, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        if (mvpNotes.isNotEmpty)
                          Text(mvpNotes, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _row('Total Players', players),
            _row('Duration', duration),
            _row('Skill Level', _match!['skill_level'] ?? 'All Levels'),
            _row('Price Per Player', _match!['price_per_player'] != null ? '₹${_match!['price_per_player']}' : 'Free'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/share-match/${widget.matchId}'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Share Match', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/stats', extra: <String, dynamic>{
                      'sport': sport,
                      'turfName': venue,
                      'teamA': teamA,
                      'teamB': teamB,
                      'scoreDisplay': '$scoreA - $scoreB',
                      'result': scoreA > scoreB ? '🏆 $teamA Won' : (scoreB > scoreA ? '🏆 $teamB Won' : 'Draw'),
                      'mvp': mvpNotes.isNotEmpty ? '$mvp ($mvpNotes)' : mvp,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Full Statistics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.push('/match-timeline/${widget.matchId}'),
                icon: const Icon(Icons.timeline_rounded, color: AppTheme.primaryGreen, size: 18),
                label: Text(
                  'View Match Timeline & Events',
                  style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
          Text(v, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
