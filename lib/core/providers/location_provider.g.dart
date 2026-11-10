// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationNameHash() => r'f9e156d61baee4f6bb7b0bf1ebdf61e9fa545d9e';

/// See also [locationName].
@ProviderFor(locationName)
final locationNameProvider = AutoDisposeFutureProvider<String>.internal(
  locationName,
  name: r'locationNameProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$locationNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationNameRef = AutoDisposeFutureProviderRef<String>;
String _$userLocationHash() => r'1eff6bed225ee028563206453815b412b4401ef0';

/// See also [UserLocation].
@ProviderFor(UserLocation)
final userLocationProvider =
    AutoDisposeAsyncNotifierProvider<UserLocation, Position?>.internal(
      UserLocation.new,
      name: r'userLocationProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$userLocationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserLocation = AutoDisposeAsyncNotifier<Position?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
