import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:turf_app/core/constants/api_constants.dart';
import 'package:turf_app/core/services/session_manager.dart';

class MatchRepository extends ChangeNotifier {
  static final MatchRepository instance = MatchRepository._internal();

  MatchRepository._internal();

  factory MatchRepository() => instance;

  Dio? _fallbackDio;
  Dio get defaultDio {
    if (_fallbackDio != null) return _fallbackDio!;
    _fallbackDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
    _fallbackDio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isUserRegistration = (options.path.endsWith('/users') ||
                  options.path.endsWith('/users/') ||
                  options.path == '/users/' ||
                  options.path == '/users') &&
              options.method.toUpperCase() == 'POST';

          final isAuthOrPublic = options.path.contains('/auth/') ||
              options.path.contains('check-availability') ||
              isUserRegistration;

          if (!isAuthOrPublic) {
            final token = await SessionManager.ensureBackendToken(dio: _fallbackDio!);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              return handler.next(options);
            }

            final user = firebase_auth.FirebaseAuth.instance.currentUser;
            if (user != null) {
              try {
                final fbToken = await user.getIdToken();
                options.headers['Authorization'] = 'Bearer $fbToken';
              } catch (_) {}
            }
          }

          return handler.next(options);
        },
      ),
    );
    return _fallbackDio!;
  }

  List<Map<String, dynamic>> _allMatches = [];
  List<Map<String, dynamic>> _myMatches = [];

  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  String? _error;

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isWsConnecting = false;

  List<Map<String, dynamic>> get allMatches => List.unmodifiable(_allMatches);
  List<Map<String, dynamic>> get myMatches => List.unmodifiable(_myMatches);

  List<Map<String, dynamic>> get liveMatches =>
      _allMatches.where((m) => (m['status']?.toString().toLowerCase() == 'live')).toList();

  List<Map<String, dynamic>> get upcomingMatches =>
      _allMatches.where((m) => (m['status']?.toString().toLowerCase() == 'scheduled')).toList();

  List<Map<String, dynamic>> get completedMatches =>
      _allMatches.where((m) => (m['status']?.toString().toLowerCase() == 'completed')).toList();

  List<Map<String, dynamic>> get myCreatedMatches =>
      _myMatches.where((m) => m['isCreator'] == true).toList();

  bool get isLoading => _isLoadingAll || _isLoadingMy;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  String? get error => _error;

  // Extract integer backend ID
  static int _extractBackendId(dynamic id) {
    if (id is num) return id.toInt();
    if (id is String) {
      final stripped = id.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(stripped) ?? 0;
    }
    return 0;
  }

  /// Maps a raw backend match JSON to UI friendly format
  static Map<String, dynamic> mapMatchFromBackend(
    Map<String, dynamic> raw, {
    int? currentUserId,
  }) {
    final dynamic rawId = raw['id'];
    final int backendId = (rawId is num) ? rawId.toInt() : (int.tryParse(rawId.toString()) ?? 0);
    final dynamic creatorId = raw['creator_id'];
    final int? creatorIdInt = (creatorId is num) ? creatorId.toInt() : int.tryParse(creatorId?.toString() ?? '');

    final bool isCreator = (currentUserId != null && creatorIdInt != null && creatorIdInt == currentUserId);

    final String sport = raw['sport_type']?.toString() ?? 'Football';
    final String format = raw['format']?.toString() ?? '5v5';
    final String title = raw['title']?.toString() ?? '${raw['team_a_name'] ?? 'Team A'} vs ${raw['team_b_name'] ?? 'Team B'}';
    final String venue = raw['venue_name']?.toString() ?? 'Play Arena';
    final String location = raw['location']?.toString() ?? 'Sarjapur Road, Bangalore';
    final String status = raw['status']?.toString() ?? 'scheduled';

    final int scoreA = (raw['team_a_score'] is num) ? (raw['team_a_score'] as num).toInt() : 0;
    final int scoreB = (raw['team_b_score'] is num) ? (raw['team_b_score'] as num).toInt() : 0;

    final String teamA = raw['team_a_name']?.toString() ?? 'Team Alpha';
    final String teamB = raw['team_b_name']?.toString() ?? 'Team Beta';

    final String teamAColor = raw['team_a_color']?.toString() ?? 'Neon Green';
    final String teamBColor = raw['team_b_color']?.toString() ?? 'Royal Blue';

    final int maxPlayers = (raw['max_players'] is num) ? (raw['max_players'] as num).toInt() : 10;
    final int currentPlayers = (raw['current_players_count'] is num) ? (raw['current_players_count'] as num).toInt() : 1;
    final double pricePerPlayer = (raw['price_per_player'] is num) ? (raw['price_per_player'] as num).toDouble() : 0.0;
    final String skillLevel = raw['skill_level']?.toString() ?? 'Intermediate';

    final String? matchDate = raw['match_date']?.toString();
    final String? matchTime = raw['match_time']?.toString();
    final int duration = (raw['duration_minutes'] is num) ? (raw['duration_minutes'] as num).toInt() : 60;

    // Parse participants
    List<Map<String, dynamic>> participants = [];
    bool hasJoined = false;
    String? userTeam;

    if (raw['participants'] is List) {
      participants = (raw['participants'] as List).map((p) {
        final pMap = Map<String, dynamic>.from(p as Map);
        final pUserId = (pMap['user_id'] is num) ? (pMap['user_id'] as num).toInt() : null;
        if (currentUserId != null && pUserId == currentUserId) {
          hasJoined = true;
          userTeam = pMap['team']?.toString();
        }
        return {
          'id': pMap['id'],
          'matchId': pMap['match_id'],
          'userId': pUserId,
          'team': pMap['team']?.toString() ?? 'A',
          'playerName': pMap['player_name']?.toString() ?? 'Player',
          'playerRole': pMap['player_role']?.toString() ?? 'Player',
          'jerseyNumber': pMap['jersey_number']?.toString() ?? '',
          'joinedAt': pMap['joined_at']?.toString(),
        };
      }).toList();
    }

    // Parse timeline events
    List<Map<String, dynamic>> timelineEvents = [];
    if (raw['timeline_events_json'] != null) {
      try {
        final decoded = jsonDecode(raw['timeline_events_json'].toString());
        if (decoded is List) {
          timelineEvents = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }

    // Parse scoreboard configuration
    Map<String, dynamic> scoreboardConfig = {};
    if (raw['scoreboard_state_json'] != null) {
      try {
        final decoded = jsonDecode(raw['scoreboard_state_json'].toString());
        if (decoded is Map) {
          scoreboardConfig = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    if (scoreboardConfig.isEmpty) {
      scoreboardConfig = {
        'sport': sport.toLowerCase(),
        'turfName': venue,
        'teamA': teamA,
        'teamB': teamB,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'isCompleted': status.toLowerCase() == 'completed',
        'isLive': status.toLowerCase() == 'live',
      };
    }

    final String? mvp = raw['mvp_player_name']?.toString();
    final String? mvpNotes = raw['mvp_notes']?.toString();

    // Map sport icon
    IconData sportIcon = Icons.sports_soccer_rounded;
    Color accentColor = const Color(0xFF00E676);
    final sportLower = sport.toLowerCase();
    if (sportLower.contains('cricket')) {
      sportIcon = Icons.sports_cricket_rounded;
      accentColor = const Color(0xFFFF9800);
    } else if (sportLower.contains('badminton')) {
      sportIcon = Icons.sports_tennis_rounded;
      accentColor = const Color(0xFF29B6F6);
    } else if (sportLower.contains('basketball')) {
      sportIcon = Icons.sports_basketball_rounded;
      accentColor = const Color(0xFFFF5722);
    } else if (sportLower.contains('tennis')) {
      sportIcon = Icons.sports_tennis_rounded;
      accentColor = const Color(0xFFE91E63);
    }

    return {
      'id': backendId,
      'backendId': backendId,
      'creatorId': creatorIdInt,
      'isCreator': isCreator,
      'hasJoined': hasJoined,
      'userTeam': userTeam,
      'title': title,
      'turfName': venue,
      'location': location,
      'sport': sport,
      'sportIcon': sportIcon,
      'accentColor': accentColor,
      'format': format,
      'teamA': teamA,
      'teamB': teamB,
      'teamAColor': teamAColor,
      'teamBColor': teamBColor,
      'scoreA': scoreA.toString(),
      'scoreB': scoreB.toString(),
      'scoreDisplay': '$scoreA - $scoreB',
      'status': status,
      'isLive': status.toLowerCase() == 'live',
      'isCompleted': status.toLowerCase() == 'completed',
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'pricePerPlayer': pricePerPlayer,
      'skillLevel': skillLevel,
      'matchDate': matchDate ?? 'Today',
      'matchTime': matchTime ?? 'Now',
      'duration': duration,
      'date': (matchDate != null && matchTime != null) ? '$matchDate • $matchTime' : 'Upcoming',
      'mvp': mvp,
      'mvpNotes': mvpNotes,
      'result': status.toLowerCase() == 'completed'
          ? (scoreA > scoreB ? '$teamA WON' : (scoreB > scoreA ? '$teamB WON' : 'DRAW'))
          : status.toUpperCase(),
      'resultColor': status.toLowerCase() == 'completed'
          ? const Color(0xFF00E676)
          : (status.toLowerCase() == 'live' ? const Color(0xFFFF5252) : const Color(0xFF29B6F6)),
      'participants': participants,
      'timelineEvents': timelineEvents,
      'scoreboardConfig': scoreboardConfig,
    };
  }

  /// Fetch all matches with optional filters
  Future<List<Map<String, dynamic>>> fetchMatches({
    Dio? dio,
    String? sport,
    String? status,
    String? search,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      _isLoadingAll = true;
      _error = null;
      notifyListeners();

      final Map<String, dynamic> query = {};
      if (sport != null && sport != 'All') query['sport_type'] = sport;
      if (status != null && status != 'All') query['status'] = status.toLowerCase();
      if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();

      final res = await client.get('/matches/', queryParameters: query);
      if (res.data is List) {
        _allMatches = (res.data as List)
            .map((item) => mapMatchFromBackend(item as Map<String, dynamic>, currentUserId: currentUserId))
            .toList();
      } else {
        _allMatches = [];
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error fetching matches: $e');
      _error = e.toString();
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
    return _allMatches;
  }

  /// Fetch matches created or joined by the authenticated user
  Future<List<Map<String, dynamic>>> fetchMyMatches({
    Dio? dio,
    String? tab = 'all',
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      _isLoadingMy = true;
      _error = null;
      notifyListeners();

      final res = await client.get('/matches/my', queryParameters: {'tab': tab ?? 'all'});
      if (res.data is List) {
        _myMatches = (res.data as List)
            .map((item) => mapMatchFromBackend(item as Map<String, dynamic>, currentUserId: currentUserId))
            .toList();
      } else {
        _myMatches = [];
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error fetching my matches: $e');
      _error = e.toString();
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
    return _myMatches;
  }

  /// Fetch single match details
  Future<Map<String, dynamic>?> fetchMatchDetails(
    dynamic matchId, {
    Dio? dio,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.get('/matches/$backendId');
      if (res.data is Map) {
        final mapped = mapMatchFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _updateLocalCache(mapped);
        return mapped;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error fetching match details: $e');
    }
    return getMatchById(matchId);
  }

  /// Create a match
  Future<Map<String, dynamic>?> createMatch(
    Map<String, dynamic> payload, {
    Dio? dio,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final res = await client.post('/matches/', data: payload);
      if (res.data is Map) {
        final mapped = mapMatchFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _allMatches.insert(0, mapped);
        _myMatches.insert(0, mapped);
        notifyListeners();
        return mapped;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error creating match: $e');
      rethrow;
    }
    return null;
  }

  /// Update match details (creator only)
  Future<Map<String, dynamic>?> updateMatch(
    dynamic matchId,
    Map<String, dynamic> payload, {
    Dio? dio,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.put('/matches/$backendId', data: payload);
      if (res.data is Map) {
        final mapped = mapMatchFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _updateLocalCache(mapped);
        return mapped;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error updating match: $e');
      rethrow;
    }
    return null;
  }

  /// Delete match (creator only)
  Future<bool> deleteMatch(
    dynamic matchId, {
    Dio? dio,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.delete('/matches/$backendId');
      if (res.statusCode == 200) {
        _allMatches.removeWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
        _myMatches.removeWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error deleting match: $e');
      rethrow;
    }
    return false;
  }

  /// Join match as participant
  Future<bool> joinMatch(
    dynamic matchId, {
    Dio? dio,
    required String team,
    String? playerName,
    String? playerRole,
    String? jerseyNumber,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.post(
        '/matches/$backendId/join',
        data: {
          'team': team.toUpperCase(),
          'player_name': playerName,
          'player_role': playerRole,
          'jersey_number': jerseyNumber,
        },
      );
      if (res.statusCode == 200) {
        await fetchMatchDetails(backendId, dio: client, currentUserId: currentUserId);
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error joining match: $e');
      rethrow;
    }
    return false;
  }

  /// Leave match
  Future<bool> leaveMatch(
    dynamic matchId, {
    Dio? dio,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.post('/matches/$backendId/leave');
      if (res.statusCode == 200) {
        await fetchMatchDetails(backendId, dio: client, currentUserId: currentUserId);
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error leaving match: $e');
      rethrow;
    }
    return false;
  }

  /// Update live score
  Future<bool> updateScore(
    dynamic matchId, {
    Dio? dio,
    int? scoreA,
    int? scoreB,
    String? status,
    String? scoreboardStateJson,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final Map<String, dynamic> data = {};
      if (scoreA != null) data['team_a_score'] = scoreA;
      if (scoreB != null) data['team_b_score'] = scoreB;
      if (status != null) data['status'] = status;
      if (scoreboardStateJson != null) data['scoreboard_state_json'] = scoreboardStateJson;

      final res = await client.put('/matches/$backendId/score', data: data);
      if (res.statusCode == 200 && res.data is Map) {
        final mapped = mapMatchFromBackend(res.data as Map<String, dynamic>, currentUserId: currentUserId);
        _updateLocalCache(mapped);
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error updating score: $e');
      rethrow;
    }
    return false;
  }

  /// Add a timeline event (goal, card, wicket, point, etc.)
  Future<bool> addTimelineEvent(
    dynamic matchId, {
    Dio? dio,
    required String eventType,
    String? minute,
    String? team,
    String? playerName,
    String? description,
    String? scoreSnapshot,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.post(
        '/matches/$backendId/timeline',
        data: {
          'event_type': eventType,
          'minute': minute,
          'team': team,
          'player_name': playerName,
          'description': description,
          'score_snapshot': scoreSnapshot,
        },
      );
      if (res.statusCode == 200) {
        await fetchMatchDetails(backendId, dio: client, currentUserId: currentUserId);
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error adding timeline event: $e');
      rethrow;
    }
    return false;
  }

  /// Conclude match and set MVP
  Future<bool> finishMatch(
    dynamic matchId, {
    Dio? dio,
    String? mvpPlayerName,
    String? mvpNotes,
    int? finalScoreA,
    int? finalScoreB,
    int? currentUserId,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.put(
        '/matches/$backendId/finish',
        data: {
          'mvp_player_name': mvpPlayerName,
          'mvp_notes': mvpNotes,
          'final_team_a_score': finalScoreA,
          'final_team_b_score': finalScoreB,
        },
      );
      if (res.statusCode == 200 && res.data is Map) {
        final mapped = mapMatchFromBackend(res.data as Map<String, dynamic>, currentUserId: currentUserId);
        _updateLocalCache(mapped);
        return true;
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error concluding match: $e');
      rethrow;
    }
    return false;
  }

  /// Fetch dynamic match statistics
  Future<Map<String, dynamic>?> fetchMatchStats(
    dynamic matchId, {
    Dio? dio,
  }) async {
    final client = dio ?? defaultDio;
    try {
      final backendId = _extractBackendId(matchId);
      final res = await client.get('/matches/$backendId/stats');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[MATCH REPO] Error fetching match stats: $e');
    }
    return null;
  }

  /// Helper to lookup match by ID
  Map<String, dynamic>? getMatchById(dynamic matchId) {
    final backendId = _extractBackendId(matchId);
    try {
      return _allMatches.firstWhere(
        (m) => m['backendId'] == backendId || m['id'] == backendId,
      );
    } catch (_) {
      try {
        return _myMatches.firstWhere(
          (m) => m['backendId'] == backendId || m['id'] == backendId,
        );
      } catch (_) {
        return null;
      }
    }
  }

  void _updateLocalCache(Map<String, dynamic> match) {
    final backendId = match['backendId'];
    final idxAll = _allMatches.indexWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
    if (idxAll >= 0) {
      _allMatches[idxAll] = match;
    } else {
      _allMatches.insert(0, match);
    }

    if (match['isCreator'] == true || match['hasJoined'] == true) {
      final idxMy = _myMatches.indexWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
      if (idxMy >= 0) {
        _myMatches[idxMy] = match;
      } else {
        _myMatches.insert(0, match);
      }
    }
    notifyListeners();
  }

  /// Connect to WebSocket channel for live score and roster synchronization
  void connectScoreboardWebSocket({int? currentUserId}) {
    if (_wsChannel != null || _isWsConnecting) return;
    _isWsConnecting = true;

    try {
      final wsUrl = Uri.parse('${ApiConstants.baseWsUrl}/scoreboard');
      debugPrint('[MATCH WS] Connecting to $wsUrl ...');
      _wsChannel = WebSocketChannel.connect(wsUrl);

      _wsSubscription = _wsChannel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            if (data is Map<String, dynamic>) {
              handleRealtimeEvent(data, currentUserId: currentUserId);
            }
          } catch (e) {
            debugPrint('[MATCH WS] Error parsing message: $e');
          }
        },
        onError: (err) {
          debugPrint('[MATCH WS] Connection error: $err');
          _reconnectWs(currentUserId: currentUserId);
        },
        onDone: () {
          debugPrint('[MATCH WS] Connection closed.');
          _reconnectWs(currentUserId: currentUserId);
        },
      );
    } catch (e) {
      debugPrint('[MATCH WS] Could not connect: $e');
    } finally {
      _isWsConnecting = false;
    }
  }

  void _reconnectWs({int? currentUserId}) {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel = null;
    Future.delayed(const Duration(seconds: 4), () {
      connectScoreboardWebSocket(currentUserId: currentUserId);
    });
  }

  /// Handle inbound real-time events from WebSocket
  void handleRealtimeEvent(Map<String, dynamic> event, {int? currentUserId}) {
    final type = event['type']?.toString();
    debugPrint('[MATCH WS] Received event: $type => $event');

    if (type == 'score_update') {
      final matchId = event['match_id'];
      if (matchId != null) {
        final existing = getMatchById(matchId);
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          if (event['team_a_score'] != null) {
            copy['scoreA'] = event['team_a_score'].toString();
          }
          if (event['team_b_score'] != null) {
            copy['scoreB'] = event['team_b_score'].toString();
          }
          copy['scoreDisplay'] = '${copy['scoreA']} - ${copy['scoreB']}';
          if (event['status'] != null) {
            copy['status'] = event['status'];
            copy['isLive'] = event['status'] == 'live';
            copy['isCompleted'] = event['status'] == 'completed';
          }
          if (event['scoreboard_state_json'] != null) {
            try {
              final decoded = jsonDecode(event['scoreboard_state_json'].toString());
              if (decoded is Map) copy['scoreboardConfig'] = Map<String, dynamic>.from(decoded);
            } catch (_) {}
          }
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'participant_joined') {
      final matchId = event['match_id'];
      if (matchId != null) {
        final existing = getMatchById(matchId);
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          if (event['current_players_count'] != null) {
            copy['currentPlayers'] = event['current_players_count'];
          }
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'match_completed') {
      final matchId = event['match_id'];
      if (matchId != null) {
        final existing = getMatchById(matchId);
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          copy['status'] = 'completed';
          copy['isLive'] = false;
          copy['isCompleted'] = true;
          if (event['mvp_player_name'] != null) {
            copy['mvp'] = event['mvp_player_name'];
          }
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'match_deleted') {
      final matchId = event['match_id'];
      if (matchId != null) {
        final backendId = _extractBackendId(matchId);
        _allMatches.removeWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
        _myMatches.removeWhere((m) => m['backendId'] == backendId || m['id'] == backendId);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }
}
