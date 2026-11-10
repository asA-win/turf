// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteRepositoryHash() =>
    r'24d9d4c7d908bf50c3a48a118682e3540cf197e3';

/// See also [favoriteRepository].
@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider =
    AutoDisposeProvider<FavoriteRepository>.internal(
      favoriteRepository,
      name: r'favoriteRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$favoriteRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteRepositoryRef = AutoDisposeProviderRef<FavoriteRepository>;
String _$fetchMyFavoritesHash() => r'374acc21663da9b9dd844c14ee2301caba3a424e';

/// See also [fetchMyFavorites].
@ProviderFor(fetchMyFavorites)
final fetchMyFavoritesProvider =
    AutoDisposeFutureProvider<List<Favorite>>.internal(
      fetchMyFavorites,
      name: r'fetchMyFavoritesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$fetchMyFavoritesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchMyFavoritesRef = AutoDisposeFutureProviderRef<List<Favorite>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
