import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TournamentRepository extends ChangeNotifier {
  static final TournamentRepository instance = TournamentRepository._internal();

  TournamentRepository._internal();

  factory TournamentRepository() => instance;

  List<Map<String, dynamic>> _allTournaments = [];
  List<Map<String, dynamic>> _myTournaments = [];

  bool _isLoadingAll = false;
  bool _isLoadingMy = false;
  String? _error;

  List<Map<String, dynamic>> get tournaments => List.unmodifiable(_allTournaments);
  List<Map<String, dynamic>> get myTournaments => List.unmodifiable(_myTournaments);

  bool get isLoading => _isLoadingAll || _isLoadingMy;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  String? get error => _error;

  /// Month name helper
  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  /// Maps a backend raw JSON tournament map to UI format
  static Map<String, dynamic> mapTournamentFromBackend(
    Map<String, dynamic> raw, {
    int? currentUserId,
  }) {
    final dynamic rawId = raw['id'];
    final int backendId = (rawId is num) ? rawId.toInt() : (int.tryParse(rawId.toString()) ?? 0);
    final dynamic creatorId = raw['creator_id'];
    final int? creatorIdInt = (creatorId is num) ? creatorId.toInt() : int.tryParse(creatorId?.toString() ?? '');

    final bool isCreator = (currentUserId != null && creatorIdInt != null && creatorIdInt == currentUserId);

    final num prizePoolNum = (raw['prize_pool'] is num) ? (raw['prize_pool'] as num) : 0;
    final num entryFeeNum = (raw['entry_fee'] is num) ? (raw['entry_fee'] as num) : 0;
    final int totalTeams = (raw['total_teams'] is num) ? (raw['total_teams'] as num).toInt() : 16;
    final int spotsFilled = (raw['registered_teams_count'] is num) ? (raw['registered_teams_count'] as num).toInt() : 0;

    final String title = raw['title']?.toString() ?? 'Tournament Championship';
    final String sport = raw['sport']?.toString() ?? 'Football';
    final String format = raw['format']?.toString() ?? '5v5 Knockout';
    final String venue = raw['venue']?.toString() ?? 'Play Arena';
    final String area = raw['area']?.toString() ?? 'Koramangala';
    final String city = raw['city']?.toString() ?? 'Bangalore';
    final String status = raw['status']?.toString() ?? 'Open Entry';

    String dateStr = 'Coming Soon';
    if (raw['start_date'] != null) {
      try {
        final dt = DateTime.parse(raw['start_date'].toString());
        dateStr = '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}';
      } catch (_) {
        dateStr = raw['start_date'].toString();
      }
    }

    // Parse registered teams
    List<Map<String, dynamic>> registeredTeams = [];
    if (raw['registrations'] is List) {
      registeredTeams = (raw['registrations'] as List).map((r) {
        final regMap = Map<String, dynamic>.from(r as Map);
        List<dynamic> players = [];
        if (regMap['players_json'] != null) {
          try {
            players = jsonDecode(regMap['players_json'].toString());
          } catch (_) {}
        }
        final regUserId = (regMap['user_id'] is num) ? (regMap['user_id'] as num).toInt() : null;
        final bool isUserTeam = (currentUserId != null && regUserId == currentUserId);

        return {
          'id': regMap['id'],
          'backendId': regMap['id'],
          'tournamentId': regMap['tournament_id'],
          'teamName': regMap['team_name']?.toString() ?? 'Team',
          'teamTag': regMap['team_tag']?.toString() ?? 'TM',
          'captainName': regMap['captain_name']?.toString() ?? 'Captain',
          'contactPhone': regMap['contact_phone']?.toString() ?? '',
          'contactEmail': regMap['contact_email']?.toString() ?? '',
          'jerseyColor': regMap['jersey_color']?.toString() ?? 'Neon Green',
          'skillLevel': regMap['skill_level']?.toString() ?? 'Intermediate / Club',
          'status': regMap['status']?.toString() ?? 'Approved',
          'playersCount': (regMap['players_count'] is num) ? (regMap['players_count'] as num).toInt() : 1,
          'players': players,
          'isUserTeam': isUserTeam,
          'userId': regUserId,
        };
      }).toList();
    }

    // Parse matches / fixtures
    List<Map<String, dynamic>> fixtures = [];
    if (raw['matches'] is List) {
      fixtures = (raw['matches'] as List).map((m) {
        final mMap = Map<String, dynamic>.from(m as Map);
        return {
          'id': mMap['id'],
          'backendId': mMap['id'],
          'matchNumber': (mMap['match_number'] is num) ? (mMap['match_number'] as num).toInt() : 1,
          'round': (mMap['round'] is num) ? (mMap['round'] as num).toInt() : 1,
          'stage': mMap['stage']?.toString() ?? 'Match',
          'stageGroup': mMap['stage_group']?.toString() ?? 'Knockout',
          't1': mMap['team_a_name']?.toString() ?? 'Team A',
          't2': mMap['team_b_name']?.toString() ?? 'Team B',
          't1Score': (mMap['team_a_score'] is num) ? (mMap['team_a_score'] as num).toInt() : 0,
          't2Score': (mMap['team_b_score'] is num) ? (mMap['team_b_score'] as num).toInt() : 0,
          'winnerName': mMap['winner_name']?.toString(),
          'status': mMap['status']?.toString() ?? 'scheduled',
          'time': mMap['scheduled_time']?.toString() ?? 'Day 1 • 05:00 PM',
          'venue': mMap['venue_pitch']?.toString() ?? '$venue • Center Pitch',
          'pitch': mMap['venue_pitch']?.toString() ?? 'Center Pitch',
          'notes': mMap['notes']?.toString() ?? '',
        };
      }).toList();
    }

    final bool isRegisteredByYou = registeredTeams.any((t) => t['isUserTeam'] == true);

    return {
      'id': 'tourn_$backendId',
      'backendId': backendId,
      'dbId': backendId,
      'name': title,
      'title': title,
      'description': raw['description']?.toString() ?? '',
      'sport': sport,
      'format': format,
      'formatType': format,
      'level': raw['level']?.toString() ?? 'Open Category',
      'venue': venue,
      'area': area,
      'city': city,
      'distanceKm': 2.0,
      'dates': dateStr,
      'startDate': raw['start_date'],
      'endDate': raw['end_date'],
      'prizePool': '₹${NumberFormat('#,##,###').format(prizePoolNum.toInt())}',
      'prizePoolAmount': prizePoolNum,
      'entryFee': entryFeeNum == 0 ? 'Free Entry' : '₹${NumberFormat('#,##,###').format(entryFeeNum.toInt())} / team',
      'entryFeeAmount': entryFeeNum,
      'totalSpots': totalTeams,
      'spotsFilled': spotsFilled,
      'status': status,
      'statusBadge': status.toUpperCase(),
      'organizer': raw['organizer_name']?.toString() ?? 'Tournament Organizer',
      'organizerPhone': raw['contact_phone']?.toString() ?? '+91 98765 43210',
      'image': raw['banner_image']?.toString() ??
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      'rules': raw['rules']?.toString() ?? 'Standard tournament rules apply.',
      'creatorId': creatorIdInt,
      'creator_id': creatorIdInt,
      'isCreator': isCreator,
      'createdBy': isCreator ? 'You' : (raw['organizer_name']?.toString() ?? 'Organizer'),
      'fixturesGenerated': raw['fixtures_generated'] == true || fixtures.isNotEmpty,
      'registeredTeams': registeredTeams,
      'fixtures': fixtures,
      'isRegisteredByYou': isRegisteredByYou,
    };
  }

  /// Fetch all published tournaments from backend
  Future<void> syncWithBackend(Dio dio, {int? currentUserId}) async {
    await fetchAllTournaments(dio, currentUserId: currentUserId);
  }

  /// Fetch all tournaments
  Future<void> fetchAllTournaments(Dio dio, {int? currentUserId}) async {
    try {
      _isLoadingAll = true;
      _error = null;
      notifyListeners();

      final res = await dio.get('/tournaments/');
      final data = res.data;
      if (data is List) {
        _allTournaments = data
            .map((item) => mapTournamentFromBackend(item as Map<String, dynamic>, currentUserId: currentUserId))
            .toList();
      } else {
        _allTournaments = [];
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error fetching all tournaments: $e');
      _error = e.toString();
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  /// Fetch dedicated creator tournaments (/tournaments/my)
  Future<void> fetchMyTournaments(Dio dio, {int? currentUserId}) async {
    try {
      _isLoadingMy = true;
      _error = null;
      notifyListeners();

      final res = await dio.get('/tournaments/my');
      final data = res.data;
      if (data is List) {
        _myTournaments = data
            .map((item) => mapTournamentFromBackend(item as Map<String, dynamic>, currentUserId: currentUserId))
            .toList();
      } else {
        _myTournaments = [];
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error fetching my tournaments: $e');
      _error = e.toString();
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
  }

  /// Fetch single tournament by ID (with registrations and matches)
  Future<Map<String, dynamic>?> fetchTournamentDetails(
    Dio dio,
    dynamic tournamentId, {
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      final res = await dio.get('/tournaments/$backendId');
      if (res.data is Map) {
        final mapped = mapTournamentFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _updateLocalCache(mapped);
        return mapped;
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error fetching tournament details: $e');
    }
    return getTournamentById(tournamentId?.toString());
  }

  /// Create tournament with persistent backend storage
  Future<Map<String, dynamic>?> createTournament(
    Dio dio,
    Map<String, dynamic> tournamentData, {
    int? currentUserId,
  }) async {
    try {
      final res = await dio.post('/tournaments/', data: tournamentData);
      if (res.data is Map) {
        final mapped = mapTournamentFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _allTournaments.insert(0, mapped);
        _myTournaments.insert(0, mapped);
        notifyListeners();
        return mapped;
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error creating tournament: $e');
      rethrow;
    }
    return null;
  }

  /// Update tournament (creator only)
  Future<Map<String, dynamic>?> updateTournamentOnBackend(
    Dio dio,
    dynamic tournamentId,
    Map<String, dynamic> updates, {
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      final res = await dio.put('/tournaments/$backendId', data: updates);
      if (res.data is Map) {
        final mapped = mapTournamentFromBackend(
          res.data as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
        _updateLocalCache(mapped);
        return mapped;
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error updating tournament: $e');
      rethrow;
    }
    return null;
  }

  /// Delete or cancel tournament (creator only)
  Future<bool> deleteOrCancelTournament(Dio dio, dynamic tournamentId) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      await dio.delete('/tournaments/$backendId');
      final idStr = 'tourn_$backendId';
      _allTournaments.removeWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
      _myTournaments.removeWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error deleting tournament: $e');
      rethrow;
    }
  }

  /// Register team for tournament
  Future<Map<String, dynamic>?> registerTeamForTournamentBackend(
    Dio dio,
    dynamic tournamentId,
    Map<String, dynamic> registrationData, {
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      final payload = {
        'team_name': registrationData['team_name'] ?? registrationData['teamName'],
        'team_tag': registrationData['team_tag'] ?? registrationData['teamTag'],
        'captain_name': registrationData['captain_name'] ?? registrationData['captainName'] ?? 'Captain',
        'contact_phone': registrationData['contact_phone'] ?? registrationData['contactPhone'] ?? '+91 98765 43210',
        'contact_email': registrationData['contact_email'] ?? registrationData['contactEmail'],
        'emergency_contact': registrationData['emergency_contact'] ?? registrationData['emergencyContact'],
        'jersey_color': registrationData['jersey_color'] ?? registrationData['jerseyColor'] ?? 'Neon Green',
        'skill_level': registrationData['skill_level'] ?? registrationData['skillLevel'] ?? 'Intermediate / Club',
        'players': registrationData['players'] ?? [],
        'special_requests': registrationData['special_requests'] ?? registrationData['specialRequests'] ?? (registrationData['options'] is Map ? registrationData['options']['specialNotes'] : null),
      };
      final res = await dio.post('/tournaments/$backendId/register', data: payload);
      if (res.data is Map) {
        // Refresh full tournament details to get updated team counts and registrations
        final details = await fetchTournamentDetails(dio, backendId, currentUserId: currentUserId);
        // Refresh user's booked / created tournaments list
        await fetchMyTournaments(dio, currentUserId: currentUserId);
        return details;
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error registering team: $e');
      rethrow;
    }
    return null;
  }

  /// Cancel team registration
  Future<bool> cancelRegistrationOnBackend(
    Dio dio,
    dynamic tournamentId,
    dynamic registrationId, {
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      await dio.delete('/tournaments/$backendId/registrations/$registrationId');
      await fetchTournamentDetails(dio, backendId, currentUserId: currentUserId);
      return true;
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error cancelling registration: $e');
      rethrow;
    }
  }

  /// Approve or reject team registration (creator only)
  Future<bool> updateRegistrationStatusOnBackend(
    Dio dio,
    dynamic tournamentId,
    dynamic registrationId,
    String newStatus, {
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      await dio.put('/tournaments/$backendId/registrations/$registrationId/status', data: {
        'status': newStatus,
      });
      await fetchTournamentDetails(dio, backendId, currentUserId: currentUserId);
      return true;
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error updating registration status: $e');
      rethrow;
    }
  }

  /// Generate fixtures from actual approved database teams (creator only)
  Future<List<Map<String, dynamic>>> generateFixturesOnBackend(
    Dio dio,
    dynamic tournamentId, {
    String strategy = 'balanced',
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      final res = await dio.post('/tournaments/$backendId/fixtures/generate', data: {
        'strategy': strategy,
      });
      if (res.data is List) {
        // Refresh full tournament details
        await fetchTournamentDetails(dio, backendId, currentUserId: currentUserId);
        final tourn = getTournamentById('tourn_$backendId') ?? getTournamentById(backendId.toString());
        return List<Map<String, dynamic>>.from(tourn?['fixtures'] ?? []);
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error generating fixtures: $e');
      rethrow;
    }
    return [];
  }

  /// Update match score and automatically advance knockout winners (creator only)
  Future<Map<String, dynamic>?> updateMatchScoreOnBackend(
    Dio dio,
    dynamic tournamentId,
    dynamic matchId, {
    required int teamAScore,
    required int teamBScore,
    String? winnerName,
    String status = 'completed',
    int? currentUserId,
  }) async {
    try {
      final backendId = _extractBackendId(tournamentId);
      final res = await dio.put('/tournaments/$backendId/matches/$matchId/score', data: {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'status': status,
        'winner_name': winnerName,
      });
      if (res.data is Map) {
        // Refresh tournament details to sync brackets
        await fetchTournamentDetails(dio, backendId, currentUserId: currentUserId);
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[TOURNAMENT REPO] Error updating match score: $e');
      rethrow;
    }
    return null;
  }

  /// Find tournament by ID in memory
  Map<String, dynamic>? getTournamentById(String? tournamentId) {
    if (tournamentId == null) return null;
    final backendId = _extractBackendId(tournamentId);
    final idStr = 'tourn_$backendId';

    final foundAll = _allTournaments.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['id'] == idStr || t?['backendId'] == backendId || t?['id'] == tournamentId,
          orElse: () => null,
        );
    if (foundAll != null) return foundAll;

    return _myTournaments.cast<Map<String, dynamic>?>().firstWhere(
          (t) => t?['id'] == idStr || t?['backendId'] == backendId || t?['id'] == tournamentId,
          orElse: () => null,
        );
  }

  /// Update or add a tournament in local cache
  void _updateLocalCache(Map<String, dynamic> tournament) {
    final backendId = tournament['backendId'];
    final idStr = tournament['id'];

    final idxAll = _allTournaments.indexWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
    if (idxAll != -1) {
      _allTournaments[idxAll] = tournament;
    } else {
      _allTournaments.insert(0, tournament);
    }

    if (tournament['isCreator'] == true) {
      final idxMy = _myTournaments.indexWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
      if (idxMy != -1) {
        _myTournaments[idxMy] = tournament;
      } else {
        _myTournaments.insert(0, tournament);
      }
    }
    notifyListeners();
  }

  /// Real-time event handler
  void handleRealtimeEvent(Map<String, dynamic> event, {int? currentUserId}) {
    final type = event['type']?.toString();
    debugPrint('[TOURNAMENT WS] Event received: $type => $event');

    if (type == 'tournament_created') {
      final tData = event['tournament'] as Map<String, dynamic>?;
      if (tData != null) {
        final mapped = mapTournamentFromBackend(tData, currentUserId: currentUserId);
        _updateLocalCache(mapped);
      }
    } else if (type == 'tournament_updated') {
      final tournId = event['tournament_id'];
      if (tournId != null) {
        final existing = getTournamentById(tournId.toString());
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          if (event['title'] != null) copy['name'] = event['title'];
          if (event['status'] != null) {
            copy['status'] = event['status'];
            copy['statusBadge'] = event['status'].toString().toUpperCase();
          }
          if (event['prize_pool'] != null) {
            final num val = event['prize_pool'];
            copy['prizePool'] = '₹${NumberFormat('#,##,###').format(val.toInt())}';
            copy['prizePoolAmount'] = val;
          }
          if (event['venue'] != null) copy['venue'] = event['venue'];
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'tournament_deleted') {
      final tournId = event['tournament_id'];
      final status = event['status']?.toString();
      if (tournId != null) {
        final backendId = _extractBackendId(tournId);
        final idStr = 'tourn_$backendId';
        if (status == 'Cancelled') {
          final existing = getTournamentById(tournId.toString());
          if (existing != null) {
            final copy = Map<String, dynamic>.from(existing);
            copy['status'] = 'Cancelled';
            copy['statusBadge'] = 'CANCELLED';
            _updateLocalCache(copy);
          }
        } else {
          _allTournaments.removeWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
          _myTournaments.removeWhere((t) => t['backendId'] == backendId || t['id'] == idStr);
          notifyListeners();
        }
      }
    } else if (type == 'tournament_registered') {
      final tournId = event['tournament_id'];
      final count = event['registered_teams_count'];
      if (tournId != null) {
        final existing = getTournamentById(tournId.toString());
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          if (count is num) {
            copy['spotsFilled'] = count.toInt();
          } else {
            copy['spotsFilled'] = (copy['spotsFilled'] as num? ?? 0).toInt() + 1;
          }
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'tournament_registration_cancelled' || type == 'tournament_registration_status_changed') {
      final tournId = event['tournament_id'];
      final count = event['registered_teams_count'];
      if (tournId != null) {
        final existing = getTournamentById(tournId.toString());
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          if (count is num) {
            copy['spotsFilled'] = count.toInt();
          }
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'tournament_fixtures_generated') {
      final tournId = event['tournament_id'];
      if (tournId != null) {
        final existing = getTournamentById(tournId.toString());
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          copy['fixturesGenerated'] = true;
          _updateLocalCache(copy);
        }
      }
    } else if (type == 'tournament_score_updated') {
      final tournId = event['tournament_id'];
      final matchId = event['match_id'];
      if (tournId != null && matchId != null) {
        final existing = getTournamentById(tournId.toString());
        if (existing != null) {
          final copy = Map<String, dynamic>.from(existing);
          final fixtures = List<Map<String, dynamic>>.from(copy['fixtures'] ?? []);
          final mIdx = fixtures.indexWhere((m) => m['backendId'] == matchId || m['id'] == matchId);
          if (mIdx != -1) {
            final mCopy = Map<String, dynamic>.from(fixtures[mIdx]);
            mCopy['t1Score'] = event['team_a_score'] ?? mCopy['t1Score'];
            mCopy['t2Score'] = event['team_b_score'] ?? mCopy['t2Score'];
            mCopy['status'] = event['status'] ?? mCopy['status'];
            mCopy['winnerName'] = event['winner_name'] ?? mCopy['winnerName'];
            fixtures[mIdx] = mCopy;
            copy['fixtures'] = fixtures;
          }
          if (event['tournament_status'] != null) {
            copy['status'] = event['tournament_status'];
            copy['statusBadge'] = event['tournament_status'].toString().toUpperCase();
          }
          _updateLocalCache(copy);
        }
      }
    }
  }

  static int _extractBackendId(dynamic id) {
    if (id is int) return id;
    if (id is num) return id.toInt();
    final str = id.toString();
    final digits = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  // Deprecated backward compatibility methods
  void addTournament(Map<String, dynamic> tournament) {
    _updateLocalCache(tournament);
  }

  void updateTournament(String tournamentId, Map<String, dynamic> updates) {
    final existing = getTournamentById(tournamentId);
    if (existing != null) {
      final copy = Map<String, dynamic>.from(existing)..addAll(updates);
      _updateLocalCache(copy);
    }
  }

  Future<void> registerTeamForTournament(
    String tournamentId,
    Map<String, dynamic> registration, {
    Dio? dio,
  }) async {
    if (dio != null) {
      try {
        await registerTeamForTournamentBackend(dio, tournamentId, registration);
      } catch (e) {
        debugPrint('registerTeamForTournament error: $e');
      }
    }
  }

  List<Map<String, dynamic>> generateAIFixtures(
    String tournamentId, {
    String strategy = 'balanced',
  }) {
    final tourn = getTournamentById(tournamentId);
    return List<Map<String, dynamic>>.from(tourn?['fixtures'] ?? []);
  }
}
