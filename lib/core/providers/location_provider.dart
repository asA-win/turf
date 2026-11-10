import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'location_provider.g.dart';

@riverpod
class UserLocation extends _$UserLocation {
  @override
  FutureOr<Position?> build() async {
    return _getCurrentLocation();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (kIsWeb) {
      // Geolocator works on Web, but service check is slightly different
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition();
    }

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _getCurrentLocation());
  }
}

@riverpod
Future<String> locationName(Ref ref) async {
  final locationAsync = ref.watch(userLocationProvider);
  
  return locationAsync.when(
    data: (pos) async {
      if (pos == null) return 'Select Location';
      
      // geocoding package DOES NOT support Web
      if (kIsWeb) {
        return '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}';
      }

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          return place.subLocality ?? place.locality ?? place.name ?? 'Unknown';
        }
      } catch (e) {
        return 'Unknown Location';
      }
      return 'Unknown';
    },
    loading: () => 'Detecting...',
    error: (_, __) => 'Error',
  );
}
