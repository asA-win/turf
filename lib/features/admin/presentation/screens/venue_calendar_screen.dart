import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class VenueCalendarScreen extends StatelessWidget {
  const VenueCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = [
      {'time': '6:00 PM - 7:00 PM', 'sport': 'Football (5v5)', 'status': 'Confirmed', 'color': Colors.green},
      {'time': '7:00 PM - 8:00 PM', 'sport': 'Football (6v6)', 'status': 'Confirmed', 'color': Colors.green},
      {'time': '8:00 PM - 9:00 PM', 'sport': 'Football (6v6)', 'status': 'Pending', 'color': Colors.amber},
      {'time': '9:00 PM - 10:00 PM', 'sport': 'Cricket Nets', 'status': 'Blocked', 'color': Colors.purple},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Venue Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('<  May 2025  >', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.black, size: 18),
                    label: Text('Add Time Slot', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, minimumSize: const Size(120, 36)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final s = slots[index];
                  final color = s['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['time'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            Text(s['sport'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                          child: Text(s['status'] as String, style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
