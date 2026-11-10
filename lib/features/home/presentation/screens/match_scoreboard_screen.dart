import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/services/realtime_service.dart';

class MatchScoreboardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialConfig;

  const MatchScoreboardScreen({super.key, this.initialConfig});

  @override
  ConsumerState<MatchScoreboardScreen> createState() => _MatchScoreboardScreenState();
}

class _MatchScoreboardScreenState extends ConsumerState<MatchScoreboardScreen> {
  // Match configuration
  late String _sport;
  late String _turfName;
  late String _teamA;
  late String _teamB;

  // Teams and Squad Members
  final List<Map<String, dynamic>> _teamAMembers = [];
  final List<Map<String, dynamic>> _teamBMembers = [];
  Color _teamAColor = const Color(0xFF00E676);
  Color _teamBColor = const Color(0xFF00E5FF);

  // Realtime
  StreamSubscription<Map<String, dynamic>>? _subscription;

  // Tab: 0 = Scoreboard & Actions, 1 = Timeline, 2 = Stats
  int _selectedTab = 0;

  // --- FOOTBALL STATE ---
  int _footballTeamAScore = 0;
  int _footballTeamBScore = 0;
  int _footballFoulsA = 0;
  int _footballFoulsB = 0;
  int _footballYellowCardsA = 0;
  int _footballYellowCardsB = 0;
  int _footballRedCardsA = 0;
  int _footballRedCardsB = 0;
  int _footballSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _gameTimer;
  int _footballHalf = 1;

  // --- CRICKET STATE ---
  int _cricketMaxOvers = 8;
  int _cricketCurrentInning = 1; // 1 or 2
  int _cricketRunsA = 0;
  int _cricketWicketsA = 0;
  int _cricketBallsA = 0; // total legal balls bowled
  int _cricketRunsB = 0;
  int _cricketWicketsB = 0;
  int _cricketBallsB = 0;
  final List<String> _cricketCurrentOverBalls = [];
  final List<Map<String, dynamic>> _cricketBallHistory = [];

  // --- BADMINTON / TENNIS STATE ---
  int _badmintonTargetPoints = 21;
  int _badmintonCurrentSet = 1;
  int _badmintonScoreA = 0;
  int _badmintonScoreB = 0;
  int _badmintonSetsWonA = 0;
  int _badmintonSetsWonB = 0;
  bool _badmintonServerIsA = true;
  final List<String> _badmintonSetHistory = [];

  // --- BASKETBALL STATE ---
  int _basketballScoreA = 0;
  int _basketballScoreB = 0;
  int _basketballQuarter = 1;
  int _basketballFoulsA = 0;
  int _basketballFoulsB = 0;

  // Timeline events for all sports
  final List<Map<String, String>> _timelineEvents = [];

  bool get isViewOnly =>
      (widget.initialConfig?['isViewOnly'] as bool?) ??
      (widget.initialConfig?['readOnly'] as bool?) ??
      false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig ?? {};
    _sport = (cfg['sport'] as String?)?.toLowerCase() ?? 'football';
    _turfName = (cfg['turfName'] as String?) ?? 'Green Field Arena';
    _teamA = (cfg['teamA'] as String?) ?? 'Team Alpha';
    _teamB = (cfg['teamB'] as String?) ?? 'Team Beta';

    if (cfg.containsKey('cricketOvers')) {
      _cricketMaxOvers = cfg['cricketOvers'] as int;
    }
    if (cfg.containsKey('badmintonPoints')) {
      _badmintonTargetPoints = cfg['badmintonPoints'] as int;
    }

    if (cfg['teamAColor'] is int) {
      _teamAColor = Color(cfg['teamAColor'] as int);
    }
    if (cfg['teamBColor'] is int) {
      _teamBColor = Color(cfg['teamBColor'] as int);
    }

    if (cfg['teamAMembers'] is List) {
      for (final m in (cfg['teamAMembers'] as List)) {
        if (m is Map) {
          final map = Map<String, dynamic>.from(m);
          map['goals'] ??= 0;
          map['runs'] ??= 0;
          map['wickets'] ??= 0;
          map['points'] ??= 0;
          map['fouls'] ??= 0;
          map['yellowCards'] ??= 0;
          map['redCards'] ??= 0;
          _teamAMembers.add(map);
        }
      }
    }
    if (cfg['teamBMembers'] is List) {
      for (final m in (cfg['teamBMembers'] as List)) {
        if (m is Map) {
          final map = Map<String, dynamic>.from(m);
          map['goals'] ??= 0;
          map['runs'] ??= 0;
          map['wickets'] ??= 0;
          map['points'] ??= 0;
          map['fouls'] ??= 0;
          map['yellowCards'] ??= 0;
          map['redCards'] ??= 0;
          _teamBMembers.add(map);
        }
      }
    }

