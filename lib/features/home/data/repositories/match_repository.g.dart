// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchRepositoryHash() => r'ab57cee6cf3183e9a596fafbacf452bc56811eb6';

/// See also [matchRepository].
@ProviderFor(matchRepository)
final matchRepositoryProvider = AutoDisposeProvider<MatchRepository>.internal(
  matchRepository,
  name: r'matchRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$matchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchRepositoryRef = AutoDisposeProviderRef<MatchRepository>;
String _$fetchMatchesHash() => r'7b9c6b3397d2bb537cf04bbd0e2be5e76ce81991';

/// See also [fetchMatches].
@ProviderFor(fetchMatches)
final fetchMatchesProvider =
    AutoDisposeFutureProvider<List<MatchModel>>.internal(
      fetchMatches,
      name: r'fetchMatchesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$fetchMatchesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchMatchesRef = AutoDisposeFutureProviderRef<List<MatchModel>>;
String _$watchMatchesHash() => r'ca019fc65fd4c0fff4c958d92c356296fe2d175f';

/// See also [watchMatches].
@ProviderFor(watchMatches)
final watchMatchesProvider =
    AutoDisposeStreamProvider<List<MatchModel>>.internal(
      watchMatches,
      name: r'watchMatchesProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$watchMatchesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WatchMatchesRef = AutoDisposeStreamProviderRef<List<MatchModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
