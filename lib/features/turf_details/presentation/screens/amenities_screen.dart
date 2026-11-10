import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class AmenitiesScreen extends ConsumerWidget {
  final String turfId;
  const AmenitiesScreen({super.key, required this.turfId});

  IconData _iconForAmenity(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('light')) return Icons.lightbulb_outline;
    if (lower.contains('park')) return Icons.local_parking;
    if (lower.contains('rest') || lower.contains('wash')) return Icons.wc;
    if (lower.contains('chang') || lower.contains('room')) return Icons.checkroom;
    if (lower.contains('cafe') || lower.contains('canteen')) return Icons.local_cafe;
    if (lower.contains('water')) return Icons.water_drop;
    if (lower.contains('aid') || lower.contains('medical')) return Icons.medical_services;
    if (lower.contains('rental') || lower.contains('ball')) return Icons.sports_soccer;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('seat') || lower.contains('stand')) return Icons.event_seat;
    if (lower.contains('music') || lower.contains('audio')) return Icons.speaker;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numericTurfId = int.tryParse(turfId) ?? 1;
    final turfAsync = ref.watch(fetchTurfByIdProvider(numericTurfId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Amenities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: turfAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load amenities: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (turf) {
            final List<String> amenities = (turf.amenities != null && turf.amenities!.trim().isNotEmpty)
                ? turf.amenities!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : ['Floodlights', 'Parking', 'Restroom', 'Changing Room', 'Drinking Water', 'First Aid'];

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: amenities.length,
              itemBuilder: (context, index) {
                final amenityName = amenities[index];
                final icon = _iconForAmenity(amenityName);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: AppTheme.primaryGreen, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          amenityName,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Available',
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