    if (_teamAMembers.isEmpty) {
      _teamAMembers.addAll([
        {'name': 'Rahul Sharma', 'role': 'Striker', 'number': '10', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
        {'name': 'Vikram Rathore', 'role': 'Midfielder', 'number': '7', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
        {'name': 'Karan Mehta', 'role': 'Goalkeeper', 'number': '1', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
      ]);
    }
    if (_teamBMembers.isEmpty) {
      _teamBMembers.addAll([
        {'name': 'Harsh Varma', 'role': 'Striker', 'number': '9', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
        {'name': 'David Miller', 'role': 'Midfielder', 'number': '8', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
        {'name': 'Tanmay Roy', 'role': 'Goalkeeper', 'number': '12', 'goals': 0, 'runs': 0, 'wickets': 0, 'points': 0, 'fouls': 0, 'yellowCards': 0, 'redCards': 0},
      ]);
    }

    _timelineEvents.add({
      'time': '00:00',
      'event': 'Match Started',
      'player': 'Referee / Scorer',
      'team': _turfName,
    });

    if (isViewOnly) {
      if (_sport == 'football') {
        _footballTeamAScore = 2;
        _footballTeamBScore = 1;
        _footballFoulsA = 4;
        _footballFoulsB = 3;
        _footballYellowCardsA = 1;
        _footballYellowCardsB = 2;
        _footballSeconds = 68 * 60;
        _footballHalf = 2;
        _isTimerRunning = true;
        _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _footballSeconds++;
          });
        });
        _timelineEvents.addAll([
          {'time': "18'", 'event': 'Goal by Vikram', 'player': 'Vikram', 'team': _teamA},
          {'time': "34'", 'event': 'Yellow Card - Harsh', 'player': 'Harsh', 'team': _teamB},
          {'time': "41'", 'event': 'Goal by David', 'player': 'David', 'team': _teamB},
          {'time': "54'", 'event': 'Goal by Rahul', 'player': 'Rahul', 'team': _teamA},
        ]);
      } else if (_sport == 'cricket') {
        _cricketRunsA = 78;
        _cricketWicketsA = 3;
        _cricketBallsA = 48;
        _cricketRunsB = 62;
        _cricketWicketsB = 5;
        _cricketBallsB = 40;
        _cricketCurrentInning = 2;
        _cricketCurrentOverBalls.addAll(['1', '4', 'W', '0']);
        _timelineEvents.addAll([
          {'time': "0.1 ov", 'event': 'Single off cover', 'player': 'Arun K.', 'team': _teamB},
          {'time': "3.2 ov", 'event': 'SIX over long-on', 'player': 'Arun K.', 'team': _teamB},
          {'time': "5.4 ov", 'event': 'WICKET! Clean bowled', 'player': 'Kiran P.', 'team': _teamA},
        ]);
      } else if (_sport == 'badminton' || _sport == 'tennis') {
        _badmintonScoreA = 14;
        _badmintonScoreB = 11;
        _badmintonCurrentSet = 3;
        _badmintonSetsWonA = 1;
        _badmintonSetsWonB = 1;
        _timelineEvents.addAll([
          {'time': "Set 1", 'event': 'Set won by $_teamA (21-18)', 'player': _teamA, 'team': _teamA},
          {'time': "Set 2", 'event': 'Set won by $_teamB (21-17)', 'player': _teamB, 'team': _teamB},
          {'time': "Set 3", 'event': 'Smash winner by $_teamA', 'player': _teamA, 'team': _teamA},
        ]);
      } else if (_sport == 'basketball') {
        _basketballScoreA = 42;
        _basketballScoreB = 38;
        _basketballQuarter = 3;
        _basketballFoulsA = 3;
        _basketballFoulsB = 4;
        _timelineEvents.addAll([
          {'time': "Q1", 'event': 'End of Q1: 14 - 12', 'player': 'Referee', 'team': _turfName},
          {'time': "Q2", 'event': 'End of Q2: 30 - 27', 'player': 'Referee', 'team': _turfName},
          {'time': "Q3 02:45", 'event': '3-Pointer by Sameer', 'player': 'Sameer', 'team': _teamA},
        ]);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRealtime();
    });
  }

  void _initRealtime() {
    try {
      final realtime = ref.read(realtimeServiceProvider);
      _subscription = realtime.connectToChannel('scoreboard').listen((data) {
        if (!mounted) return;
        setState(() {
          if (_sport == 'football') {
            if (data.containsKey('team_a_score')) _footballTeamAScore = data['team_a_score'];
            if (data.containsKey('team_b_score')) _footballTeamBScore = data['team_b_score'];
          } else if (_sport == 'cricket') {
            if (data.containsKey('runs')) {
              if (_cricketCurrentInning == 1) {
                _cricketRunsA = data['runs'];
              } else {
                _cricketRunsB = data['runs'];
              }
            }
          }
        });
      });
    } catch (_) {}
  }

