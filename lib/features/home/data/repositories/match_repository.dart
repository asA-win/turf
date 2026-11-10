import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/home/domain/models/match_model.dart';

part 'match_repository.g.dart';

class MatchRepository {
  final Dio _dio;

  MatchRepository(this._dio);

  Future<List<MatchModel>> getMatches() async {
    final response = await _dio.get('/matches/');
    return (response.data as List).map((e) => MatchModel.fromJson(e)).toList();
  }

  Future<void> updateScore(int matchId, int scoreA, int scoreB) async {
    await _dio.put('/matches/$matchId/score', queryParameters: {
      'team_a_score': scoreA,
      'team_b_score': scoreB,
    });
  }
}

@riverpod
MatchRepository matchRepository(Ref ref) {
  return MatchRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<MatchModel>> fetchMatches(Ref ref) {
  return ref.watch(matchRepositoryProvider).getMatches();
}

@riverpod
Stream<List<MatchModel>> watchMatches(Ref ref) async* {
  // Yield initial value
  final initialMatches = await ref.read(matchRepositoryProvider).getMatches();
  yield initialMatches;
  
  // Poll every 10 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    yield await ref.read(matchRepositoryProvider).getMatches();
  }
}
