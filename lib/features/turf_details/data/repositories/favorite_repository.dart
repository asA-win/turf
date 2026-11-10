import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/turf_details/domain/models/favorite.dart';

part 'favorite_repository.g.dart';

class FavoriteRepository {
  final Dio _dio;

  FavoriteRepository(this._dio);

  Future<List<Favorite>> getMyFavorites() async {
    try {
      final response = await _dio.get('/favorites/');
      return (response.data as List).map((e) => Favorite.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return []; // Return empty if user has no favorites record yet
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(int turfId) async {
    await _dio.post('/favorites/', data: {'turf_id': turfId});
  }
}

@riverpod
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepository(ref.watch(dioClientProvider));
}

@riverpod
Future<List<Favorite>> fetchMyFavorites(Ref ref) async {
  // Wait for user profile to be synced with backend
  final userProfile = await ref.watch(fetchUserProfileProvider.future);
  if (userProfile == null) return [];
  
  return ref.watch(favoriteRepositoryProvider).getMyFavorites();
}