  void _startStopTimer() {
    setState(() {
      if (_isTimerRunning) {
        _gameTimer?.cancel();
        _isTimerRunning = false;
      } else {
        _isTimerRunning = true;
        _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _footballSeconds++;
          });
        });
      }
    });
  }

  String _formatTime(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  // --- FOOTBALL ACTIONS ---
  void _addFootballGoal(bool isTeamA) {
    final team = isTeamA ? _teamA : _teamB;
    final members = isTeamA ? _teamAMembers : _teamBMembers;

    if (members.isNotEmpty) {
      _showGoalScorerSheet(isTeamA: isTeamA);
    } else {
      _commitFootballGoal(isTeamA: isTeamA, scorer: '$team Scored', member: null);
    }
  }

  void _commitFootballGoal({required bool isTeamA, required String scorer, Map<String, dynamic>? member}) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (isTeamA) {
        _footballTeamAScore++;
      } else {
        _footballTeamBScore++;
      }
      if (member != null) {
        member['goals'] = ((member['goals'] as int? ?? 0) + 1);
      }
      final team = isTeamA ? _teamA : _teamB;
      _timelineEvents.insert(0, {
        'time': _formatTime(_footballSeconds),
        'event': '⚽ GOAL!',
        'player': scorer,
        'team': team,
      });

      try {
        ref.read(realtimeServiceProvider).sendMessage({
          'type': 'goal',
          'team_a_score': _footballTeamAScore,
          'team_b_score': _footballTeamBScore,
          'scorer': scorer,
          'team': team,
          'time': _formatTime(_footballSeconds),
        }, channelPath: 'scoreboard');
      } catch (_) {}
    });
  }

  void _showGoalScorerSheet({required bool isTeamA}) {
    final team = isTeamA ? _teamA : _teamB;
    final members = isTeamA ? _teamAMembers : _teamBMembers;
    final accentColor = isTeamA ? _teamAColor : _teamBColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101912),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Who scored for $team?',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sports_soccer, color: accentColor, size: 20),
                ),
                title: Text(
                  'Quick Team Goal (Unassigned)',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                subtitle: Text('Score without player attribution', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                onTap: () {
                  Navigator.pop(ctx);
                  _commitFootballGoal(isTeamA: isTeamA, scorer: '$team Scored', member: null);
                },
              ),
              const Divider(color: Color(0xFF1B2B1F)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, idx) {
                    final m = members[idx];
                    final name = m['name'] as String;
                    final num = m['number']?.toString() ?? '${idx + 1}';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        child: Text(num, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                      subtitle: Text(m['role']?.toString() ?? 'Player', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white30),
                      onTap: () {
                        Navigator.pop(ctx);
                        _commitFootballGoal(isTeamA: isTeamA, scorer: '$name (#$num)', member: m);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeFootballGoal(bool isTeamA) {
    setState(() {
      if (isTeamA && _footballTeamAScore > 0) {
        _footballTeamAScore--;
      } else if (!isTeamA && _footballTeamBScore > 0) {
        _footballTeamBScore--;
      }
    });
  }

  // --- CRICKET ACTIONS ---
  void _addCricketBall(int runs, {bool isWicket = false, bool isWide = false, bool isNoBall = false}) {
    HapticFeedback.lightImpact();
    setState(() {
      final isFirstInnings = _cricketCurrentInning == 1;

      // Save for Undo
      _cricketBallHistory.add({
        'inning': _cricketCurrentInning,
        'runs': runs,
        'isWicket': isWicket,
        'isWide': isWide,
        'isNoBall': isNoBall,
        'prevOverBalls': List<String>.from(_cricketCurrentOverBalls),
      });

      String ballTag = runs.toString();
      if (isWicket) ballTag = 'W';
      if (isWide) ballTag = 'Wd';
      if (isNoBall) ballTag = 'Nb';

      if (isWide || isNoBall) {
        // Extra run, doesn't increment legal ball count
        if (isFirstInnings) {
          _cricketRunsA += runs + 1;
        } else {
          _cricketRunsB += runs + 1;
        }
        _cricketCurrentOverBalls.add(ballTag);
      } else {
        // Legal ball
        if (isFirstInnings) {
          _cricketRunsA += runs;
          if (isWicket) _cricketWicketsA++;
          _cricketBallsA++;
        } else {
          _cricketRunsB += runs;
          if (isWicket) _cricketWicketsB++;
          _cricketBallsB++;
        }
        _cricketCurrentOverBalls.add(ballTag);

        // Check for completed over (6 balls)
        final newBalls = isFirstInnings ? _cricketBallsA : _cricketBallsB;
        if (newBalls % 6 == 0 && newBalls > 0) {
          _cricketCurrentOverBalls.clear();
        }
      }

      // Add to timeline if wicket or boundary
      final currentTeam = isFirstInnings ? _teamA : _teamB;
      if (isWicket) {
        _timelineEvents.insert(0, {
          'time': '${(_cricketBallsA ~/ 6)}.${_cricketBallsA % 6} ov',
          'event': '☝️ WICKET!',
          'player': 'Wicket fallen',
          'team': currentTeam,
        });
      } else if (runs == 4 || runs == 6) {
        _timelineEvents.insert(0, {
          'time': '${(_cricketBallsA ~/ 6)}.${_cricketBallsA % 6} ov',
          'event': runs == 6 ? '💥 SIX!' : '🏏 FOUR!',
          'player': '$runs Runs',
          'team': currentTeam,
        });
      }

      try {
        ref.read(realtimeServiceProvider).sendMessage({
          'type': 'cricket_update',
          'inning': isFirstInnings ? 1 : 2,
          'runs': isFirstInnings ? _cricketRunsA : _cricketRunsB,
          'wickets': isFirstInnings ? _cricketWicketsA : _cricketWicketsB,
          'balls': isFirstInnings ? _cricketBallsA : _cricketBallsB,
        }, channelPath: 'scoreboard');
      } catch (_) {}
    });
  }

  void _undoCricketBall() {
    if (_cricketBallHistory.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      final last = _cricketBallHistory.removeLast();
      final inning = last['inning'] as int;
      final runs = last['runs'] as int;
      final isWicket = last['isWicket'] as bool;
      final isWide = last['isWide'] as bool;
      final isNoBall = last['isNoBall'] as bool;
      _cricketCurrentOverBalls.clear();
      _cricketCurrentOverBalls.addAll(List<String>.from(last['prevOverBalls'] as List));

      if (inning == 1) {
        if (isWide || isNoBall) {
          _cricketRunsA = (_cricketRunsA - runs - 1).clamp(0, 999);
        } else {
          _cricketRunsA = (_cricketRunsA - runs).clamp(0, 999);
          if (isWicket) _cricketWicketsA = (_cricketWicketsA - 1).clamp(0, 11);
          _cricketBallsA = (_cricketBallsA - 1).clamp(0, 600);
        }
      } else {
        if (isWide || isNoBall) {
          _cricketRunsB = (_cricketRunsB - runs - 1).clamp(0, 999);
        } else {
          _cricketRunsB = (_cricketRunsB - runs).clamp(0, 999);
          if (isWicket) _cricketWicketsB = (_cricketWicketsB - 1).clamp(0, 11);
          _cricketBallsB = (_cricketBallsB - 1).clamp(0, 600);
        }
      }
    });
  }

  void _switchCricketInnings() {
    setState(() {
      if (_cricketCurrentInning == 1) {
        _cricketCurrentInning = 2;
        _cricketCurrentOverBalls.clear();
        _timelineEvents.insert(0, {
          'time': 'Innings Break',
          'event': 'Target: ${_cricketRunsA + 1} Runs',
          'player': '$_teamB needs ${_cricketRunsA + 1} runs in $_cricketMaxOvers overs',
          'team': _teamB,
        });
      } else {
        _cricketCurrentInning = 1;
      }
    });
  }

  // --- BADMINTON ACTIONS ---
  void _addBadmintonPoint(bool isTeamA) {
    HapticFeedback.lightImpact();
    setState(() {
      if (isTeamA) {
        _badmintonScoreA++;
        _badmintonServerIsA = true;
      } else {
        _badmintonScoreB++;
        _badmintonServerIsA = false;
      }

      // Check for set win: target reached and at least 2 points lead
      if (_badmintonScoreA >= _badmintonTargetPoints && (_badmintonScoreA - _badmintonScoreB) >= 2) {
        _badmintonSetsWonA++;
        _badmintonSetHistory.add('Set $_badmintonCurrentSet: $_teamA ($_badmintonScoreA - $_badmintonScoreB)');
        _badmintonCurrentSet++;
        _badmintonScoreA = 0;
        _badmintonScoreB = 0;
      } else if (_badmintonScoreB >= _badmintonTargetPoints && (_badmintonScoreB - _badmintonScoreA) >= 2) {
        _badmintonSetsWonB++;
        _badmintonSetHistory.add('Set $_badmintonCurrentSet: $_teamB ($_badmintonScoreB - $_badmintonScoreA)');
        _badmintonCurrentSet++;
        _badmintonScoreA = 0;
        _badmintonScoreB = 0;
      }
    });
  }

  void _undoBadmintonPoint(bool isTeamA) {
    setState(() {
      if (isTeamA && _badmintonScoreA > 0) {
        _badmintonScoreA--;
      } else if (!isTeamA && _badmintonScoreB > 0) {
        _badmintonScoreB--;
      }
    });
  }

  // --- BASKETBALL ACTIONS ---
  void _addBasketballPoints(bool isTeamA, int pts) {
    HapticFeedback.lightImpact();
    setState(() {
      if (isTeamA) {
        _basketballScoreA += pts;
      } else {
        _basketballScoreB += pts;
      }
      final team = isTeamA ? _teamA : _teamB;
      _timelineEvents.insert(0, {
        'time': 'Q$_basketballQuarter',
        'event': '+$pts Points',
        'player': '$team scored',
        'team': team,
      });

      try {
        ref.read(realtimeServiceProvider).sendMessage({
          'type': 'basketball_update',
          'team_a_score': _basketballScoreA,
          'team_b_score': _basketballScoreB,
          'points': pts,
          'team': team,
        }, channelPath: 'scoreboard');
      } catch (_) {}
    });
  }

  // --- END MATCH DIALOG ---
  void _showEndMatchDialog() {
    String winnerText = 'Match Tied!';
    String finalScoreText = '';

    if (_sport == 'football') {
      finalScoreText = '$_teamA $_footballTeamAScore - $_footballTeamBScore $_teamB';
      if (_footballTeamAScore > _footballTeamBScore) {
        winnerText = '🏆 $_teamA Won!';
      } else if (_footballTeamBScore > _footballTeamAScore) {
        winnerText = '🏆 $_teamB Won!';
      }
    } else if (_sport == 'cricket') {
      finalScoreText = '$_teamA $_cricketRunsA/$_cricketWicketsA vs $_teamB $_cricketRunsB/$_cricketWicketsB';
      if (_cricketRunsA > _cricketRunsB) {
        winnerText = '🏆 $_teamA Won by ${_cricketRunsA - _cricketRunsB} runs!';
      } else if (_cricketRunsB > _cricketRunsA) {
        winnerText = '🏆 $_teamB Won by ${10 - _cricketWicketsB} wickets!';
      }
    } else if (_sport == 'badminton') {
      finalScoreText = '$_teamA $_badmintonSetsWonA - $_badmintonSetsWonB $_teamB (Sets)';
      if (_badmintonSetsWonA > _badmintonSetsWonB) {
        winnerText = '🏆 $_teamA Won!';
      } else if (_badmintonSetsWonB > _badmintonSetsWonA) {
        winnerText = '🏆 $_teamB Won!';
      }
    } else if (_sport == 'basketball') {
      finalScoreText = '$_teamA $_basketballScoreA - $_basketballScoreB $_teamB';
      if (_basketballScoreA > _basketballScoreB) {
        winnerText = '🏆 $_teamA Won!';
      } else if (_basketballScoreB > _basketballScoreA) {
        winnerText = '🏆 $_teamB Won!';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        title: Center(
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 52),
              const SizedBox(height: 8),
              Text(
                'Match Concluded',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    winnerText,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    finalScoreText,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 $_turfName',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this scorecard with players or save to your booking summary.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '🔥 Match Result at $_turfName:\n$winnerText\n$finalScoreText\nTracked live on BYS Turf App!',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Match result copied to clipboard! Share on WhatsApp!')),
              );
            },
            icon: const Icon(Icons.share, color: AppTheme.primaryGreen, size: 18),
            label: Text('Share Result', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/stats', extra: <String, dynamic>{
                'sport': _sport,
                'turfName': _turfName,
                'teamA': _teamA,
                'teamB': _teamB,
                'result': winnerText,
                'scoreDisplay': finalScoreText,
              });
            },
            icon: const Icon(Icons.analytics_outlined, color: Colors.black, size: 16),
            label: Text('View Stats', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2F22)),
            child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            _buildSportIconBadge(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isViewOnly ? 'LIVE MATCH SCORECARD' : 'LIVE SCOREBOARD',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                  ),
                  Text(
                    _turfName,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live pulse pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            tooltip: 'View Match Stats',
            onPressed: () {
              context.push('/stats', extra: <String, dynamic>{
                'sport': _sport,
                'turfName': _turfName,
                'teamA': _teamA,
                'teamB': _teamB,
                'scoreA': _sport == 'cricket' ? '$_cricketRunsA/$_cricketWicketsA' : (_sport == 'football' ? '$_footballTeamAScore' : (_sport == 'badminton' ? '$_badmintonSetsWonA' : '$_basketballScoreA')),
                'scoreB': _sport == 'cricket' ? '$_cricketRunsB/$_cricketWicketsB' : (_sport == 'football' ? '$_footballTeamBScore' : (_sport == 'badminton' ? '$_badmintonSetsWonB' : '$_basketballScoreB')),
              });
            },
          ),
          if (isViewOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(left: 6, right: 12, top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF00E5FF), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'VIEW ONLY',
                    style: GoogleFonts.poppins(color: const Color(0xFF00E5FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen),
              tooltip: 'End Match',
              onPressed: _showEndMatchDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs: Scoreboard, Squads & Members, Timeline
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, isViewOnly ? 'Scorecard' : 'Scoreboard'),
                  ),
                  Expanded(
                    child: _buildTabButton(1, 'Squads (${_teamAMembers.length + _teamBMembers.length})'),
                  ),
                  Expanded(
                    child: _buildTabButton(2, 'Timeline'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _selectedTab == 0
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _buildSquadQuickBar(),
                          _buildSportSpecificScoreboard(),
                        ],
                      ),
                    )
                  : _selectedTab == 1
                      ? _buildSquadsView()
                      : _buildTimelineView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadQuickBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppTheme.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_teamA (${_teamAMembers.length}) vs $_teamB (${_teamBMembers.length})',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryGreen, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Manage Squad',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadsView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2F23)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _teamA,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_teamAMembers.length} Players',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _teamB,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_teamBMembers.length} Players',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Team A Squad Section
          _buildSquadSection(
            teamName: _teamA,
            members: _teamAMembers,
            isTeamA: true,
            accentColor: _teamAColor,
          ),
          const SizedBox(height: 18),

          // Team B Squad Section
          _buildSquadSection(
            teamName: _teamB,
            members: _teamBMembers,
            isTeamA: false,
            accentColor: _teamBColor,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSquadSection({
    required String teamName,
    required List<Map<String, dynamic>> members,
    required bool isTeamA,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$teamName Squad',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isViewOnly)
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(isTeamA: isTeamA),
                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: accentColor),
                  label: Text(
                    'Add Member',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'No members in this team yet.',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6F8275)),
              ),
            )
          else
            ...List.generate(members.length, (idx) {
              final m = members[idx];
              final name = m['name'] as String? ?? 'Player';
              final role = m['role'] as String? ?? 'Member';
              final number = m['number']?.toString() ?? '${idx + 1}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF09120B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1B2B1F)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        number,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                role,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF8E9E94),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildMemberStatsBadge(m),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isViewOnly) ...[
                      // Quick + Score button for this member
                      IconButton(
                        tooltip: 'Add Score for $name',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.add_circle_rounded, color: accentColor, size: 22),
                        onPressed: () => _quickAddScoreForMember(m, isTeamA),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6F8275), size: 18),
                        onPressed: () {
                          setState(() {
                            members.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMemberStatsBadge(Map<String, dynamic> m) {
    String statText = '';
    Color statColor = AppTheme.primaryGreen;

    if (_sport == 'football') {
      final goals = m['goals'] as int? ?? 0;
      if (goals > 0) {
        statText = '⚽ $goals';
      }
    } else if (_sport == 'cricket') {
      final runs = m['runs'] as int? ?? 0;
      final wkts = m['wickets'] as int? ?? 0;
      if (runs > 0 || wkts > 0) {
        statText = '🏏 $runs R${wkts > 0 ? ' • $wkts W' : ''}';
        statColor = const Color(0xFFFFA000);
      }
    } else if (_sport == 'basketball') {
      final pts = m['points'] as int? ?? 0;
      if (pts > 0) {
        statText = '🏀 $pts pts';
        statColor = const Color(0xFFFF7043);
      }
    }

    if (statText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statText,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: statColor,
        ),
      ),
    );
  }

  void _quickAddScoreForMember(Map<String, dynamic> m, bool isTeamA) {
    HapticFeedback.mediumImpact();
    final name = m['name'] as String? ?? 'Player';
    final team = isTeamA ? _teamA : _teamB;

    setState(() {
      if (_sport == 'football') {
        if (isTeamA) {
          _footballTeamAScore++;
        } else {
          _footballTeamBScore++;
        }
        m['goals'] = ((m['goals'] as int? ?? 0) + 1);
        _timelineEvents.insert(0, {
          'time': _formatTime(_footballSeconds),
          'event': '⚽ GOAL!',
          'player': '$name (#${m['number'] ?? ''})',
          'team': team,
        });
      } else if (_sport == 'cricket') {
        if (isTeamA) {
          _cricketRunsA += 4;
        } else {
          _cricketRunsB += 4;
        }
        m['runs'] = ((m['runs'] as int? ?? 0) + 4);
        _timelineEvents.insert(0, {
          'time': 'Event',
          'event': '🏏 FOUR! by $name',
          'player': name,
          'team': team,
        });
      } else if (_sport == 'basketball') {
        if (isTeamA) {
          _basketballScoreA += 2;
        } else {
          _basketballScoreB += 2;
        }
        m['points'] = ((m['points'] as int? ?? 0) + 2);
        _timelineEvents.insert(0, {
          'time': 'Q$_basketballQuarter',
          'event': '🏀 +2 Points by $name',
          'player': name,
          'team': team,
        });
      } else {
        if (isTeamA) {
          _badmintonScoreA++;
        } else {
          _badmintonScoreB++;
        }
        _timelineEvents.insert(0, {
          'time': 'Set $_badmintonCurrentSet',
          'event': 'Point won by $name',
          'player': name,
          'team': team,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score updated for $name ($team)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5)),
        backgroundColor: const Color(0xFF1E2C22),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddMemberDialog({required bool isTeamA}) {
    final nameCtrl = TextEditingController();
    final jerseyCtrl = TextEditingController();
    String role = _sport == 'cricket'
        ? 'Batsman'
        : _sport == 'basketball'
            ? 'Guard'
            : 'Striker';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101912),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final teamName = isTeamA ? _teamA : _teamB;
            final accentColor = isTeamA ? _teamAColor : _teamBColor;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add_rounded, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add Member to $teamName',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF09120B),
                      hintText: 'Member / Player Name',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF5E7064), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1B2B1F)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: jerseyCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF09120B),
                            hintText: 'Jersey #',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF5E7064), fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1B2B1F)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09120B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B2B1F)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: role,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF101912),
                              items: ['Captain', 'Striker', 'Midfielder', 'Defender', 'Goalkeeper', 'Batsman', 'Bowler', 'Guard', 'Forward']
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setModalState(() => role = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        setState(() {
                          final targetList = isTeamA ? _teamAMembers : _teamBMembers;
                          targetList.add({
                            'name': name,
                            'role': role,
                            'number': jerseyCtrl.text.trim().isEmpty ? '${targetList.length + 1}' : jerseyCtrl.text.trim(),
                            'goals': 0,
                            'runs': 0,
                            'wickets': 0,
                            'points': 0,
                            'fouls': 0,
                          });
                          _timelineEvents.insert(0, {
                            'time': 'Live',
                            'event': '👤 $name joined the squad',
                            'player': name,
                            'team': teamName,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Add to $teamName',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabButton(int idx, String title) {
    final isSel = _selectedTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.cardDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSel ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)) : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? AppTheme.primaryGreen : AppTheme.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildSportIconBadge() {
    IconData icon;
    Color color;
    switch (_sport) {
      case 'cricket':
        icon = Icons.sports_cricket;
        color = const Color(0xFFFFA000);
        break;
      case 'badminton':
        icon = Icons.sports_tennis;
        color = const Color(0xFF29B6F6);
        break;
      case 'basketball':
        icon = Icons.sports_basketball;
        color = const Color(0xFFFF7043);
        break;
      case 'tennis':
        icon = Icons.sports_handball;
        color = const Color(0xFFAB47BC);
        break;
      default:
        icon = Icons.sports_soccer;
        color = AppTheme.primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ==========================================
  // DISPATCHER FOR EACH SPORT SCOREBOARD
  // ==========================================
  Widget _buildSportSpecificScoreboard() {
    if (isViewOnly) {
      return Column(
        children: [
          _buildViewOnlyBanner(),
          if (_sport == 'cricket')
            _buildCricketViewOnlyScoreboard()
          else if (_sport == 'badminton' || _sport == 'tennis')
            _buildBadmintonViewOnlyScoreboard()
          else if (_sport == 'basketball')
            _buildBasketballViewOnlyScoreboard()
          else
            _buildFootballViewOnlyScoreboard(),
        ],
      );
    }

    switch (_sport) {
      case 'cricket':
        return _buildCricketScoreboard();
      case 'badminton':
      case 'tennis':
        return _buildBadmintonScoreboard();
      case 'basketball':
        return _buildBasketballScoreboard();
      default:
        return _buildFootballScoreboard();
    }
  }

  // ==========================================
  // VIEW-ONLY SPECTATOR SCOREBOARD WIDGETS
  // ==========================================
  Widget _buildViewOnlyBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.primaryGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spectator Scorecard • View Only',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  'Scores & match highlights are synced live with the turf official.',
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
    );
  }

  Widget _buildFootballViewOnlyScoreboard() {
    return Column(
      children: [
        // Main Header Card (View Only)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Running Clock & Half (View Only, non-clickable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 15, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_footballSeconds),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Half $_footballHalf',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Teams & Big Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Team A
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield, color: AppTheme.primaryGreen, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _teamA.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Score Numbers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '$_footballTeamAScore - $_footballTeamBScore',
                      style: GoogleFonts.poppins(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  // Team B
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.amber, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _teamB.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Live Match Statistics (View Only)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LIVE MATCH STATISTICS',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    'Live Official Feed',
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildStatRow('Goals', '$_footballTeamAScore', '$_footballTeamBScore'),
              _buildStatRow('Yellow Cards', '$_footballYellowCardsA', '$_footballYellowCardsB'),
              _buildStatRow('Red Cards', '$_footballRedCardsA', '$_footballRedCardsB'),
              _buildStatRow('Fouls', '$_footballFoulsA', '$_footballFoulsB'),
              _buildStatRow('Shots on Target', '7', '5'),
              _buildStatRow('Corners', '4', '2'),
              const SizedBox(height: 10),

              // Possession Bar
              Text(
                'Ball Possession',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('55% $_teamA', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  Text('45% $_teamB', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Expanded(flex: 55, child: Container(height: 6, color: AppTheme.primaryGreen)),
                    Expanded(flex: 45, child: Container(height: 6, color: Colors.amber)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Key Events Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1811),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1B2E21)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFFFD600), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'KEY MATCH HIGHLIGHTS',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildHighlightRow("54'", '⚽ Goal scored by Rahul', _teamA),
              _buildHighlightRow("41'", '⚽ Goal scored by David', _teamB),
              _buildHighlightRow("34'", '🟨 Yellow Card issued to Harsh', _teamB),
              _buildHighlightRow("18'", '⚽ Goal scored by Vikram', _teamA),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCricketViewOnlyScoreboard() {
    final balls = _cricketCurrentInning == 1 ? _cricketBallsA : _cricketBallsB;
    final runs = _cricketCurrentInning == 1 ? _cricketRunsA : _cricketRunsB;
    final wickets = _cricketCurrentInning == 1 ? _cricketWicketsA : _cricketWicketsB;
    final battingTeam = _cricketCurrentInning == 1 ? _teamA : _teamB;
    final completedOvers = balls ~/ 6;
    final ballsInOver = balls % 6;
    final overString = '$completedOvers.$ballsInOver';
    final totalOversDecimal = completedOvers + (ballsInOver / 6.0);
    final crr = totalOversDecimal > 0 ? (runs / totalOversDecimal).toStringAsFixed(2) : '0.00';
    final target = _cricketRunsA + 1;
    final runsNeeded = target - runs;
    final ballsRemaining = (_cricketMaxOvers * 6) - balls;

    return Column(
      children: [
        // Main Header Card (View Only)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFA000)),
                ),
                child: Text(
                  'INNINGS $_cricketCurrentInning • LIVE',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFFA000)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    battingTeam.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  Text(' (Batting)', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$runs',
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFFFFA000)),
                  ),
                  Text(
                    ' / $wickets',
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '($overString / $_cricketMaxOvers ov)',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('CRR: $crr', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
                    if (_cricketCurrentInning == 2) ...[
                      Text('Target: $target', style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                      Text(
                        'Need $runsNeeded in $ballsRemaining b',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: runsNeeded <= 0 ? AppTheme.primaryGreen : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('This Over: ', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _cricketCurrentOverBalls.map((b) => _buildBallBadge(b)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Batting & Bowling Summary Card (View Only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE ON CREASE',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              _buildPlayerCreaseRow('Arun K.*', '34 (18)', '4x4, 1x6', isStriker: true),
              const Divider(color: Colors.white12, height: 14),
              _buildPlayerCreaseRow('Rajesh S.', '18 (11)', '2x4, 0x6', isStriker: false),
              const SizedBox(height: 16),
              Text(
                'CURRENT BOWLER',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kiran P. (Blaster XI)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('1.4 ov • 12 runs • 2 wkts', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadmintonViewOnlyScoreboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF29B6F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF29B6F6)),
                ),
                child: Text(
                  'SET $_badmintonCurrentSet • DECIDER (RACE TO $_badmintonTargetPoints)',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF29B6F6)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(_teamA, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Sets Won: $_badmintonSetsWonA', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                  Text(
                    '$_badmintonScoreA - $_badmintonScoreB',
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF29B6F6)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(_teamB, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Sets Won: $_badmintonSetsWonB', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Current Server: ${_badmintonServerIsA ? _teamA : _teamB}',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SET-BY-SET BREAKDOWN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 10),
              _buildStatRow('Set 1', '21', '18'),
              _buildStatRow('Set 2', '17', '21'),
              _buildStatRow('Set 3 (Current)', '$_badmintonScoreA', '$_badmintonScoreB'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasketballViewOnlyScoreboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('QUARTER $_basketballQuarter • LIVE', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF7043))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(_teamA, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Fouls: $_basketballFoulsA', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                  Text(
                    '$_basketballScoreA - $_basketballScoreB',
                    style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFFFF7043)),
                  ),
                  Column(
                    children: [
                      Text(_teamB, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Fouls: $_basketballFoulsB', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUARTER SCORES BREAKDOWN', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF7043))),
              const SizedBox(height: 10),
              _buildStatRow('Quarter 1', '14', '12'),
              _buildStatRow('Quarter 2', '16', '15'),
              _buildStatRow('Quarter 3 (Live)', '12', '11'),
              _buildStatRow('Quarter 4', '-', '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String valA, String valB) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 45,
            child: Text(valA, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(valB, textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String minute, String event, String team) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(minute, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
            ),
          ),
          Text(
            team,
            style: GoogleFonts.poppins(fontSize: 9.5, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCreaseRow(String name, String score, String boundary, {required bool isStriker}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isStriker) const Icon(Icons.star, color: Colors.amber, size: 12),
            const SizedBox(width: 4),
            Text(name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
        Row(
          children: [
            Text(score, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(width: 8),
            Text(boundary, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 1. FOOTBALL SCOREBOARD
  // ==========================================
  Widget _buildFootballScoreboard() {
    return Column(
      children: [
        // Main Score Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Timer & Half
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _startStopTimer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isTimerRunning ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isTimerRunning ? AppTheme.primaryGreen : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isTimerRunning ? Icons.pause : Icons.play_arrow,
                            size: 16,
                            color: _isTimerRunning ? AppTheme.primaryGreen : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_footballSeconds),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isTimerRunning ? AppTheme.primaryGreen : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Half $_footballHalf',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                    tooltip: 'Reset Timer',
                    onPressed: () => setState(() => _footballSeconds = 0),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Teams & Big Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Team A
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield, color: AppTheme.primaryGreen, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _teamA.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Score Numbers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '$_footballTeamAScore - $_footballTeamBScore',
                      style: GoogleFonts.poppins(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  // Team B
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.amber, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _teamB.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Controls Grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Team A
            Expanded(
              child: _buildTeamScoringColumn(
                teamName: _teamA,
                color: AppTheme.primaryGreen,
                onAddGoal: () => _addFootballGoal(true),
                onRemoveGoal: () => _footballTeamAScore > 0 ? _removeFootballGoal(true) : null,
                yellowCards: _footballYellowCardsA,
                redCards: _footballRedCardsA,
                fouls: _footballFoulsA,
                onAddYellowCard: () => setState(() => _footballYellowCardsA++),
                onAddRedCard: () => setState(() => _footballRedCardsA++),
                onAddFoul: () => setState(() => _footballFoulsA++),
              ),
            ),
            const SizedBox(width: 14),
            // Controls Team B
            Expanded(
              child: _buildTeamScoringColumn(
                teamName: _teamB,
                color: Colors.amber,
                onAddGoal: () => _addFootballGoal(false),
                onRemoveGoal: () => _footballTeamBScore > 0 ? _removeFootballGoal(false) : null,
                yellowCards: _footballYellowCardsB,
                redCards: _footballRedCardsB,
                fouls: _footballFoulsB,
                onAddYellowCard: () => setState(() => _footballYellowCardsB++),
                onAddRedCard: () => setState(() => _footballRedCardsB++),
                onAddFoul: () => setState(() => _footballFoulsB++),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Half switcher button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _footballHalf = _footballHalf == 1 ? 2 : 1;
                _timelineEvents.insert(0, {
                  'time': _formatTime(_footballSeconds),
                  'event': _footballHalf == 2 ? '2nd Half Started' : '1st Half Started',
                  'player': 'Referee',
                  'team': _turfName,
                });
              });
            },
            icon: const Icon(Icons.sync_alt, color: AppTheme.primaryGreen, size: 18),
            label: Text('Switch to Half ${_footballHalf == 1 ? 2 : 1}', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamScoringColumn({
    required String teamName,
    required Color color,
    required VoidCallback onAddGoal,
    required VoidCallback? onRemoveGoal,
    required int yellowCards,
    required int redCards,
    required int fouls,
    required VoidCallback onAddYellowCard,
    required VoidCallback onAddRedCard,
    required VoidCallback onAddFoul,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Big Goal Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAddGoal,
              icon: const Icon(Icons.sports_soccer, size: 18, color: Colors.black),
              label: Text('+ GOAL', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Remove Goal & Foul row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemoveGoal,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('- Goal', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAddFoul,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text('Foul ($fouls)', style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Cards row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: onAddYellowCard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.yellow.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 12, color: Colors.yellow),
                      const SizedBox(width: 4),
                      Text('$yellowCards', style: GoogleFonts.poppins(fontSize: 11, color: Colors.yellow, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onAddRedCard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('$redCards', style: GoogleFonts.poppins(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. CRICKET SCOREBOARD
  // ==========================================
  Widget _buildCricketScoreboard() {
    final isFirstInnings = _cricketCurrentInning == 1;
    final battingTeam = isFirstInnings ? _teamA : _teamB;
    final bowlingTeam = isFirstInnings ? _teamB : _teamA;
    final runs = isFirstInnings ? _cricketRunsA : _cricketRunsB;
    final wickets = isFirstInnings ? _cricketWicketsA : _cricketWicketsB;
    final balls = isFirstInnings ? _cricketBallsA : _cricketBallsB;

    final completedOvers = balls ~/ 6;
    final ballsInOver = balls % 6;
    final overString = '$completedOvers.$ballsInOver';

    // Current Run Rate
    final totalOversDecimal = completedOvers + (ballsInOver / 6.0);
    final crr = totalOversDecimal > 0 ? (runs / totalOversDecimal).toStringAsFixed(2) : '0.00';

    // Target calculation for Inning 2
    int target = _cricketRunsA + 1;
    int runsNeeded = target - runs;
    int ballsRemaining = (_cricketMaxOvers * 6) - balls;

    return Column(
      children: [
        // Main Cricket Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Inning badge and switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFA000)),
                    ),
                    child: Text(
                      'INNINGS $_cricketCurrentInning',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFFA000)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _switchCricketInnings,
                    icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryGreen, size: 18),
                    label: Text(
                      isFirstInnings ? 'Start 2nd Innings' : 'View 1st Innings',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Batting team name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_cricket, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    battingTeam.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  Text(' (Batting)', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
              const SizedBox(height: 10),

              // Big Score: 64/2
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$runs',
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFFFFA000)),
                  ),
                  Text(
                    ' / $wickets',
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '($overString / $_cricketMaxOvers ov)',
                    style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Run rate bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('CRR: $crr', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
                    if (!isFirstInnings) ...[
                      Text(
                        'Target: $target',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Need $runsNeeded in $ballsRemaining b',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: runsNeeded <= 0 ? AppTheme.primaryGreen : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      Text('Bowling: $bowlingTeam', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Current Over Balls: [0] [1] [4] [W]
              Row(
                children: [
                  Text('This Over: ', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _cricketCurrentOverBalls.isEmpty
                            ? [Text('Start of over', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38))]
                            : _cricketCurrentOverBalls.map((b) => _buildBallBadge(b)).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.grey, size: 20),
                    tooltip: 'Undo Ball',
                    onPressed: _undoCricketBall,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Scoring Keypad
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BALL-BY-BALL SCORING PAD',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),

              // Rows of keypad
              Row(
                children: [
                  _buildKeypadButton('0', () => _addCricketBall(0), color: Colors.grey.shade800),
                  const SizedBox(width: 8),
                  _buildKeypadButton('1', () => _addCricketBall(1), color: Colors.grey.shade800),
                  const SizedBox(width: 8),
                  _buildKeypadButton('2', () => _addCricketBall(2), color: Colors.grey.shade800),
                  const SizedBox(width: 8),
                  _buildKeypadButton('3', () => _addCricketBall(3), color: Colors.grey.shade800),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKeypadButton('4 FOUR', () => _addCricketBall(4), color: const Color(0xFF1E88E5), textColor: Colors.white, isBold: true),
                  const SizedBox(width: 8),
                  _buildKeypadButton('6 SIX', () => _addCricketBall(6), color: AppTheme.primaryGreen, textColor: Colors.black, isBold: true),
                  const SizedBox(width: 8),
                  _buildKeypadButton('WICKET', () => _addCricketBall(0, isWicket: true), color: AppTheme.errorRed, textColor: Colors.white, isBold: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKeypadButton('Wide (+1)', () => _addCricketBall(0, isWide: true), color: Colors.orange.shade900),
                  const SizedBox(width: 8),
                  _buildKeypadButton('No Ball (+1)', () => _addCricketBall(0, isNoBall: true), color: Colors.purple.shade900),
                  const SizedBox(width: 8),
                  _buildKeypadButton('Undo ↩', _undoCricketBall, color: Colors.white12, textColor: Colors.white70),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBallBadge(String val) {
    Color bg = Colors.white12;
    Color fg = Colors.white;
    if (val == '4') {
      bg = const Color(0xFF1E88E5);
      fg = Colors.white;
    } else if (val == '6') {
      bg = AppTheme.primaryGreen;
      fg = Colors.black;
    } else if (val == 'W') {
      bg = AppTheme.errorRed;
      fg = Colors.white;
    } else if (val == 'Wd' || val == 'Nb') {
      bg = Colors.orange;
      fg = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          val,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(
    String label,
    VoidCallback onTap, {
    required Color color,
    Color textColor = Colors.white,
    bool isBold = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 3. BADMINTON / TENNIS SCOREBOARD
  // ==========================================
  Widget _buildBadmintonScoreboard() {
    return Column(
      children: [
        // Sets Tracker Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF29B6F6).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'SET $_badmintonCurrentSet (Target: $_badmintonTargetPoints pts)',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF29B6F6)),
              ),
              const SizedBox(height: 16),

              // Big Sets Won Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          if (_badmintonServerIsA)
                            const Icon(Icons.sports_tennis, color: AppTheme.primaryGreen, size: 16),
                          const SizedBox(width: 4),
                          Text(_teamA, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Text('Sets Won: $_badmintonSetsWonA', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                  Text('VS', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  Column(
                    children: [
                      Row(
                        children: [
                          if (!_badmintonServerIsA)
                            const Icon(Icons.sports_tennis, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(_teamB, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Text('Sets Won: $_badmintonSetsWonB', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current Set Large Points Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_badmintonScoreA',
                    style: GoogleFonts.poppins(fontSize: 54, fontWeight: FontWeight.w900, color: const Color(0xFF29B6F6)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(':', style: GoogleFonts.poppins(fontSize: 40, color: Colors.white30)),
                  ),
                  Text(
                    '$_badmintonScoreB',
                    style: GoogleFonts.poppins(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.amber),
                  ),
                ],
              ),

              if (_badmintonSetHistory.isNotEmpty) ...[
                const Divider(color: AppTheme.cardBorder, height: 24),
                Wrap(
                  spacing: 8,
                  children: _badmintonSetHistory.map((s) => Chip(
                    label: Text(s, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                    backgroundColor: AppTheme.surfaceDark,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Big Tactile Tap Points Buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () => _addBadmintonPoint(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
                      const SizedBox(height: 4),
                      Text('+1 Point $_teamA', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ElevatedButton(
                  onPressed: () => _addBadmintonPoint(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
                      const SizedBox(height: 4),
                      Text('+1 Point $_teamB', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Auxiliary actions: Switch Server, Undo
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _badmintonServerIsA = !_badmintonServerIsA),
                icon: const Icon(Icons.swap_calls, size: 18, color: Colors.white70),
                label: Text('Switch Server', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cardBorder)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_badmintonScoreA > 0 || _badmintonScoreB > 0) {
                    if (_badmintonScoreA > _badmintonScoreB) {
                      _undoBadmintonPoint(true);
                    } else {
                      _undoBadmintonPoint(false);
                    }
                  }
                },
                icon: const Icon(Icons.undo, size: 18, color: Colors.white70),
                label: Text('Undo Point', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cardBorder)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 4. BASKETBALL SCOREBOARD
  // ==========================================
  Widget _buildBasketballScoreboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF7043).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('QUARTER $_basketballQuarter', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF7043))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(_teamA, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Fouls: $_basketballFoulsA', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                  Text(
                    '$_basketballScoreA - $_basketballScoreB',
                    style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w900, color: const Color(0xFFFF7043)),
                  ),
                  Column(
                    children: [
                      Text(_teamB, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Fouls: $_basketballFoulsB', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Point buttons for Team A & Team B
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(_teamA, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => _addBasketballPoints(true, 1), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark), child: const Text('+1 Free Throw')),
                  const SizedBox(height: 6),
                  ElevatedButton(onPressed: () => _addBasketballPoints(true, 2), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen), child: const Text('+2 Field Goal', style: TextStyle(color: Colors.black))),
                  const SizedBox(height: 6),
                  ElevatedButton(onPressed: () => _addBasketballPoints(true, 3), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), child: const Text('+3 Three-Pointer')),
                  const SizedBox(height: 6),
                  OutlinedButton(onPressed: () => setState(() => _basketballFoulsA++), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)), child: const Text('+ Foul', style: TextStyle(fontSize: 11, color: Colors.orange))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Text(_teamB, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => _addBasketballPoints(false, 1), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark), child: const Text('+1 Free Throw')),
                  const SizedBox(height: 6),
                  ElevatedButton(onPressed: () => _addBasketballPoints(false, 2), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: const Text('+2 Field Goal', style: TextStyle(color: Colors.black))),
                  const SizedBox(height: 6),
                  ElevatedButton(onPressed: () => _addBasketballPoints(false, 3), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent), child: const Text('+3 Three-Pointer')),
                  const SizedBox(height: 6),
                  OutlinedButton(onPressed: () => setState(() => _basketballFoulsB++), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)), child: const Text('+ Foul', style: TextStyle(fontSize: 11, color: Colors.orange))),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _basketballQuarter = (_basketballQuarter % 4) + 1),
          icon: const Icon(Icons.skip_next, color: AppTheme.primaryGreen),
          label: Text('Advance to Quarter ${_basketballQuarter < 4 ? _basketballQuarter + 1 : 1}', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cardBorder)),
        ),
      ],
    );
  }

  // ==========================================
  // TIMELINE VIEW
  // ==========================================
  Widget _buildTimelineView() {
    if (_timelineEvents.isEmpty) {
      return Center(
        child: Text('No match events logged yet.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timelineEvents.length,
      itemBuilder: (context, index) {
        final ev = _timelineEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ev['time']!,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev['event']!,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      '${ev['player']} • ${ev['team']}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
