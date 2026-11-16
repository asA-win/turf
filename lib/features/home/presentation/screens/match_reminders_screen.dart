import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class MatchRemindersScreen extends StatefulWidget {
  const MatchRemindersScreen({super.key});

  @override
  State<MatchRemindersScreen> createState() => _MatchRemindersScreenState();
}

class _MatchRemindersScreenState extends State<MatchRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _upcomingMatches = [];
  List<Map<String, dynamic>> _pastMatches = [];
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadReminders();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final upcoming = await MatchRepository.instance.fetchMatches(status: 'scheduled');
      final completed = await MatchRepository.instance.fetchMatches(status: 'completed');

      if (mounted) {
        setState(() {
          _upcomingMatches = upcoming;
          _pastMatches = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load match schedule';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCountdown(String? matchDate, String? matchTime) {
    if (matchDate == null || matchDate.isEmpty) return '00 : 00 : 00';
    try {
      DateTime targetDate = DateTime.parse(matchDate);
      if (matchTime != null && matchTime.contains(':')) {
        final parts = matchTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;
        targetDate = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
      }
      final diff = targetDate.difference(DateTime.now());
      if (diff.isNegative) return '00 : 00 : 00';
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours : $minutes : $seconds';
    } catch (_) {
      return '00 : 00 : 00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Match Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            onPressed: _loadReminders,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'Upcoming Matches'),
            Tab(text: 'Past Matches'),
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
                          onPressed: _loadReminders,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text('Retry', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUpcomingList(),
                      _buildPastList(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildUpcomingList() {
    if (_upcomingMatches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReminders,
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
                    child: const Icon(Icons.alarm_on_rounded, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Upcoming Matches Scheduled',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Host or join scheduled matches to receive live countdown reminders and kickoff alerts.',
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
      onRefresh: _loadReminders,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _upcomingMatches.length,
        itemBuilder: (context, index) {
          final m = _upcomingMatches[index];
          final teamA = m['team_a_name'] ?? 'Team A';
          final teamB = m['team_b_name'] ?? 'Team B';
          final venue = m['venue_name'] ?? m['location'] ?? 'Turf Arena';
          final date = m['match_date'] ?? '';
          final time = m['match_time'] ?? '';
          final countdown = _formatCountdown(date, time);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                Text(
                  '${date.isNotEmpty ? "$date • " : ""}$time',
                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                ),
                Text(
                  venue,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(teamA, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Text(teamB, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  countdown,
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 2),
                ),
                Text(
                  'HRS  MINS  SECS',
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reminder active for $teamA vs $teamB!'),
                              backgroundColor: const Color(0xFF1E2C22),
                            ),
                          );
                        },
                        icon: const Icon(Icons.alarm_on, color: Colors.black, size: 18),
                        label: const Text('Reminder Set', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/match-details/${m['id']}'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        child: Text('Details', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPastList() {
    if (_pastMatches.isEmpty) {
      return Center(
        child: Text(
          'No past match records found',
          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pastMatches.length,
      itemBuilder: (context, index) {
        final m = _pastMatches[index];
        return ListTile(
          onTap: () => context.push('/match-summary/${m['id']}'),
          title: Text('${m['team_a_name']} vs ${m['team_b_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(m['venue_name'] ?? 'Turf', style: const TextStyle(color: AppTheme.textGrey)),
          trailing: Text('${m['team_a_score']} - ${m['team_b_score']}', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
