import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Initial state is idle
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).loginWithEmail(email, password);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> loginWithPhone(String phoneNumber, String password) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).loginWithPhone(phoneNumber, password);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signUp(String email, String password, String username, String contact) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signUpWithEmail(email, password, username, contact);
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}
