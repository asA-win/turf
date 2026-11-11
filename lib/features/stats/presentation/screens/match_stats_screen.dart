import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchStatsScreen extends StatefulWidget {
  final String? matchId;
  final Map<String, dynamic>? matchData;

  const MatchStatsScreen({
    super.key,
    this.matchId,
    this.matchData,
  });

  @override
  State<MatchStatsScreen> createState() => _MatchStatsScreenState();
}

class _MatchStatsScreenState extends State<MatchStatsScreen> {
  late String _currentSport;
  int _selectedTeamTab = 0; // 0: All, 1: Team A, 2: Team B
  StreamSubscription<Map<String, dynamic>>? _scoreboardSub;
  String? _liveScoreDisplay;

  @override
  void initState() {
    super.initState();
    _currentSport = _resolveInitialSport();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final container = ProviderScope.containerOf(context, listen: false);
        final realtime = container.read(realtimeServiceProvider);
        _scoreboardSub = realtime.connectToChannel('scoreboard').listen((data) {
          if (!mounted) return;
          final type = data['type'] as String?;
          if (type == 'score_update') {
            final a = data['team_a_score'] ?? data['scoreA'];
            final b = data['team_b_score'] ?? data['scoreB'];
            if (a != null && b != null) {
              setState(() {
                _liveScoreDisplay = '$a vs $b';
              });
            }
          }
        });
      } catch (_) {
        // Runs cleanly in widget unit tests without ProviderScope
      }
    });
  }

  @override
  void dispose() {
    _scoreboardSub?.cancel();
    super.dispose();
  }

  String _resolveInitialSport() {
    if (widget.matchData != null) {
      final s = (widget.matchData!['sport'] ??
              widget.matchData!['sportType'] ??
              widget.matchData!['sport_type'] ??
              '')
          .toString()
          .toLowerCase();
      if (s.contains('cricket')) return 'Cricket';
      if (s.contains('badminton')) return 'Badminton';
      if (s.contains('basketball')) return 'Basketball';
      if (s.contains('tennis')) return 'Badminton';
      if (s.contains('football') || s.contains('soccer')) return 'Football';
    }
    return 'Cricket'; // Default to Cricket for rich demonstration of wickets and runs
  }

  Color get _accentColor {
    switch (_currentSport) {
      case 'Cricket':
        return const Color(0xFFFF9800);
      case 'Football':
        return AppTheme.primaryGreen;
      case 'Badminton':
        return const Color(0xFF00E5FF);
      case 'Basketball':
        return const Color(0xFFFF7043);
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData get _sportIcon {
    switch (_currentSport) {
      case 'Cricket':
        return Icons.sports_cricket_rounded;
      case 'Football':
        return Icons.sports_soccer_rounded;
      case 'Badminton':
        return Icons.sports_tennis_rounded;
      case 'Basketball':
        return Icons.sports_basketball_rounded;
      default:
        return Icons.sports_score_rounded;
    }
  }

  // --- Dynamic Match Info Extraction ---
  String get _turfName {
    if (widget.matchData != null && widget.matchData!['turfName'] != null) {
      return widget.matchData!['turfName'].toString();
    }
    if (widget.matchData != null && widget.matchData!['venue'] != null) {
      return widget.matchData!['venue'].toString();
    }
    switch (_currentSport) {
      case 'Cricket':
        return 'Turf Nation Box Pitch';
      case 'Football':
        return 'Green Field Arena';
      case 'Badminton':
        return 'Victory Sports Arena';
      case 'Basketball':
        return 'Greenfield Court';
      default:
        return 'Apex Sports Arena';
    }
  }

  String get _teamAName {
    if (widget.matchData != null && widget.matchData!['teamA'] != null) {
      return widget.matchData!['teamA'].toString();
    }
    if (widget.matchData != null && widget.matchData!['team_a_name'] != null) {
      return widget.matchData!['team_a_name'].toString();
    }
    switch (_currentSport) {
      case 'Cricket':
        return 'Blaster XI';
      case 'Football':
        return 'Turf Titans';
      case 'Badminton':
        return 'Smashers (John & Dev)';
      case 'Basketball':
        return 'HSR Dunkers';
      default:
        return 'Team Alpha';
    }
  }

  String get _teamBName {
    if (widget.matchData != null && widget.matchData!['teamB'] != null) {
      return widget.matchData!['teamB'].toString();
    }
    if (widget.matchData != null && widget.matchData!['team_b_name'] != null) {
      return widget.matchData!['team_b_name'].toString();
    }
    switch (_currentSport) {
      case 'Cricket':
        return 'Royal Chalks';
      case 'Football':
        return 'Kickers United';
      case 'Badminton':
        return 'Shuttle Pro (Kiran & Raj)';
      case 'Basketball':
        return 'Metro Ballers';
      default:
        return 'Team Beta';
    }
  }

  String get _scoreDisplay {
    if (_liveScoreDisplay != null) return _liveScoreDisplay!;
    if (widget.matchData != null && widget.matchData!['scoreDisplay'] != null) {
      return widget.matchData!['scoreDisplay'].toString();
    }
    if (widget.matchData != null &&
        widget.matchData!['scoreA'] != null &&
        widget.matchData!['scoreB'] != null) {
      return '${widget.matchData!['scoreA']} vs ${widget.matchData!['scoreB']}';
    }
    switch (_currentSport) {
      case 'Cricket':
        return '88/4 (8.0 ov) vs 72/6 (8.0 ov)';
      case 'Football':
        return '4 - 2';
      case 'Badminton':
        return '21-18, 19-21, 21-15';
      case 'Basketball':
        return '68 - 62';
      default:
        return '3 - 1';
    }
  }

  String get _resultBanner {
    if (widget.matchData != null && widget.matchData!['result'] != null) {
      return widget.matchData!['result'].toString();
    }
    switch (_currentSport) {
      case 'Cricket':
        return '🏆 $_teamAName won by 16 runs';
      case 'Football':
        return '🏆 $_teamAName won by 2 goals';
      case 'Badminton':
        return '🏆 $_teamAName won (2-1 sets)';
      case 'Basketball':
        return '🏆 $_teamAName won by 6 pts';
      default:
        return '🏆 $_teamAName victorious';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Statistics',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              '$_currentSport • $_turfName',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share Match Stats',
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryGreen, size: 20),
            onPressed: _shareStats,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sport Selector Filter Chips
              _buildSportFilterBar(),
              const SizedBox(height: 14),

              // 2. Match Scoreboard Card
              _buildMatchHeaderCard(),
              const SizedBox(height: 20),

              // 3. Section Title: Match Honors
              _buildSectionTitle('Match Honors & Highlights', Icons.emoji_events_rounded),
              const SizedBox(height: 12),

              // 4. Best Player of the Match (MVP) Spotlight
              _buildBestPlayerCard(),
              const SizedBox(height: 14),

              // 5. Sport-Specific Highlights Grid (Top Scorer, Most Wickets, etc.)
              _buildTopPerformersGrid(),
              const SizedBox(height: 24),

              // 6. Section Title: Team Comparison
              _buildSectionTitle('Team Head-to-Head Comparison', Icons.compare_arrows_rounded),
              const SizedBox(height: 12),

              // 7. Head-to-Head Comparative Metrics
              _buildTeamComparisonCard(),
              const SizedBox(height: 24),

              // 8. Section Title: Squad Performance Leaderboard
              _buildSectionTitle('Player Performance Scorecard', Icons.leaderboard_rounded),
              const SizedBox(height: 12),

              // 9. Team Filter Pills & Detailed Scorecard Table
              _buildPlayerScorecardSection(),
              const SizedBox(height: 24),

              // 10. AI Analytics & Tactical Breakdown
              _buildAiInsightCard(),
              const SizedBox(height: 24),

              // 11. Share / Export Bottom Action Button
              _buildShareButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Sport Filter Bar ---
  Widget _buildSportFilterBar() {
    final sports = ['Cricket', 'Football', 'Badminton', 'Basketball'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sports.map((sport) {
          final isSel = _currentSport == sport;
          IconData icon;
          switch (sport) {
            case 'Cricket':
              icon = Icons.sports_cricket_rounded;
              break;
            case 'Football':
              icon = Icons.sports_soccer_rounded;
              break;
            case 'Badminton':
              icon = Icons.sports_tennis_rounded;
              break;
            default:
              icon = Icons.sports_basketball_rounded;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSel ? Colors.black : Colors.white70,
              ),
              label: Text(
                sport,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.black : Colors.white,
                ),
              ),
              selected: isSel,
              selectedColor: _accentColor,
              backgroundColor: const Color(0xFF131D16),
              side: BorderSide(
                color: isSel ? _accentColor : const Color(0xFF223427),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _currentSport = sport;
                    _selectedTeamTab = 0;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 2. Match Header Card ---
  Widget _buildMatchHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF142217),
            const Color(0xFF0D140F),
            _accentColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_sportIcon, color: _accentColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _currentSport.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Full Match Stats',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00E676),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Team A vs Team B Display
          Row(
            children: [
              // Team A
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _accentColor.withValues(alpha: 0.2),
                      child: Text(
                        _teamAName.isNotEmpty ? _teamAName[0] : 'A',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _teamAName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF243828)),
                ),
                child: Column(
                  children: [
                    Text(
                      _scoreDisplay,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Final Score',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // Team B
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                      child: Text(
                        _teamBName.isNotEmpty ? _teamBName[0] : 'B',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _teamBName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Outcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _resultBanner,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Section Title ---
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- 4. Best Player of Match (Player/Man of the Match / MVP) ---
  Widget _buildBestPlayerCard() {
    final mvpData = _getBestPlayerDetails();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111A13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B2414),
            const Color(0xFF101912),
            Colors.amber.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    mvpData['awardTitle']!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      mvpData['rating']!,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.amber.shade300],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mvpData['avatar']!,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.amber, size: 16),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mvpData['name']!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mvpData['team']!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mvpData['headline']!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF25331C), height: 1),
          const SizedBox(height: 10),

          // Stat Pills for MOTM
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: (mvpData['chips'] as List<String>).map((chip) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                ),
                child: Text(
                  chip,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade200,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- 5. Sport-Specific Highlights Grid ---
  Widget _buildTopPerformersGrid() {
    final performers = _getTopPerformersList();

    return Column(
      children: performers.map((perf) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF101912),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1D2F22)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (perf['color'] as Color).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: (perf['color'] as Color).withValues(alpha: 0.35)),
                ),
                child: Icon(perf['icon'] as IconData, color: perf['color'] as Color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perf['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: perf['color'] as Color,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perf['player'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      perf['subtitle'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16251A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (perf['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      perf['highlightStat'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      perf['statSub'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: perf['color'] as Color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 6. Head-to-Head Comparative Metrics ---
  Widget _buildTeamComparisonCard() {
    final metrics = _getTeamComparisonMetrics();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _teamAName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              Text(
                'Head-to-Head',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),
              Text(
                _teamBName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...metrics.map((m) {
            final double ratio = (m['ratio'] as double).clamp(0.05, 0.95);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m['valA'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                      Text(
                        m['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        m['valB'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      color: _accentColor,
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 7. Player Scorecard Table ---
  Widget _buildPlayerScorecardSection() {
    final scorecard = _getSportScorecard();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1C2C20))),
            ),
            child: Row(
              children: [
                _buildTeamFilterTab(0, 'All Players'),
                _buildTeamFilterTab(1, _teamAName),
                _buildTeamFilterTab(2, _teamBName),
              ],
            ),
          ),

          // Header columns
          Container(
            color: const Color(0xFF142017),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Player',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.bold),
                  ),
                ),
                ...scorecard['headers'].map<Widget>((h) {
                  return Expanded(
                    flex: 2,
                    child: Text(
                      h as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Player rows
          ..._getFilteredPlayers(scorecard['players'] as List<Map<String, dynamic>>).map((p) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF18261C))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (p['isMvp'] == true) ...[
                              const Text('👑', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                p['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p['isMvp'] == true ? Colors.amber : Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          p['team'] as String,
                          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ),
                  ...(p['stats'] as List).map<Widget>((s) {
                    return Expanded(
                      flex: 2,
                      child: Text(
                        s.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamFilterTab(int idx, String title) {
    final isSel = _selectedTeamTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTeamTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? _accentColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSel ? Border.all(color: _accentColor.withValues(alpha: 0.4)) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? _accentColor : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPlayers(List<Map<String, dynamic>> players) {
    if (_selectedTeamTab == 1) {
      return players.where((p) => (p['team'] as String).contains(_teamAName) || p['teamId'] == 'A').toList();
    } else if (_selectedTeamTab == 2) {
      return players.where((p) => (p['team'] as String).contains(_teamBName) || p['teamId'] == 'B').toList();
    }
    return players;
  }

  // --- 8. AI Match Insight ---
  Widget _buildAiInsightCard() {
    String insightText;
    switch (_currentSport) {
      case 'Cricket':
        insightText =
            '$_teamAName capitalized heavily on boundary striking during overs 3-6. Amit Sharma\'s 54(26) anchoring innings coupled with Rahul Verma\'s tight 3-wicket spell in the 7th over dictated the winning momentum.';
        break;
      case 'Football':
        insightText =
            '$_teamAName held 58% possession and executed high pressing effectively, creating 7 shots on target. Rahul\'s brace and clinical distribution opened up the opponent\'s backline.';
        break;
      case 'Badminton':
        insightText =
            'High intensity rally exchanges in Set 3 decided the clash. John Doe\'s aggressive smash placement won 18 decisive points with under 5 unforced errors.';
        break;
      case 'Basketball':
        insightText =
            '$_teamAName dominated second-chance offensive points and fast-breaks, shooting 41% from beyond the 3-point arc led by Sameer\'s 24-point performance.';
        break;
      default:
        insightText =
            'Outstanding competitive intensity throughout the fixture with peak stamina shown in the closing phases.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF101912),
            _accentColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: _accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Performance Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insightText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 9. Share Button ---
  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _shareStats,
        icon: const Icon(Icons.share_rounded, color: Colors.black, size: 18),
        label: Text(
          'Share Match Statistics & Scorecard',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _shareStats() {
    final best = _getBestPlayerDetails();
    final summary = '📊 Match Statistics - $_currentSport at $_turfName\n'
        '$_teamAName vs $_teamBName\n'
        'Score: $_scoreDisplay\n'
        'Result: $_resultBanner\n'
        '👑 Best Player of Match: ${best['name']} (${best['headline']})\n'
        'Tracked live on BYS Turf App!';

    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Match statistics copied to clipboard! Ready to share!'),
        backgroundColor: const Color(0xFF16251A),
      ),
    );
  }

  // ==========================================
  // --- SPORT-SPECIFIC DATA GENERATORS ---
  // ==========================================

  Map<String, dynamic> _getBestPlayerDetails() {
    if (widget.matchData != null && widget.matchData!['mvp'] != null) {
      final mvpStr = widget.matchData!['mvp'].toString();
      final name = mvpStr.contains('(') ? mvpStr.split('(')[0].trim() : mvpStr;
      final extra = mvpStr.contains('(') ? mvpStr.split('(')[1].replaceAll(')', '').trim() : 'Key match winner';

      return {
        'awardTitle': '👑 Best Player of the Match',
        'name': name,
        'team': _teamAName,
        'rating': '★ 9.6',
        'headline': extra,
        'avatar': name.isNotEmpty ? name[0] : 'M',
        'chips': ['Match Winner', extra, '★ 9.6 Rating'],
      };
    }

    switch (_currentSport) {
      case 'Cricket':
        return {
          'awardTitle': '👑 Best Player of the Match',
          'name': 'Amit Sharma',
          'team': _teamAName,
          'rating': '★ 9.8',
          'headline': '54 runs (26 balls, 5x4, 4x6) & 2/18 wickets in 2.0 ov',
          'avatar': 'A',
          'chips': ['54 Runs (26b)', '2 Wickets / 18r', 'SR 207.7', '★ 9.8 Rating'],
        };
      case 'Football':
        return {
          'awardTitle': '👑 Man of the Match',
          'name': 'Rahul Sharma',
          'team': _teamAName,
          'rating': '★ 9.4',
          'headline': '2 Goals & 1 Assist • 89% Pass Accuracy',
          'avatar': 'R',
          'chips': ['2 Goals', '1 Assist', '3 Shots on Target', '★ 9.4 Rating'],
        };
      case 'Badminton':
        return {
          'awardTitle': '👑 Player of the Match',
          'name': 'John Doe',
          'team': _teamAName,
          'rating': '★ 9.5',
          'headline': '42 Rally Points Won & Decider Set Smash Winner',
          'avatar': 'J',
          'chips': ['42 Total Points', '14 Smash Winners', '3 Aces', '★ 9.5 Rating'],
        };
      case 'Basketball':
        return {
          'awardTitle': '👑 Match MVP',
          'name': 'Sameer Rao',
          'team': _teamAName,
          'rating': '★ 9.7',
          'headline': '24 Points, 8 Rebounds, 5 Assists (64% FG)',
          'avatar': 'S',
          'chips': ['24 Points', '8 Rebounds', '5 Assists', '3 Threes'],
        };
      default:
        return {
          'awardTitle': '👑 Best Player of the Match',
          'name': 'Player One',
          'team': _teamAName,
          'rating': '★ 9.0',
          'headline': 'Outstanding game-winning performance',
          'avatar': 'P',
          'chips': ['MVP', '★ 9.0 Rating'],
        };
    }
  }

  List<Map<String, dynamic>> _getTopPerformersList() {
    switch (_currentSport) {
      case 'Cricket':
        return [
          {
            'title': '🏏 TOP RUN SCORER',
            'player': 'Amit Sharma',
            'subtitle': '$_teamAName • SR 207.7 (5x4, 4x6)',
            'highlightStat': '54 (26b)',
            'statSub': 'HIGHEST RUNS',
            'color': const Color(0xFFFF9800),
            'icon': Icons.sports_cricket_rounded,
          },
          {
            'title': '🎯 MOST WICKETS TAKEN',
            'player': 'Rahul Verma',
            'subtitle': '$_teamBName • 2.0 overs • 7 Dot Balls',
            'highlightStat': '3 / 14',
            'statSub': 'BEST BOWLER',
            'color': const Color(0xFF00E5FF),
            'icon': Icons.track_changes_rounded,
          },
          {
            'title': '💥 MAXIMUM SIXES',
            'player': 'Vikram Singh',
            'subtitle': '$_teamAName • Longest six: 86 meters',
            'highlightStat': '5 Sixes',
            'statSub': 'POWER HITTER',
            'color': Colors.amber,
            'icon': Icons.bolt_rounded,
          },
          {
            'title': '🛡️ BEST ECONOMY RATE',
            'player': 'Dinesh Kumar',
            'subtitle': '$_teamBName • 2.0 overs • 1 wicket',
            'highlightStat': '5.50 RPO',
            'statSub': '1/11 (2.0)',
            'color': AppTheme.primaryGreen,
            'icon': Icons.shield_rounded,
          },
        ];
      case 'Football':
        return [
          {
            'title': '⚽ TOP SCORER',
            'player': 'Rahul Sharma',
            'subtitle': '$_teamAName • 3 Shots on Target',
            'highlightStat': '2 Goals',
            'statSub': 'BRACE',
            'color': AppTheme.primaryGreen,
            'icon': Icons.sports_soccer_rounded,
          },
          {
            'title': '👟 MOST ASSISTS / PLAYMAKER',
            'player': 'Kiran Patel',
            'subtitle': '$_teamAName • 4 Key Passes Created',
            'highlightStat': '2 Assists',
            'statSub': 'PLAYMAKER',
            'color': const Color(0xFF00E5FF),
            'icon': Icons.alt_route_rounded,
          },
          {
            'title': '🧤 BEST GOALKEEPER / MOST SAVES',
            'player': 'Arun Prasad',
            'subtitle': '$_teamBName • 86% Save Efficiency',
            'highlightStat': '6 Saves',
            'statSub': 'TOP KEEPER',
            'color': Colors.amber,
            'icon': Icons.front_hand_rounded,
          },
          {
            'title': '🛡️ MOST TACKLES & INTERCEPTIONS',
            'player': 'Dev George',
            'subtitle': '$_teamAName • 100% Tackle success',
            'highlightStat': '5 Tackles',
            'statSub': 'DEFENSIVE WALL',
            'color': const Color(0xFFFF5252),
            'icon': Icons.shield_rounded,
          },
        ];
      case 'Badminton':
        return [
          {
            'title': '🏸 TOP POINTS SCORER',
            'player': 'John Doe',
            'subtitle': '$_teamAName • Total rally winners',
            'highlightStat': '42 Pts',
            'statSub': 'POINT LEADER',
            'color': const Color(0xFF00E5FF),
            'icon': Icons.sports_tennis_rounded,
          },
          {
            'title': '💥 MOST SMASH WINNERS',
            'player': 'Dev Raj',
            'subtitle': '$_teamAName • Fastest smash: 284 km/h',
            'highlightStat': '14 Smashes',
            'statSub': 'SMASH KING',
            'color': Colors.amber,
            'icon': Icons.flash_on_rounded,
          },
          {
            'title': '🛡️ FEWEST UNFORCED ERRORS',
            'player': 'Kiran',
            'subtitle': '$_teamBName • High consistency rally play',
            'highlightStat': '3 Errors',
            'statSub': 'PRECISION',
            'color': AppTheme.primaryGreen,
            'icon': Icons.check_circle_outline_rounded,
          },
        ];
      case 'Basketball':
        return [
          {
            'title': '🏀 TOP SCORER',
            'player': 'Sameer Rao',
            'subtitle': '$_teamAName • 9/14 Field Goals (64%)',
            'highlightStat': '24 Pts',
            'statSub': 'TOP SCORER',
            'color': const Color(0xFFFF7043),
            'icon': Icons.sports_basketball_rounded,
          },
          {
            'title': '🎯 MOST 3-POINTERS',
            'player': 'Dev Sharma',
            'subtitle': '$_teamBName • 4 of 6 beyond arc',
            'highlightStat': '4 Threes',
            'statSub': '67% 3PT',
            'color': Colors.amber,
            'icon': Icons.adjust_rounded,
          },
          {
            'title': '🔄 REBOUNDS & ASSISTS LEADER',
            'player': 'Karthik M',
            'subtitle': '$_teamAName • 8 Boards, 7 Dimes',
            'highlightStat': '8 Reb / 7 Ast',
            'statSub': 'DOUBLE DIGIT',
            'color': const Color(0xFF00E5FF),
            'icon': Icons.all_inclusive_rounded,
          },
        ];
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getTeamComparisonMetrics() {
    switch (_currentSport) {
      case 'Cricket':
        return [
          {'title': 'Total Runs', 'valA': '88', 'valB': '72', 'ratio': 88 / (88 + 72)},
          {'title': 'Run Rate (RPO)', 'valA': '11.0', 'valB': '9.0', 'ratio': 11 / 20},
          {'title': 'Fours (4s)', 'valA': '8', 'valB': '6', 'ratio': 8 / 14},
          {'title': 'Sixes (6s)', 'valA': '5', 'valB': '3', 'ratio': 5 / 8},
          {'title': 'Extras Conceded', 'valA': '6', 'valB': '9', 'ratio': 6 / 15},
          {'title': 'Dot Ball %', 'valA': '38%', 'valB': '46%', 'ratio': 0.45},
          {'title': 'Wickets Lost', 'valA': '4', 'valB': '6', 'ratio': 4 / 10},
        ];
      case 'Football':
        return [
          {'title': 'Possession', 'valA': '58%', 'valB': '42%', 'ratio': 0.58},
          {'title': 'Total Shots', 'valA': '12', 'valB': '6', 'ratio': 12 / 18},
          {'title': 'Shots on Target', 'valA': '7', 'valB': '3', 'ratio': 7 / 10},
          {'title': 'Pass Accuracy', 'valA': '86%', 'valB': '74%', 'ratio': 86 / 160},
          {'title': 'Corners', 'valA': '4', 'valB': '2', 'ratio': 4 / 6},
          {'title': 'Fouls', 'valA': '5', 'valB': '6', 'ratio': 5 / 11},
          {'title': 'Yellow Cards', 'valA': '1', 'valB': '2', 'ratio': 1 / 3},
        ];
      case 'Badminton':
        return [
          {'title': 'Total Points Won', 'valA': '61', 'valB': '54', 'ratio': 61 / 115},
          {'title': 'Smash Winners', 'valA': '18', 'valB': '11', 'ratio': 18 / 29},
          {'title': 'Net Kill Winners', 'valA': '12', 'valB': '8', 'ratio': 12 / 20},
          {'title': 'Unforced Errors', 'valA': '8', 'valB': '15', 'ratio': 8 / 23},
          {'title': 'Max Consecutive Pts', 'valA': '6', 'valB': '4', 'ratio': 6 / 10},
          {'title': 'Service Aces', 'valA': '4', 'valB': '2', 'ratio': 4 / 6},
        ];
      case 'Basketball':
        return [
          {'title': 'Field Goal %', 'valA': '52%', 'valB': '44%', 'ratio': 52 / 96},
          {'title': '3-Point FG %', 'valA': '41%', 'valB': '35%', 'ratio': 41 / 76},
          {'title': 'Total Rebounds', 'valA': '34', 'valB': '28', 'ratio': 34 / 62},
          {'title': 'Assists', 'valA': '18', 'valB': '13', 'ratio': 18 / 31},
          {'title': 'Steals', 'valA': '8', 'valB': '5', 'ratio': 8 / 13},
          {'title': 'Turnovers', 'valA': '9', 'valB': '14', 'ratio': 9 / 23},
        ];
      default:
        return [];
    }
  }

  Map<String, dynamic> _getSportScorecard() {
    switch (_currentSport) {
      case 'Cricket':
        return {
          'headers': ['Runs', 'Balls', '4s/6s', 'SR'],
          'players': [
            {
              'name': 'Amit Sharma',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': true,
              'stats': ['54', '26', '5/4', '207.7'],
            },
            {
              'name': 'Vikram Singh',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': false,
              'stats': ['34', '18', '2/5', '188.8'],
            },
            {
              'name': 'Karan Gupta',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['38', '22', '4/2', '172.7'],
            },
            {
              'name': 'Rahul Verma',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['18', '14', '2/1', '128.5'],
            },
            {
              'name': 'Dinesh Kumar',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['12', '9', '1/1', '133.3'],
            },
          ],
        };
      case 'Football':
        return {
          'headers': ['Goals', 'Assists', 'Shots', 'Rating'],
          'players': [
            {
              'name': 'Rahul Sharma',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': true,
              'stats': ['2', '1', '4(3)', '9.4'],
            },
            {
              'name': 'Kiran Patel',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': false,
              'stats': ['1', '2', '2(1)', '8.8'],
            },
            {
              'name': 'Dev George',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': false,
              'stats': ['1', '0', '1(1)', '8.0'],
            },
            {
              'name': 'Arun Prasad (GK)',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['0', '0', '6 saves', '8.2'],
            },
            {
              'name': 'Farhan Khan',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['2', '0', '3(2)', '8.5'],
            },
          ],
        };
      case 'Badminton':
        return {
          'headers': ['Points', 'Smashes', 'Aces', 'Rating'],
          'players': [
            {
              'name': 'John Doe',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': true,
              'stats': ['42', '14', '3', '9.5'],
            },
            {
              'name': 'Dev Raj',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': false,
              'stats': ['19', '8', '1', '8.4'],
            },
            {
              'name': 'Kiran',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['31', '9', '2', '8.6'],
            },
            {
              'name': 'Rajesh',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['23', '6', '1', '7.9'],
            },
          ],
        };
      case 'Basketball':
        return {
          'headers': ['Pts', '3PT', 'Reb', 'Ast'],
          'players': [
            {
              'name': 'Sameer Rao',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': true,
              'stats': ['24', '3', '8', '5'],
            },
            {
              'name': 'Karthik M',
              'team': _teamAName,
              'teamId': 'A',
              'isMvp': false,
              'stats': ['16', '1', '8', '7'],
            },
            {
              'name': 'Dev Sharma',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['22', '4', '4', '3'],
            },
            {
              'name': 'Arjun Nair',
              'team': _teamBName,
              'teamId': 'B',
              'isMvp': false,
              'stats': ['14', '2', '6', '4'],
            },
          ],
        };
      default:
        return {'headers': [], 'players': []};
    }
  }
}
