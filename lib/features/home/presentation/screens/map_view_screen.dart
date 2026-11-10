import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/providers/location_provider.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

class MapViewScreen extends ConsumerWidget {
  const MapViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLocationAsync = ref.watch(userLocationProvider);
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turfs Near You'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: userLocationAsync.when(
        data: (position) {
          final center = position != null 
              ? LatLng(position.latitude, position.longitude)
              : const LatLng(13.0827, 80.2707); // Default to Chennai

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.turf_app',
              ),
              MarkerLayer(
                markers: [
                  // User Location Marker
                  if (position != null)
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  
                  // Turf Markers
                  ...turfsAsync.maybeWhen(
                    data: (turfs) => turfs
                        .where((t) => t.latitude != null && t.longitude != null)
                        .map((t) => Marker(
                              point: LatLng(t.latitude!, t.longitude!),
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () => _showTurfPreview(context, t),
                                child: const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 40),
                              ),
                            ))
                        .toList(),
                    orElse: () => [],
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showTurfPreview(BuildContext context, Turf turf) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(turf.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(turf.location, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Rs. ${turf.pricePerHour.toInt()}/hr', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/turf-details/${turf.id}'),
                child: const Text('VIEW DETAILS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
