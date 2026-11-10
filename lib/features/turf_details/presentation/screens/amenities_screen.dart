import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AmenitiesScreen extends StatelessWidget {
  final String turfId;
  const AmenitiesScreen({super.key, required this.turfId});

  @override
  Widget build(BuildContext context) {
    final amenities = [
      {'name': 'Floodlights', 'status': 'Yes', 'icon': Icons.lightbulb_outline},
      {'name': 'Parking', 'status': 'Available', 'icon': Icons.local_parking},
      {'name': 'Restroom', 'status': 'Yes', 'icon': Icons.wc},
      {'name': 'Changing Room', 'status': 'Yes', 'icon': Icons.checkroom},
      {'name': 'Cafeteria', 'status': 'Yes', 'icon': Icons.local_cafe},
      {'name': 'Water', 'status': 'Yes', 'icon': Icons.water_drop},
      {'name': 'First Aid', 'status': 'Yes', 'icon': Icons.medical_services},
      {'name': 'Equipment Rental', 'status': 'Yes', 'icon': Icons.sports_soccer},
      {'name': 'Wi-Fi', 'status': 'Available', 'icon': Icons.wifi},
      {'name': 'Spectator Seating', 'status': 'Yes', 'icon': Icons.event_seat},
      {'name': 'Music System', 'status': 'Yes', 'icon': Icons.speaker},
    ];

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
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: amenities.length,
                itemBuilder: (context, index) {
                  final item = amenities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, color: AppTheme.primaryGreen, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item['name'] as String,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          item['status'] as String,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/slot-selection/$turfId'),
                child: const Text('See Available Slots'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
