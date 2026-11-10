import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ActiveMatchesScreen extends ConsumerStatefulWidget {
  const ActiveMatchesScreen({super.key});

  @override
  ConsumerState<ActiveMatchesScreen> createState() => _ActiveMatchesScreenState();
}

class _ActiveMatchesScreenState extends ConsumerState<ActiveMatchesScreen> with SingleTickerProviderStateMixin {
  String _selectedSport = 'All';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _scoreboardSub;
  final CancelToken _cancelToken = CancelToken();
  bool _isLoading = false;

  final List<String> _sportsFilter = ['All', 'Football', 'Cricket', 'Badminton', 'Basketball'];

  List<Map<String, dynamic>> _matches = [
    {
      'id': 101,
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'teamA': 'Turf Titans',
      'teamB': 'Kickers United',
      'scoreA': '2',
      'scoreB': '1',
      'minute': 'Live',
      'liveStatus': 'Match In Progress',
      'venue': 'Play Arena (Pitch 1)',
      'location': 'Koramangala, Bengaluru',
      'playersCount': 10,
      'latestEvent': 'Live on-pitch action',
      'scoreboardConfig': {
        'sport': 'football',
        'turfName': 'Play Arena',
        'teamA': 'Turf Titans',
        'teamB': 'Kickers United',
      },
      'isLiveSync': true,
    },
  ];

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'badminton':
        return Icons.sports_tennis_rounded;
      case 'basketball':
        return Icons.sports_basketball_rounded;
      case 'tennis':
        return Icons.sports_tennis_rounded;
      default:
        return Icons.sports_soccer_rounded;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'cricket':
        return const Color(0xFFFF9800);
      case 'badminton':
        return const Color(0xFF10B981);
      case 'basketball':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  Future<void> _loadMatchesFromBackend() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.get('/matches/', cancelToken: _cancelToken);
      final data = res.data;
      if (data is List && data.isNotEmpty) {
        final List<Map<String, dynamic>> loaded = [];
        for (final item in data) {
          final sport = (item['sport_type'] as String? ?? 'Football');
          final turf = item['turf'] as Map<String, dynamic>?;
          final turfName = turf?['name'] ?? 'Play Arena';
          final location = turf?['location'] ?? 'Bengaluru';
          loaded.add({
            'id': item['id'],
            'sport': sport,
            'sportIcon': _getSportIcon(sport),
            'accentColor': _getSportColor(sport),
            'teamA': item['team_a_name'] ?? 'Team A',
            'teamB': item['team_b_name'] ?? 'Team B',
            'scoreA': (item['team_a_score'] ?? 0).toString(),
            'scoreB': (item['team_b_score'] ?? 0).toString(),
            'minute': item['status'] == 'live' ? "Live" : (item['status'] ?? "Live"),
            'liveStatus': item['status'] == 'live' ? 'Match In Progress' : 'Certified Turf Match',
            'venue': turfName,
            'location': location,
            'playersCount': 10,
            'latestEvent': 'Live on-pitch action',
            'scoreboardConfig': {
              'sport': sport.toLowerCase(),
              'turfName': turfName,
              'teamA': item['team_a_name'] ?? 'Team A',
              'teamB': item['team_b_name'] ?? 'Team B',
            },
            'isLiveSync': true,
          });
        }
        if (mounted) {
          setState(() {
            _matches = loaded;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading active matches from backend: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadMatchesFromBackend();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scoreboardSub = ref.read(realtimeServiceProvider).connectToChannel('scoreboard').listen((event) {
      final eventType = event['type'] as String?;
      if (eventType == 'new_match') {
        _loadMatchesFromBackend();
        return;
      }
      if (eventType == 'score_update') {
        final teamA = event['teamA'] as String?;
        final teamB = event['teamB'] as String?;
        final sport = event['sport'] as String?;
        final scoreA = event['scoreA']?.toString();
        final scoreB = event['scoreB']?.toString();
        final eventDesc = event['event'] as String?;
        final timeStr = event['time'] as String?;

        if (mounted) {
          setState(() {
            int matchIdx = _matches.indexWhere((m) {
              if (teamA != null && (m['teamA'] as String).toLowerCase().contains(teamA.toLowerCase())) return true;
              if (teamB != null && (m['teamB'] as String).toLowerCase().contains(teamB.toLowerCase())) return true;
              return false;
            });

            if (matchIdx != -1) {
              if (scoreA != null) _matches[matchIdx]['scoreA'] = scoreA;
              if (scoreB != null) _matches[matchIdx]['scoreB'] = scoreB;
              if (eventDesc != null) _matches[matchIdx]['latestEvent'] = eventDesc;
              if (timeStr != null) _matches[matchIdx]['minute'] = timeStr;
              _matches[matchIdx]['isLiveSync'] = true;
            } else if (teamA != null && teamB != null) {
              _matches.insert(0, {
                'id': DateTime.now().millisecondsSinceEpoch,
                'sport': (sport != null && sport.isNotEmpty) ? sport[0].toUpperCase() + sport.substring(1) : 'Football',
                'sportIcon': _getSportIcon(sport ?? 'Football'),
                'accentColor': _getSportColor(sport ?? 'Football'),
                'teamA': teamA,
                'teamB': teamB,
                'scoreA': scoreA ?? '0',
                'scoreB': scoreB ?? '0',
                'minute': timeStr ?? "Just now",
                'liveStatus': 'Live in Progress',
                'venue': 'Play Arena (Pitch 1)',
                'location': 'Bengaluru',
                'playersCount': 10,
                'latestEvent': eventDesc ?? 'Match in progress',
                'scoreboardConfig': {
                  'sport': sport ?? 'football',
                  'teamA': teamA,
                  'teamB': teamB,
                },
                'isLiveSync': true,
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _scoreboardSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedSport == 'All'
        ? _matches
        : _matches.where((m) => m['sport'] == _selectedSport).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C140F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Active Matches',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FadeTransition(
                      opacity: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF3B30), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF3B30),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_matches.length} matches happening right now on turfs',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF8E9E94),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Match Stats & Top Scorers',
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 22),
            onPressed: () => context.push('/stats'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sports Filter Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sportsFilter.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sport = _sportsFilter[index];
                  final isSelected = _selectedSport == sport;
                  final count = sport == 'All'
                      ? _matches.length
                      : _matches.where((m) => m['sport'] == sport).length;

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
                      child: Row(
                        children: [
                          Text(
                            sport,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.black : const Color(0xFFCFDBD2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF1C2D22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Matches List
            Expanded(
              child: _isLoading && _matches.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.cardDark,
                      onRefresh: _loadMatchesFromBackend,
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.sports_soccer_outlined, color: Colors.white24, size: 56),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No active matches in $_selectedSport',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pull down to refresh or select another category',
                                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final match = filtered[index];
                                return _buildLiveMatchCard(context, match);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMatchCard(BuildContext context, Map<String, dynamic> match) {
    final accentColor = match['accentColor'] as Color;
    final config = match['scoreboardConfig'] as Map<String, dynamic>? ?? {};

    return GestureDetector(
      onTap: () {
        context.push('/scoreboard', extra: <String, dynamic>{
          ...config,
          'isViewOnly': true,
          'readOnly': true,
        });
      },
      child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1D2E22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sport Chip + Venue & Location + Pulsing LIVE badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF132017),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(match['sportIcon'] as IconData, size: 14, color: accentColor),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['venue'] as String,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: Colors.white,
                          ),
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
                  ],
                ),
                // Pulsing Live Indicator
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF3B30), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match['minute'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Match Scoreboard Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Team A
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2C20),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            (match['teamA'] as String).substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match['teamA'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Score Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF09120B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF233827)),
                        ),
                        child: Text(
                          '${match['scoreA']}  -  ${match['scoreB']}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        match['liveStatus'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9FB2A5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Team B
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2C20),
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            (match['teamB'] as String).substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match['teamB'] as String,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Latest Event Ticker Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF152219),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF213626)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFFD600), size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match['latestEvent'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFFCFDBD2),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Open Scoreboard CTA
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.push('/scoreboard', extra: <String, dynamic>{
                        ...config,
                        'isViewOnly': true,
                        'readOnly': true,
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.scoreboard_outlined, size: 16, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          'View Live Scorecard',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Stats CTA
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2A4232)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.push('/stats', extra: match);
                    },
                    icon: const Icon(Icons.analytics_outlined, color: Colors.white70, size: 15),
                    label: Text(
                      'Stats',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Match Timeline CTA
                GestureDetector(
                  onTap: () {
                    context.push('/match-timeline/${match['id']}');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16251B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF253B2B)),
                    ),
                    child: const Icon(Icons.timeline_rounded, color: Colors.white70, size: 16),
                  ),
                ),
                const SizedBox(width: 6),

                // Share Button
                GestureDetector(
                  onTap: () {
                    context.push('/share-match/${match['id']}');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16251B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF253B2B)),
                    ),
                    child: const Icon(Icons.share_outlined, color: Colors.white70, size: 16),
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
