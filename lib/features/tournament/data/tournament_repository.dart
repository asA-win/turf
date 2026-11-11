import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class TournamentRepository extends ChangeNotifier {
  static final TournamentRepository instance = TournamentRepository._internal();

  TournamentRepository._internal() {
    _tournaments = _cloneInitialTournaments();
  }

  factory TournamentRepository() => instance;

  List<Map<String, dynamic>> _tournaments = [];
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> syncWithBackend(Dio dio) async {
    try {
      _isSyncing = true;
      final res = await dio.get('/tournaments/');
      final data = res.data;
      if (data is List && data.isNotEmpty) {
        for (final item in data) {
          final backendId = item['id'];
          final idStr = 'tourn_$backendId';
          final existingIdx = _tournaments.indexWhere((t) => t['id'] == idStr || t['backendId'] == backendId);
          final title = item['title'] ?? 'Tournament Championship';
          final prize = item['prize_pool'] != null ? '₹${(item['prize_pool'] as num).toInt()}' : '₹50,000';
          final totalTeams = (item['total_teams'] as num?)?.toInt() ?? 16;
          final format = item['format'] ?? 'Knockout';
          final status = (item['status'] == 'upcoming') ? 'Open for Registration' : (item['status'] ?? 'Open for Registration');

          if (existingIdx != -1) {
            _tournaments[existingIdx]['name'] = title;
            _tournaments[existingIdx]['prizePool'] = prize;
            _tournaments[existingIdx]['totalSpots'] = totalTeams;
            _tournaments[existingIdx]['format'] = format;
            _tournaments[existingIdx]['status'] = status;
          } else {
            _tournaments.insert(0, {
              'id': idStr,
              'backendId': backendId,
              'name': title,
              'sport': 'Football',
              'status': status,
              'prizePool': prize,
              'entryFee': '₹1,500',
              'entryFeeAmount': 1500,
              'totalSpots': totalTeams,
              'spotsFilled': 8,
              'format': format,
              'venue': 'Play Arena',
              'area': 'Koramangala',
              'city': 'Bangalore',
              'date': 'Coming Soon',
              'registeredTeams': _generateDefaultTeamsForSport('Football', 8),
              'fixtures': <Map<String, dynamic>>[],
              'fixturesGenerated': false,
            });
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing tournaments with backend: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void handleRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'tournament_created') {
      final tData = event['tournament'] as Map<String, dynamic>?;
      if (tData != null) {
        final backendId = tData['id'];
        final idStr = 'tourn_$backendId';
        if (!_tournaments.any((t) => t['id'] == idStr || t['backendId'] == backendId)) {
          _tournaments.insert(0, {
            'id': idStr,
            'backendId': backendId,
            'name': tData['title'] ?? 'Tournament Championship',
            'sport': 'Football',
            'status': tData['status'] ?? 'Open for Registration',
            'prizePool': tData['prize_pool'] != null ? '₹${(tData['prize_pool'] as num).toInt()}' : '₹50,000',
            'entryFee': '₹1,500',
            'entryFeeAmount': 1500,
            'totalSpots': (tData['total_teams'] as num?)?.toInt() ?? 16,
            'spotsFilled': 1,
            'format': tData['format'] ?? 'Knockout',
            'venue': 'Play Arena',
            'area': 'Koramangala',
            'city': 'Bangalore',
            'date': 'Coming Soon',
            'registeredTeams': _generateDefaultTeamsForSport('Football', 1),
            'fixtures': <Map<String, dynamic>>[],
            'fixturesGenerated': false,
            'isLive': true,
          });
          notifyListeners();
        }
      }
    } else if (type == 'tournament_registered') {
      final backendId = event['tournament_id'];
      final teamName = event['team_name'] as String? ?? 'Challenger Team';
      final idx = _tournaments.indexWhere((t) => t['backendId'] == backendId || t['id'] == 'tourn_$backendId');
      if (idx != -1) {
        final t = Map<String, dynamic>.from(_tournaments[idx]);
        final spotsFilled = (t['spotsFilled'] as num?)?.toInt() ?? 0;
        final totalSpots = (t['totalSpots'] as num?)?.toInt() ?? 16;
        if (spotsFilled < totalSpots) {
          t['spotsFilled'] = spotsFilled + 1;
        }
        final teams = List<Map<String, dynamic>>.from(t['registeredTeams'] ?? []);
        teams.add({
          'name': teamName,
          'seed': teams.length + 1,
          'status': 'Confirmed',
          'captain': 'Captain',
        });
        t['registeredTeams'] = teams;
        _tournaments[idx] = t;
        notifyListeners();
      }
    }
  }

  List<Map<String, dynamic>> get tournaments {
    if (_tournaments.isEmpty) {
      _tournaments = _cloneInitialTournaments();
    }
    return List.unmodifiable(_tournaments);
  }

  List<Map<String, dynamic>> _cloneInitialTournaments() {
    return initialTournaments.map((t) {
      final copy = Map<String, dynamic>.from(t);
      final sport = (copy['sport'] as String? ?? 'Football');
      final spotsFilled = (copy['spotsFilled'] as num?)?.toInt() ?? 8;
      copy['registeredTeams'] = _generateDefaultTeamsForSport(sport, spotsFilled);
      copy['fixtures'] = copy['fixtures'] != null
          ? List<Map<String, dynamic>>.from(copy['fixtures'])
          : <Map<String, dynamic>>[];
      copy['fixturesGenerated'] = copy['fixturesGenerated'] ?? false;
      return copy;
    }).toList();
  }

  Map<String, dynamic>? getTournamentById(String? tournamentId) {
    if (tournamentId == null) return null;
    final idx = _tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (idx != -1) return _tournaments[idx];
    return null;
  }

  void addTournament(Map<String, dynamic> tournament) {
    final t = Map<String, dynamic>.from(tournament);
    final sport = (t['sport'] as String? ?? 'Football');
    final spotsFilled = (t['spotsFilled'] as num?)?.toInt() ?? 1;
    if (t['registeredTeams'] == null) {
      t['registeredTeams'] = _generateDefaultTeamsForSport(sport, spotsFilled, includeUserTeam: true);
    }
    t['fixtures'] = t['fixtures'] ?? <Map<String, dynamic>>[];
    t['fixturesGenerated'] = t['fixturesGenerated'] ?? false;
    _tournaments.insert(0, t);
    notifyListeners();
  }

  void updateTournament(String tournamentId, Map<String, dynamic> updates) {
    final idx = _tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (idx != -1) {
      final t = Map<String, dynamic>.from(_tournaments[idx]);
      t.addAll(updates);
      _tournaments[idx] = t;
      notifyListeners();
    }
  }

  Future<void> registerTeamForTournament(String tournamentId, Map<String, dynamic> registration, {Dio? dio}) async {
    final idx = _tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (idx != -1) {
      final t = Map<String, dynamic>.from(_tournaments[idx]);
      final currentFilled = (t['spotsFilled'] as num?)?.toInt() ?? 0;
      final total = (t['totalSpots'] as num?)?.toInt() ?? 16;
      if (currentFilled < total) {
        t['spotsFilled'] = currentFilled + 1;
      }
      t['isRegisteredByYou'] = true;

      final regWithMeta = Map<String, dynamic>.from(registration);
      regWithMeta['id'] = regWithMeta['id'] ?? 'team_${DateTime.now().millisecondsSinceEpoch}';
      regWithMeta['isUserTeam'] = true;
      regWithMeta['rating'] = regWithMeta['rating'] ?? 4.8;

      final registeredTeams = List<Map<String, dynamic>>.from(t['registeredTeams'] ?? []);
      // Add user team at the front for visibility
      registeredTeams.insert(0, regWithMeta);
      t['registeredTeams'] = registeredTeams;

      _tournaments[idx] = t;
      notifyListeners();

      if (dio != null) {
        try {
          final backendId = t['backendId'] ?? int.tryParse(tournamentId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
          await dio.post('/tournaments/register', data: {
            'tournament_id': backendId,
            'team_name': registration['teamName'] ?? 'My Squad FC',
          });
        } catch (e) {
          debugPrint('Backend tournament registration error: $e');
        }
      }
    }
  }

  List<Map<String, dynamic>> generateAIFixtures(
    String tournamentId, {
    String strategy = 'balanced',
  }) {
    final idx = _tournaments.indexWhere((t) => t['id'] == tournamentId);
    if (idx == -1) return [];

    final t = Map<String, dynamic>.from(_tournaments[idx]);
    final venue = t['venue'] as String? ?? 'Play Arena';
    final sport = (t['sport'] as String? ?? 'Football');

    // Retrieve or seed registered teams
    var teams = List<Map<String, dynamic>>.from(t['registeredTeams'] ?? []);
    if (teams.isEmpty) {
      teams = _generateDefaultTeamsForSport(sport, 8);
      t['registeredTeams'] = teams;
      t['spotsFilled'] = teams.length;
    }

    // Determine target bracket size (4, 8, or 16)
    int bracketSize = 8;
    if (teams.length <= 4) {
      bracketSize = 4;
    } else if (teams.length <= 8) {
      bracketSize = 8;
    } else {
      bracketSize = 16;
    }

    // Ensure we have enough teams up to bracketSize
    while (teams.length < bracketSize) {
      final seedIdx = teams.length + 1;
      teams.add({
        'id': 'team_seed_$seedIdx',
        'teamName': 'Challenger Seed XI #$seedIdx',
        'teamTag': 'CS$seedIdx',
        'captainName': 'Captain $seedIdx',
        'jerseyColor': 'Midnight Black',
        'skillLevel': 'Club / Competitive',
        'rating': 4.2 + ((seedIdx % 6) * 0.1),
        'playersCount': 7,
        'isUserTeam': false,
        'registeredAt': 'Seeded Entry',
        'players': [
          {'name': 'Captain $seedIdx', 'role': 'Captain', 'jersey': '10'},
          {'name': 'Player A', 'role': 'Midfielder', 'jersey': '7'},
          {'name': 'Player B', 'role': 'Goalkeeper', 'jersey': '1'},
        ],
      });
    }

    final matchTeams = List<Map<String, dynamic>>.from(teams.take(bracketSize));

    // Sort or seed according to strategy
    if (strategy == 'balanced') {
      matchTeams.sort((a, b) => ((b['rating'] as num?)?.toDouble() ?? 4.0)
          .compareTo((a['rating'] as num?)?.toDouble() ?? 4.0));
    } else if (strategy == 'seeded') {
      matchTeams.sort((a, b) => ((b['rating'] as num?)?.toDouble() ?? 4.0)
          .compareTo((a['rating'] as num?)?.toDouble() ?? 4.0));
      final seeded = <Map<String, dynamic>>[];
      for (int i = 0; i < bracketSize / 2; i++) {
        seeded.add(matchTeams[i]);
        seeded.add(matchTeams[bracketSize - 1 - i]);
      }
      matchTeams.clear();
      matchTeams.addAll(seeded);
    } else {
      matchTeams.shuffle();
    }

    final fixtures = <Map<String, dynamic>>[];
    final pitches = ['Pitch A (Main Court)', 'Pitch B (North Arena)', 'Pitch C (West Turf)'];
    final timeSlots = [
      'Day 1 • 05:00 PM',
      'Day 1 • 06:15 PM',
      'Day 1 • 07:30 PM',
      'Day 1 • 08:45 PM',
      'Day 2 • 05:30 PM',
      'Day 2 • 06:45 PM',
      'Day 2 • 08:00 PM',
      'Day 3 • 06:00 PM',
    ];

    int matchNumber = 1;
    final int round1Matches = bracketSize ~/ 2;

    // Round 1 / Quarter Finals
    for (int i = 0; i < matchTeams.length; i += 2) {
      final team1 = matchTeams[i];
      final team2 = matchTeams[i + 1];
      final r1 = (team1['rating'] as num?)?.toDouble() ?? 4.5;
      final r2 = (team2['rating'] as num?)?.toDouble() ?? 4.5;
      final diff = (r1 - r2).abs();
      final parityScore = (100 - (diff * 20)).clamp(86, 99).toInt();

      final t1Prob = (50 + ((r1 - r2) * 15)).clamp(42, 58).toInt();
      final t2Prob = 100 - t1Prob;

      final isUserMatch = (team1['isUserTeam'] == true) || (team2['isUserTeam'] == true);
      final stage = bracketSize == 16
          ? 'Round of 16 • Match $matchNumber'
          : 'Quarter Final $matchNumber';
      final stageGroup = bracketSize == 16 ? 'Round of 16' : 'Quarter Finals';

      fixtures.add({
        'id': 'fix_$matchNumber',
        'matchNumber': matchNumber,
        'round': 1,
        'stage': stage,
        'stageGroup': stageGroup,
        't1': team1['teamName'] as String,
        't1Tag': team1['teamTag'] as String? ?? 'T1',
        't1Rating': r1,
        't1Color': team1['jerseyColor'] as String? ?? 'Royal Blue',
        't1IsUser': team1['isUserTeam'] == true,
        't2': team2['teamName'] as String,
        't2Tag': team2['teamTag'] as String? ?? 'T2',
        't2Rating': r2,
        't2Color': team2['jerseyColor'] as String? ?? 'Neon Green',
        't2IsUser': team2['isUserTeam'] == true,
        'time': timeSlots[(matchNumber - 1) % timeSlots.length],
        'venue': '$venue • ${pitches[(matchNumber - 1) % pitches.length]}',
        'pitch': pitches[(matchNumber - 1) % pitches.length],
        'status': 'Scheduled (AI Assigned)',
        'isUserMatch': isUserMatch,
        'aiBalanceScore': parityScore,
        'aiNote': 'Balanced tactical matchup ($parityScore% parity). Rest periods & turf slots optimized.',
        't1WinProb': t1Prob,
        't2WinProb': t2Prob,
      });

      matchNumber++;
    }

    // Semi Finals (Round 2)
    final sfCount = round1Matches ~/ 2;
    for (int i = 0; i < sfCount; i++) {
      final t1Name = 'Winner Match ${i * 2 + 1}';
      final t2Name = 'Winner Match ${i * 2 + 2}';
      fixtures.add({
        'id': 'fix_$matchNumber',
        'matchNumber': matchNumber,
        'round': 2,
        'stage': 'Semi Final ${i + 1}',
        'stageGroup': 'Semi Finals',
        't1': t1Name,
        't1Tag': 'SF${i * 2 + 1}',
        't1Rating': 4.8,
        't1Color': 'Royal Blue',
        't1IsUser': false,
        't2': t2Name,
        't2Tag': 'SF${i * 2 + 2}',
        't2Rating': 4.7,
        't2Color': 'Sun Yellow',
        't2IsUser': false,
        'time': 'Day 3 • 0${6 + i}:00 PM',
        'venue': '$venue • Pitch A (Main Court)',
        'pitch': 'Pitch A (Main Court)',
        'status': 'TBD • Awaiting Round 1',
        'isUserMatch': false,
        'aiBalanceScore': 95,
        'aiNote': 'High stakes semi-final slot reserved on center pitch.',
        't1WinProb': 50,
        't2WinProb': 50,
      });
      matchNumber++;
    }

    // Grand Championship Final (Round 3)
    fixtures.add({
      'id': 'fix_$matchNumber',
      'matchNumber': matchNumber,
      'round': 3,
      'stage': 'Grand Final Championship',
      'stageGroup': 'Final',
      't1': 'Winner Semi Final 1',
      't1Tag': 'FINAL 1',
      't1Rating': 4.9,
      't1Color': 'Gold & Green',
      't1IsUser': false,
      't2': 'Winner Semi Final 2',
      't2Tag': 'FINAL 2',
      't2Rating': 4.9,
      't2Color': 'Silver & Black',
      't2IsUser': false,
      'time': 'Day 4 • 07:30 PM (Grand Finale)',
      'venue': '$venue • Championship Center Pitch',
      'pitch': 'Championship Center Pitch',
      'status': 'TBD • Grand Finale',
      'isUserMatch': false,
      'aiBalanceScore': 98,
      'aiNote': 'Championship decider. Trophy presentation and live broadcast scheduled.',
      't1WinProb': 50,
      't2WinProb': 50,
    });

    t['fixtures'] = fixtures;
    t['fixturesGenerated'] = true;
    t['aiFixtureMeta'] = {
      'generatedAt': DateTime.now().toIso8601String(),
      'strategy': strategy,
      'balanceParity': '95.6%',
      'totalMatches': fixtures.length,
      'aiModel': 'BYS Sports Matchmaker AI v2.4',
    };

    _tournaments[idx] = t;
    notifyListeners();
    return fixtures;
  }

  static List<Map<String, dynamic>> _generateDefaultTeamsForSport(
    String sport,
    int count, {
    bool includeUserTeam = false,
  }) {
    final s = sport.toLowerCase();
    final List<Map<String, dynamic>> result = [];

    if (includeUserTeam) {
      result.add({
        'id': 'team_user_lead',
        'teamName': 'My Squad XI',
        'teamTag': 'MSX',
        'captainName': 'You (Captain)',
        'contactPhone': '+91 98765 43210',
        'jerseyColor': 'Neon Green',
        'skillLevel': 'Advanced / Semi-Pro',
        'rating': 4.8,
        'playersCount': 7,
        'isUserTeam': true,
        'registeredAt': 'Creator Squad',
        'players': [
          {'name': 'You (Captain)', 'role': 'Captain (Striker)', 'jersey': '10'},
          {'name': 'Rohan Sen', 'role': 'Midfielder', 'jersey': '8'},
          {'name': 'Aditya Verma', 'role': 'Goalkeeper', 'jersey': '1'},
          {'name': 'Karthik Rao', 'role': 'Defender', 'jersey': '4'},
          {'name': 'Manish K.', 'role': 'Winger', 'jersey': '7'},
          {'name': 'Dev Joshi', 'role': 'Defender', 'jersey': '3'},
          {'name': 'Sameer P.', 'role': 'Forward', 'jersey': '11'},
        ],
      });
    }

    if (s.contains('cricket')) {
      final cricketTemplates = [
        {'name': 'Bangalore Royal Strikers', 'tag': 'BRS', 'captain': 'Rohit Varma', 'color': 'Royal Blue', 'rating': 4.8},
        {'name': 'Koramangala Blasters', 'tag': 'KMB', 'captain': 'Suresh Raina', 'color': 'Sun Yellow', 'rating': 4.7},
        {'name': 'Indiranagar Smashers', 'tag': 'INS', 'captain': 'Amit Patel', 'color': 'Fire Red', 'rating': 4.6},
        {'name': 'Electronic City Eleven', 'tag': 'ECE', 'captain': 'Vijay Kumar', 'color': 'Neon Green', 'rating': 4.5},
        {'name': 'Turf Kings CC', 'tag': 'TKC', 'captain': 'Ajay Sharma', 'color': 'Midnight Black', 'rating': 4.4},
        {'name': 'Whitefield Warriors', 'tag': 'WFW', 'captain': 'Karthik Reddy', 'color': 'Clean White', 'rating': 4.6},
        {'name': 'HSR Spartans CC', 'tag': 'HSR', 'captain': 'Sandeep Singh', 'color': 'Purple', 'rating': 4.5},
        {'name': 'East Bangalore Mavericks', 'tag': 'EBM', 'captain': 'Praveen Rao', 'color': 'Orange', 'rating': 4.7},
      ];
      for (int i = 0; i < count && i < cricketTemplates.length; i++) {
        final t = cricketTemplates[i];
        result.add({
          'id': 'cricket_team_${i + 1}',
          'teamName': t['name'],
          'teamTag': t['tag'],
          'captainName': t['captain'],
          'contactPhone': '+91 98450 11${20 + i}',
          'jerseyColor': t['color'],
          'skillLevel': 'Intermediate / Club',
          'rating': t['rating'],
          'playersCount': 7,
          'isUserTeam': false,
          'registeredAt': '1${i + 1} May 2025',
          'players': [
            {'name': t['captain'] as String, 'role': 'Captain (Batsman)', 'jersey': '7'},
            {'name': 'Karthik R.', 'role': 'All-Rounder', 'jersey': '18'},
            {'name': 'Siddharth M.', 'role': 'Fast Bowler', 'jersey': '24'},
            {'name': 'Aditya N.', 'role': 'Wicket-Keeper', 'jersey': '1'},
            {'name': 'Arjun D.', 'role': 'Spinner', 'jersey': '99'},
            {'name': 'Manish K.', 'role': 'Batsman', 'jersey': '45'},
            {'name': 'Sameer K.', 'role': 'Finisher', 'jersey': '11'},
          ],
        });
      }
    } else if (s.contains('badminton') || s.contains('tennis')) {
      final racketTemplates = [
        {'name': 'Smash Aces Duo', 'tag': 'SAD', 'captain': 'Vikram Rathore', 'color': 'Royal Blue', 'rating': 4.8},
        {'name': 'Shuttle Masters', 'tag': 'SHM', 'captain': 'Prateek Jain', 'color': 'Neon Green', 'rating': 4.7},
        {'name': 'Victory Smashers', 'tag': 'VSM', 'captain': 'Rohan Nair', 'color': 'Fire Red', 'rating': 4.6},
        {'name': 'Net Dominators', 'tag': 'NDM', 'captain': 'Kunal Sen', 'color': 'Sun Yellow', 'rating': 4.5},
        {'name': 'Spin Serves Pair', 'tag': 'SSP', 'captain': 'Deepak Joshi', 'color': 'Purple', 'rating': 4.4},
        {'name': 'Baseline Kings', 'tag': 'BLK', 'captain': 'Tarun Paul', 'color': 'Clean White', 'rating': 4.6},
      ];
      for (int i = 0; i < count && i < racketTemplates.length; i++) {
        final t = racketTemplates[i];
        result.add({
          'id': 'racket_team_${i + 1}',
          'teamName': t['name'],
          'teamTag': t['tag'],
          'captainName': t['captain'],
          'contactPhone': '+91 98112 33${40 + i}',
          'jerseyColor': t['color'],
          'skillLevel': 'Open Category',
          'rating': t['rating'],
          'playersCount': 2,
          'isUserTeam': false,
          'registeredAt': '1${i + 2} May 2025',
          'players': [
            {'name': t['captain'] as String, 'role': 'Main Player (Captain)', 'jersey': '1'},
            {'name': 'Doubles Partner', 'role': 'Doubles Partner', 'jersey': '2'},
          ],
        });
      }
    } else {
      // Default Football / Futsal / General
      final footballTemplates = [
        {'name': 'Koramangala Titans', 'tag': 'KMT', 'captain': 'Vikram Rathore', 'color': 'Royal Blue', 'rating': 4.8},
        {'name': 'Apex Predators FC', 'tag': 'APX', 'captain': 'Rahul Sen', 'color': 'Neon Green', 'rating': 4.7},
        {'name': 'Green Blitz United', 'tag': 'GBU', 'captain': 'Arun Nair', 'color': 'Sun Yellow', 'rating': 4.6},
        {'name': 'Indiranagar Hawks', 'tag': 'INH', 'captain': 'Dev Malhotra', 'color': 'Fire Red', 'rating': 4.5},
        {'name': 'Urban Kickers FC', 'tag': 'UKF', 'captain': 'Sameer Khan', 'color': 'Midnight Black', 'rating': 4.4},
        {'name': 'Velocity Sports FC', 'tag': 'VSF', 'captain': 'Rohan Mehta', 'color': 'Clean White', 'rating': 4.6},
        {'name': 'Spartans Arena', 'tag': 'SPA', 'captain': 'Siddharth Rao', 'color': 'Purple', 'rating': 4.7},
        {'name': 'Thunderbolts FC', 'tag': 'TBF', 'captain': 'Kabir Joshi', 'color': 'Orange', 'rating': 4.5},
        {'name': 'Golden Eagles FC', 'tag': 'GDE', 'captain': 'Manish Paul', 'color': 'Royal Blue', 'rating': 4.3},
        {'name': 'City Strikers', 'tag': 'CST', 'captain': 'Tariq Ali', 'color': 'Neon Green', 'rating': 4.6},
        {'name': 'Phoenix Rising FC', 'tag': 'PHX', 'captain': 'Nitin Verma', 'color': 'Fire Red', 'rating': 4.4},
        {'name': 'Red Devils Turf FC', 'tag': 'RDT', 'captain': 'Daniel Craig', 'color': 'Midnight Black', 'rating': 4.8},
      ];
      for (int i = 0; i < count && i < footballTemplates.length; i++) {
        final t = footballTemplates[i];
        result.add({
          'id': 'football_team_${i + 1}',
          'teamName': t['name'],
          'teamTag': t['tag'],
          'captainName': t['captain'],
          'contactPhone': '+91 98451 22${30 + i}',
          'jerseyColor': t['color'],
          'skillLevel': 'Advanced / Semi-Pro',
          'rating': t['rating'],
          'playersCount': 7,
          'isUserTeam': false,
          'registeredAt': '0${(i % 9) + 1} Jun 2025',
          'players': [
            {'name': t['captain'] as String, 'role': 'Captain (Striker)', 'jersey': '10'},
            {'name': 'Rohan Sen', 'role': 'Midfielder', 'jersey': '8'},
            {'name': 'Aditya Verma', 'role': 'Goalkeeper', 'jersey': '1'},
            {'name': 'Karthik Rao', 'role': 'Defender', 'jersey': '4'},
            {'name': 'Manish K.', 'role': 'Winger', 'jersey': '7'},
            {'name': 'Dev Joshi', 'role': 'Defender', 'jersey': '3'},
            {'name': 'Sameer P.', 'role': 'Forward', 'jersey': '11'},
          ],
        });
      }
    }

    return result;
  }

  static final List<Map<String, dynamic>> initialTournaments = [
    {
      'id': 'tourn_1',
      'name': 'Summer Cup 2025',
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'format': '5v5 Knockout • 16 Teams',
      'formatType': 'Knockout',
      'status': 'Open Entry',
      'statusBadge': 'REGISTRATION OPEN',
      'badgeColor': const Color(0xFF00E5FF),
      'venue': 'Play Arena, Koramangala',
      'area': 'Koramangala',
      'city': 'Bangalore',
      'distanceKm': 1.2,
      'dates': '15 Jun - 20 Jun 2025',
      'prizePool': '₹1,000,000',
      'prizePoolAmount': 1000000,
      'entryFee': 'Free Entry',
      'entryFeeAmount': 0,
      'spotsFilled': 12,
      'totalSpots': 16,
      'isFillingFast': true,
      'isWeekend': true,
      'organizer': 'Bangalore Football League',
      'organizerPhone': '+91 98765 43210',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      'isSpotlight': true,
      'rules': 'Standard FIFA 5v5 rules apply. Shin guards mandatory. 20 min halves.',
      'level': 'Open Category',
      'createdBy': 'You',
      'isCreator': true,
    },
    {
      'id': 'tourn_2',
      'name': 'Bangalore Premier Box League',
      'sport': 'Cricket',
      'sportIcon': Icons.sports_cricket_rounded,
      'accentColor': const Color(0xFFFF9800),
      'format': 'Box Cricket 7v7 • League + Knockout',
      'formatType': 'Box Cricket',
      'status': 'Ongoing (Live)',
      'statusBadge': 'LIVE • DAY 3',
      'badgeColor': const Color(0xFFFF3B30),
      'venue': 'Turf Nation, Electronic City',
      'area': 'Electronic City',
      'city': 'Bangalore',
      'distanceKm': 8.5,
      'dates': '10 May - 18 May 2025',
      'prizePool': '₹500,000',
      'prizePoolAmount': 500000,
      'entryFee': '₹2,500 / team',
      'entryFeeAmount': 2500,
      'spotsFilled': 8,
      'totalSpots': 16,
      'isFillingFast': false,
      'isWeekend': true,
      'organizer': 'Karnataka Turf Cricket Board',
      'organizerPhone': '+91 98450 11223',
      'image': 'https://images.unsplash.com/photo-1531415074868-036b1c57e329?w=800',
      'isSpotlight': false,
      'rules': '8 Overs per side. Box cricket boundaries & direct hit dismissals.',
      'level': 'Open Category',
    },
    {
      'id': 'tourn_3',
      'name': 'Smash Masters Badminton Open',
      'sport': 'Badminton',
      'sportIcon': Icons.sports_tennis_rounded,
      'accentColor': const Color(0xFF10B981),
      'format': 'Men & Mixed Doubles • 32 Pairs',
      'formatType': 'Doubles',
      'status': 'Open Entry',
      'statusBadge': 'FAST FILLING (3 LEFT)',
      'badgeColor': const Color(0xFFFF9800),
      'venue': 'Victory Turf, Bellandur',
      'area': 'Bellandur',
      'city': 'Bangalore',
      'distanceKm': 2.8,
      'dates': '22 May - 25 May 2025',
      'prizePool': '₹150,000',
      'prizePoolAmount': 150000,
      'entryFee': '₹800 / pair',
      'entryFeeAmount': 800,
      'spotsFilled': 6,
      'totalSpots': 16,
      'isFillingFast': true,
      'isWeekend': true,
      'organizer': 'Shuttle Pro Series',
      'organizerPhone': '+91 98112 33445',
      'image': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      'isSpotlight': false,
      'rules': 'Best of 3 sets of 21 points. BWF certified shuttlecocks provided.',
      'level': 'Amateur',
    },
    {
      'id': 'tourn_4',
      'name': 'Metropolitan Hoops 3v3 Shootout',
      'sport': 'Basketball',
      'sportIcon': Icons.sports_basketball_rounded,
      'accentColor': const Color(0xFFF59E0B),
      'format': 'Half Court 3v3 • Double Elimination',
      'formatType': 'Knockout',
      'status': 'Upcoming',
      'statusBadge': 'UPCOMING • 01 JUN',
      'badgeColor': const Color(0xFF10B981),
      'venue': 'Greenfield Arena, HSR Layout',
      'area': 'HSR Layout',
      'city': 'Bangalore',
      'distanceKm': 2.1,
      'dates': '01 Jun - 03 Jun 2025',
      'prizePool': '₹200,000',
      'prizePoolAmount': 200000,
      'entryFee': '₹1,500 / team',
      'entryFeeAmount': 1500,
      'spotsFilled': 8,
      'totalSpots': 16,
      'isFillingFast': false,
      'isWeekend': false,
      'organizer': 'Bangalore Ballers Club',
      'organizerPhone': '+91 99001 22334',
      'image': 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
      'isSpotlight': false,
      'rules': 'FIBA 3x3 rules. 12-second shot clock.',
      'level': 'Open Category',
    },
    {
      'id': 'tourn_5',
      'name': 'Corporate Turf Cup Season 4',
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'format': '7v7 Weekend Corporate League',
      'formatType': 'League + Knockout',
      'status': 'Open Entry',
      'statusBadge': 'EARLY BIRD ENTRY',
      'badgeColor': const Color(0xFF00E5FF),
      'venue': 'Decathlon Arena, Sarjapur',
      'area': 'Sarjapur',
      'city': 'Bangalore',
      'distanceKm': 4.5,
      'dates': '05 Jun - 12 Jun 2025',
      'prizePool': '₹350,000',
      'prizePoolAmount': 350000,
      'entryFee': '₹5,000 / team',
      'entryFeeAmount': 5000,
      'spotsFilled': 8,
      'totalSpots': 16,
      'isFillingFast': true,
      'isWeekend': true,
      'organizer': 'Corporate Sports India',
      'organizerPhone': '+91 97412 88990',
      'image': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
      'isSpotlight': false,
      'rules': 'Corporate ID required for all participating squad players.',
      'level': 'Corporate',
    },
    {
      'id': 'tourn_6',
      'name': 'Koramangala Community Futsal Clash',
      'sport': 'Football',
      'sportIcon': Icons.sports_soccer_rounded,
      'accentColor': const Color(0xFF00E5FF),
      'format': '5v5 Quick Knockout • 12 Teams',
      'formatType': 'Knockout',
      'status': 'Open Entry',
      'statusBadge': 'REGISTRATION OPEN',
      'badgeColor': const Color(0xFF00E5FF),
      'venue': 'Kick Off Arena, Koramangala 5th Block',
      'area': 'Koramangala',
      'city': 'Bangalore',
      'distanceKm': 0.8,
      'dates': '28 May - 29 May 2025',
      'prizePool': '₹75,000',
      'prizePoolAmount': 75000,
      'entryFee': 'Free Entry',
      'entryFeeAmount': 0,
      'spotsFilled': 7,
      'totalSpots': 12,
      'isFillingFast': false,
      'isWeekend': true,
      'organizer': 'Koramangala Sports Circle',
      'organizerPhone': '+91 98860 55443',
      'image': 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?w=800',
      'isSpotlight': false,
      'rules': 'Flat shoes only. Local neighborhood tournament.',
      'level': 'Amateur',
    },
    {
      'id': 'tourn_7',
      'name': 'Indiranagar Box Cricket Rumble',
      'sport': 'Cricket',
      'sportIcon': Icons.sports_cricket_rounded,
      'accentColor': const Color(0xFFFF9800),
      'format': '6v6 Box Cricket • 16 Teams',
      'formatType': 'Box Cricket',
      'status': 'Upcoming',
      'statusBadge': 'UPCOMING • 08 JUN',
      'badgeColor': const Color(0xFF10B981),
      'venue': 'Urban Turf, Indiranagar 100ft Rd',
      'area': 'Indiranagar',
      'city': 'Bangalore',
      'distanceKm': 3.4,
      'dates': '08 Jun - 10 Jun 2025',
      'prizePool': '₹250,000',
      'prizePoolAmount': 250000,
      'entryFee': '₹1,800 / team',
      'entryFeeAmount': 1800,
      'spotsFilled': 6,
      'totalSpots': 16,
      'isFillingFast': false,
      'isWeekend': true,
      'organizer': 'East Bangalore Cricket Union',
      'organizerPhone': '+91 97311 00221',
      'image': 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
      'isSpotlight': false,
      'rules': 'Tennis ball only. Maximum 6 overs per innings.',
      'level': 'Open Category',
    },
    {
      'id': 'tourn_8',
      'name': 'Spring Lawn Tennis Championship',
      'sport': 'Tennis',
      'sportIcon': Icons.sports_baseball_rounded,
      'accentColor': const Color(0xFF8B5CF6),
      'format': 'Men Singles & Doubles Knockout',
      'formatType': 'Knockout',
      'status': 'Completed',
      'statusBadge': 'COMPLETED • RESULTS OUT',
      'badgeColor': const Color(0xFF8E9E94),
      'venue': 'Top Spin Tennis Hub, Whitefield',
      'area': 'Whitefield',
      'city': 'Bangalore',
      'distanceKm': 14.2,
      'dates': '18 Apr - 22 Apr 2025',
      'prizePool': '₹100,000',
      'prizePoolAmount': 100000,
      'entryFee': '₹1,200 / player',
      'entryFeeAmount': 1200,
      'spotsFilled': 8,
      'totalSpots': 16,
      'isFillingFast': false,
      'isWeekend': false,
      'organizer': 'Karnataka Lawn Tennis Assoc.',
      'organizerPhone': '+91 98450 99887',
      'image': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800',
      'isSpotlight': false,
      'rules': 'ITF standard rules. Final winner: Team Baseline Aces.',
      'level': 'Open Category',
    },
  ];
}
