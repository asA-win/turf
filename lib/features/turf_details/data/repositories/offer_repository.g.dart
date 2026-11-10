// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$offerRepositoryHash() => r'24d3e879e79d1531ed640c65ad8063af0b1ed1a1';

/// See also [offerRepository].
@ProviderFor(offerRepository)
final offerRepositoryProvider = AutoDisposeProvider<OfferRepository>.internal(
  offerRepository,
  name: r'offerRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$offerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OfferRepositoryRef = AutoDisposeProviderRef<OfferRepository>;
String _$fetchOffersHash() => r'86f4a6e3e211d9786f15f15ec75a21a8d917d007';

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

/// See also [fetchOffers].
@ProviderFor(fetchOffers)
const fetchOffersProvider = FetchOffersFamily();

/// See also [fetchOffers].
class FetchOffersFamily extends Family<AsyncValue<List<Offer>>> {
  /// See also [fetchOffers].
  const FetchOffersFamily();

  /// See also [fetchOffers].
  FetchOffersProvider call({int? turfId}) {
    return FetchOffersProvider(turfId: turfId);
  }

  @override
  FetchOffersProvider getProviderOverride(
    covariant FetchOffersProvider provider,
  ) {
    return call(turfId: provider.turfId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchOffersProvider';
}

/// See also [fetchOffers].
class FetchOffersProvider extends AutoDisposeFutureProvider<List<Offer>> {
  /// See also [fetchOffers].
  FetchOffersProvider({int? turfId})
    : this._internal(
        (ref) => fetchOffers(ref as FetchOffersRef, turfId: turfId),
        from: fetchOffersProvider,
        name: r'fetchOffersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$fetchOffersHash,
        dependencies: FetchOffersFamily._dependencies,
        allTransitiveDependencies: FetchOffersFamily._allTransitiveDependencies,
        turfId: turfId,
      );

  FetchOffersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.turfId,
  }) : super.internal();

  final int? turfId;

  @override
  Override overrideWith(
    FutureOr<List<Offer>> Function(FetchOffersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchOffersProvider._internal(
        (ref) => create(ref as FetchOffersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        turfId: turfId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Offer>> createElement() {
    return _FetchOffersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchOffersProvider && other.turfId == turfId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, turfId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FetchOffersRef on AutoDisposeFutureProviderRef<List<Offer>> {
  /// The parameter `turfId` of this provider.
  int? get turfId;
}

class _FetchOffersProviderElement
    extends AutoDisposeFutureProviderElement<List<Offer>>
    with FetchOffersRef {
  _FetchOffersProviderElement(super.provider);

  @override
  int? get turfId => (origin as FetchOffersProvider).turfId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
