// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewRepositoryHash() => r'50335f407c297cfd6c79252626288c89ae62ab22';

/// See also [reviewRepository].
@ProviderFor(reviewRepository)
final reviewRepositoryProvider = AutoDisposeProvider<ReviewRepository>.internal(
  reviewRepository,
  name: r'reviewRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reviewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReviewRepositoryRef = AutoDisposeProviderRef<ReviewRepository>;
String _$fetchTurfReviewsHash() => r'481670a5a5560bc1e732185750232f85b6d4f4aa';

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

/// See also [fetchTurfReviews].
@ProviderFor(fetchTurfReviews)
const fetchTurfReviewsProvider = FetchTurfReviewsFamily();

/// See also [fetchTurfReviews].
class FetchTurfReviewsFamily extends Family<AsyncValue<List<Review>>> {
  /// See also [fetchTurfReviews].
  const FetchTurfReviewsFamily();

  /// See also [fetchTurfReviews].
  FetchTurfReviewsProvider call(int turfId) {
    return FetchTurfReviewsProvider(turfId);
  }

  @override
  FetchTurfReviewsProvider getProviderOverride(
    covariant FetchTurfReviewsProvider provider,
  ) {
    return call(provider.turfId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchTurfReviewsProvider';
}

/// See also [fetchTurfReviews].
class FetchTurfReviewsProvider extends AutoDisposeFutureProvider<List<Review>> {
  /// See also [fetchTurfReviews].
  FetchTurfReviewsProvider(int turfId)
    : this._internal(
        (ref) => fetchTurfReviews(ref as FetchTurfReviewsRef, turfId),
        from: fetchTurfReviewsProvider,
        name: r'fetchTurfReviewsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$fetchTurfReviewsHash,
        dependencies: FetchTurfReviewsFamily._dependencies,
        allTransitiveDependencies:
            FetchTurfReviewsFamily._allTransitiveDependencies,
        turfId: turfId,
      );

  FetchTurfReviewsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.turfId,
  }) : super.internal();

  final int turfId;

  @override
  Override overrideWith(
    FutureOr<List<Review>> Function(FetchTurfReviewsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchTurfReviewsProvider._internal(
        (ref) => create(ref as FetchTurfReviewsRef),
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
  AutoDisposeFutureProviderElement<List<Review>> createElement() {
    return _FetchTurfReviewsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchTurfReviewsProvider && other.turfId == turfId;
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
mixin FetchTurfReviewsRef on AutoDisposeFutureProviderRef<List<Review>> {
  /// The parameter `turfId` of this provider.
  int get turfId;
}

class _FetchTurfReviewsProviderElement
    extends AutoDisposeFutureProviderElement<List<Review>>
    with FetchTurfReviewsRef {
  _FetchTurfReviewsProviderElement(super.provider);

  @override
  int get turfId => (origin as FetchTurfReviewsProvider).turfId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
