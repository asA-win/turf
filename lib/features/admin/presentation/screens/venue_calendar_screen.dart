import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class VenueCalendarScreen extends ConsumerStatefulWidget {
  const VenueCalendarScreen({super.key});

  @override
  ConsumerState<VenueCalendarScreen> createState() => _VenueCalendarScreenState();
}

class _VenueCalendarScreenState extends ConsumerState<VenueCalendarScreen> {
  StreamSubscription<Map<String, dynamic>>? _calendarSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _calendarSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
          if (mounted) ref.invalidate(fetchSlotsProvider(1));
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _calendarSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(fetchSlotsProvider(1));
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Venue Calendar'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  Text(
                    '<  $currentMonth  >',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(fetchSlotsProvider(1));
                    },
                    icon: const Icon(Icons.refresh, color: Colors.black, size: 18),
                    label: Text(
                      'Refresh Slots',
                      style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(120, 36),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (err, stack) => Center(
                  child: Text('Failed to load slots: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                ),
                data: (slots) {
                  if (slots.isEmpty) {
                    return Center(
                      child: Text('No slots scheduled for this month.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isAvailable = !slot.isBooked;
                      final color = isAvailable ? AppTheme.primaryGreen : AppTheme.errorRed;
                      final statusLabel = isAvailable ? 'Available' : 'Booked';

                      final startFormatted = DateFormat('hh:mm a').format(slot.startTime);
                      final endFormatted = DateFormat('hh:mm a').format(slot.endTime);
                      final timeStr = '$startFormatted - $endFormatted';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeStr,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Slot #${slot.id} • Capacity: ${slot.capacity}',
                                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12),
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
          ],
        ),
      ),
    );
  }
}
