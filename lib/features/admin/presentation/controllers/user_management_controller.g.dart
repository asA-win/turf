// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_management_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchAllUsersHash() => r'13c765070fe14e8ee2faef71bf34c4b97c32e21d';

/// See also [fetchAllUsers].
@ProviderFor(fetchAllUsers)
final fetchAllUsersProvider =
    AutoDisposeFutureProvider<List<UserProfile>>.internal(
      fetchAllUsers,
      name: r'fetchAllUsersProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$fetchAllUsersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchAllUsersRef = AutoDisposeFutureProviderRef<List<UserProfile>>;
String _$userManagementControllerHash() =>
    r'9f782db8a72efeb759ddff85675ae0f811a1b12f';

/// See also [UserManagementController].
@ProviderFor(UserManagementController)
final userManagementControllerProvider = AutoDisposeNotifierProvider<
  UserManagementController,
  AsyncValue<void>
>.internal(
  UserManagementController.new,
  name: r'userManagementControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userManagementControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserManagementController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
