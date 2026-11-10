import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/domain/models/user_profile.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_providers.dart';

part 'user_provider.g.dart';

@riverpod
Future<UserProfile?> fetchUserProfile(Ref ref) async {
  final dio = ref.watch(dioClientProvider);
  final authState = ref.watch(authStateChangesProvider);

  // Re-run whenever auth state changes
  final user = authState.valueOrNull;
  if (user == null) return null;

  try {
    final response = await dio.get('/users/me');
    return UserProfile.fromJson(response.data);
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      debugPrint('User not found in backend, creating for UID: ${user.uid}');
      try {
        final syncResponse = await dio.post('/users/', data: {
          'firebase_uid': user.uid,
          'email': user.email,
          'full_name': (user.displayName != null && user.displayName!.isNotEmpty) 
              ? user.displayName 
              : 'New User',
          'phone': user.phoneNumber,
        });
        
        // Wait a tiny bit for DB consistency
        await Future.delayed(const Duration(milliseconds: 800));
        return UserProfile.fromJson(syncResponse.data);
      } catch (syncError) {
        debugPrint('Sync failed: $syncError');
        // Return null instead of rethrowing to avoid provider error loops
        return null;
      }
    }
    debugPrint('fetchUserProfile error: $e');
    return null;
  }
}
