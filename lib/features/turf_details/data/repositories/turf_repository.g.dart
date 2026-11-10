// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turf_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchTurfStatsHash() => r'd23deea3e026704024ace4dab4836a48a97e9af9';

/// See also [fetchTurfStats].
@ProviderFor(fetchTurfStats)
final fetchTurfStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      fetchTurfStats,
      name: r'fetchTurfStatsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$fetchTurfStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchTurfStatsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$turfRepositoryHash() => r'71c70663df8f3bd7e51768cd7ba9274a20b1d5d8';

/// See also [turfRepository].
@ProviderFor(turfRepository)
final turfRepositoryProvider = AutoDisposeProvider<TurfRepository>.internal(
  turfRepository,
  name: r'turfRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$turfRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TurfRepositoryRef = AutoDisposeProviderRef<TurfRepository>;
String _$fetchTurfsHash() => r'2e74829e638e380830d08eec29b6f8c01fae4f87';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [fetchTurfs].
@ProviderFor(fetchTurfs)
const fetchTurfsProvider = FetchTurfsFamily();

/// See also [fetchTurfs].
class FetchTurfsFamily extends Family<AsyncValue<List<Turf>>> {
  /// See also [fetchTurfs].
  const FetchTurfsFamily();

  /// See also [fetchTurfs].
  FetchTurfsProvider call(String? search, String? sportType) {
    return FetchTurfsProvider(search, sportType);
  }

  @override
  FetchTurfsProvider getProviderOverride(
    covariant FetchTurfsProvider provider,
  ) {
    return call(provider.search, provider.sportType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchTurfsProvider';
}

/// See also [fetchTurfs].
class FetchTurfsProvider extends AutoDisposeFutureProvider<List<Turf>> {
  /// See also [fetchTurfs].
  FetchTurfsProvider(String? search, String? sportType)
    : this._internal(
        (ref) => fetchTurfs(ref as FetchTurfsRef, search, sportType),
        from: fetchTurfsProvider,
        name: r'fetchTurfsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$fetchTurfsHash,
        dependencies: FetchTurfsFamily._dependencies,
        allTransitiveDependencies: FetchTurfsFamily._allTransitiveDependencies,
        search: search,
        sportType: sportType,
      );

  FetchTurfsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.search,
    required this.sportType,
  }) : super.internal();

  final String? search;
  final String? sportType;

  @override
  Override overrideWith(
    FutureOr<List<Turf>> Function(FetchTurfsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchTurfsProvider._internal(
        (ref) => create(ref as FetchTurfsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        search: search,
        sportType: sportType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Turf>> createElement() {
    return _FetchTurfsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchTurfsProvider &&
        other.search == search &&
        other.sportType == sportType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);
    hash = _SystemHash.combine(hash, sportType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchTurfsRef on AutoDisposeFutureProviderRef<List<Turf>> {
  /// The parameter `search` of this provider.
  String? get search;

  /// The parameter `sportType` of this provider.
  String? get sportType;
}

class _FetchTurfsProviderElement
    extends AutoDisposeFutureProviderElement<List<Turf>>
    with FetchTurfsRef {
  _FetchTurfsProviderElement(super.provider);

  @override
  String? get search => (origin as FetchTurfsProvider).search;
  @override
  String? get sportType => (origin as FetchTurfsProvider).sportType;
}

String _$fetchTurfByIdHash() => r'07fbe68a04319c9564a13bbdff85e99b25a2943a';

/// See also [fetchTurfById].
@ProviderFor(fetchTurfById)
const fetchTurfByIdProvider = FetchTurfByIdFamily();

/// See also [fetchTurfById].
class FetchTurfByIdFamily extends Family<AsyncValue<Turf>> {
  /// See also [fetchTurfById].
  const FetchTurfByIdFamily();

  /// See also [fetchTurfById].
  FetchTurfByIdProvider call(int id) {
    return FetchTurfByIdProvider(id);
  }

  @override
  FetchTurfByIdProvider getProviderOverride(
    covariant FetchTurfByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchTurfByIdProvider';
}

/// See also [fetchTurfById].
class FetchTurfByIdProvider extends AutoDisposeFutureProvider<Turf> {
  /// See also [fetchTurfById].
  FetchTurfByIdProvider(int id)
    : this._internal(
        (ref) => fetchTurfById(ref as FetchTurfByIdRef, id),
        from: fetchTurfByIdProvider,
        name: r'fetchTurfByIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$fetchTurfByIdHash,
        dependencies: FetchTurfByIdFamily._dependencies,
        allTransitiveDependencies:
            FetchTurfByIdFamily._allTransitiveDependencies,
        id: id,
      );

  FetchTurfByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  Override overrideWith(
    FutureOr<Turf> Function(FetchTurfByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchTurfByIdProvider._internal(
        (ref) => create(ref as FetchTurfByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Turf> createElement() {
    return _FetchTurfByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchTurfByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchTurfByIdRef on AutoDisposeFutureProviderRef<Turf> {
  /// The parameter `id` of this provider.
  int get id;
}

class _FetchTurfByIdProviderElement
    extends AutoDisposeFutureProviderElement<Turf>
    with FetchTurfByIdRef {
  _FetchTurfByIdProviderElement(super.provider);

  @override
  int get id => (origin as FetchTurfByIdProvider).id;
}

String _$fetchSlotsHash() => r'65154b008562e16ff9e360e068afb76c8fea4800';

/// See also [fetchSlots].
@ProviderFor(fetchSlots)
const fetchSlotsProvider = FetchSlotsFamily();

/// See also [fetchSlots].
class FetchSlotsFamily extends Family<AsyncValue<List<Slot>>> {
  /// See also [fetchSlots].
  const FetchSlotsFamily();

  /// See also [fetchSlots].
  FetchSlotsProvider call(int turfId, {String? date}) {
    return FetchSlotsProvider(turfId, date: date);
  }

  @override
  FetchSlotsProvider getProviderOverride(
    covariant FetchSlotsProvider provider,
  ) {
    return call(provider.turfId, date: provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchSlotsProvider';
}

/// See also [fetchSlots].
class FetchSlotsProvider extends AutoDisposeFutureProvider<List<Slot>> {
  /// See also [fetchSlots].
  FetchSlotsProvider(int turfId, {String? date})
    : this._internal(
        (ref) => fetchSlots(ref as FetchSlotsRef, turfId, date: date),
        from: fetchSlotsProvider,
        name: r'fetchSlotsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$fetchSlotsHash,
        dependencies: FetchSlotsFamily._dependencies,
        allTransitiveDependencies: FetchSlotsFamily._allTransitiveDependencies,
        turfId: turfId,
        date: date,
      );

  FetchSlotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.turfId,
    required this.date,
  }) : super.internal();

  final int turfId;
  final String? date;

  @override
  Override overrideWith(
    FutureOr<List<Slot>> Function(FetchSlotsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchSlotsProvider._internal(
        (ref) => create(ref as FetchSlotsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        turfId: turfId,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Slot>> createElement() {
    return _FetchSlotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchSlotsProvider &&
        other.turfId == turfId &&
        other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, turfId.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchSlotsRef on AutoDisposeFutureProviderRef<List<Slot>> {
  /// The parameter `turfId` of this provider.
  int get turfId;

  /// The parameter `date` of this provider.
  String? get date;
}

class _FetchSlotsProviderElement
    extends AutoDisposeFutureProviderElement<List<Slot>>
    with FetchSlotsRef {
  _FetchSlotsProviderElement(super.provider);

  @override
  int get turfId => (origin as FetchSlotsProvider).turfId;
  @override
  String? get date => (origin as FetchSlotsProvider).date;
}

String _$fetchMyTurfsHash() => r'c997a04137bd399abaadfc1b6fb615bfd5c5600c';

/// See also [fetchMyTurfs].
@ProviderFor(fetchMyTurfs)
final fetchMyTurfsProvider = AutoDisposeFutureProvider<List<Turf>>.internal(
  fetchMyTurfs,
  name: r'fetchMyTurfsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fetchMyTurfsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FetchMyTurfsRef = AutoDisposeFutureProviderRef<List<Turf>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
