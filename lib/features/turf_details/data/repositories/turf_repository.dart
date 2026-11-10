import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';
import 'package:turf_app/features/turf_details/domain/models/slot.dart';

part 'turf_repository.g.dart';

class TurfRepository {
  final Dio _dio;

  TurfRepository(this._dio);

  Future<List<Turf>> getTurfs({String? search, String? sportType}) async {
    final response = await _dio.get('/turfs/', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (sportType != null && sportType != 'All Sports') 'sport_type': sportType,
    });
    return (response.data as List).map((e) => Turf.fromJson(e)).toList();
  }

  Future<Turf> getTurfById(int id) async {
    final response = await _dio.get('/turfs/$id');
    return Turf.fromJson(response.data);
  }

  Future<List<Slot>> getSlots(int turfId, {String? date}) async {
    final response = await _dio.get('/slots/', queryParameters: {
      'turf_id': turfId,
      if (date != null) 'date': date,
    });
    return (response.data as List).map((e) => Slot.fromJson(e)).toList();
  }

  Future<void> createSlot({
    required int turfId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _dio.post('/slots/', data: {
      'turf_id': turfId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_booked': false,
    });
  }

  Future<void> toggleSlot(int slotId) async {
    await _dio.post('/slots/$slotId/toggle');
  }

  Future<void> lockSlot(int slotId) async {
    await _dio.post('/slots/$slotId/lock');
  }

  Future<List<Turf>> getMyTurfs() async {
    final response = await _dio.get('/turfs/my-turfs');
    return (response.data as List).map((e) => Turf.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getTurfStats() async {
    try {
      final response = await _dio.get('/turfs/stats');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return {
          "total_revenue": 0,
          "total_bookings": 0,
          "active_turfs": 0
        };
      }
      rethrow;
    }
  }
}

@riverpod
Future<Map<String, dynamic>> fetchTurfStats(Ref ref) async {
  // Wait for user profile to be synced with backend
  final userProfile = await ref.watch(fetchUserProfileProvider.future);
  if (userProfile == null) {
    return {"total_revenue": 0, "total_bookings": 0, "active_turfs": 0};
  }
  
  return ref.watch(turfRepositoryProvider).getTurfStats();
}

@riverpod
TurfRepository turfRepository(Ref ref) {
  return TurfRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<Turf>> fetchTurfs(Ref ref, String? search, String? sportType) {
  return ref.watch(turfRepositoryProvider).getTurfs(search: search, sportType: sportType);
}

@riverpod
Future<Turf> fetchTurfById(Ref ref, int id) {
  return ref.watch(turfRepositoryProvider).getTurfById(id);
}

@riverpod
Future<List<Slot>> fetchSlots(Ref ref, int turfId, {String? date}) {
  return ref.watch(turfRepositoryProvider).getSlots(turfId, date: date);
}

@riverpod
Future<List<Turf>> fetchMyTurfs(Ref ref) async {
  // Wait for user profile to be synced with backend
  final userProfile = await ref.watch(fetchUserProfileProvider.future);
  if (userProfile == null) return [];
  
  return ref.watch(turfRepositoryProvider).getMyTurfs();
}
