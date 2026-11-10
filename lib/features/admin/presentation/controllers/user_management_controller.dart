import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/domain/models/user_profile.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

part 'user_management_controller.g.dart';

@riverpod
Future<List<UserProfile>> fetchAllUsers(Ref ref) async {
  // Wait for user profile to be synced with backend
  final userProfile = await ref.watch(fetchUserProfileProvider.future);
  if (userProfile == null || userProfile.role != 'admin') return [];

  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/users/');
  return (response.data as List).map((u) => UserProfile.fromJson(u)).toList();
}

@riverpod
class UserManagementController extends _$UserManagementController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateUserRole(int userId, String newRole) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/users/$userId/role', data: {'role': newRole});
      ref.invalidate(fetchAllUsersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
