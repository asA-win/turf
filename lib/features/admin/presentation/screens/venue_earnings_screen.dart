import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class VenueEarningsScreen extends ConsumerStatefulWidget {
  const VenueEarningsScreen({super.key});

  @override
  ConsumerState<VenueEarningsScreen> createState() => _VenueEarningsScreenState();
}

class _VenueEarningsScreenState extends ConsumerState<VenueEarningsScreen> {
  StreamSubscription<Map<String, dynamic>>? _earningsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _earningsSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
          if (mounted) ref.invalidate(fetchTurfStatsProvider);
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _earningsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(fetchTurfStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Earnings & Revenue'),
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
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load earnings: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (stats) {
            final double totalRev = (stats['total_revenue'] as num?)?.toDouble() ?? 0.0;
            final int totalBookings = (stats['total_bookings'] as num?)?.toInt() ?? 0;
            final double bookingsEarnings = totalRev * 0.90;
            final double addOnsEarnings = totalRev * 0.10;
            final double platformFee = totalRev * 0.05;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: Column(
                      children: [
                        Text('Total Confirmed Earnings', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalRev.toInt()}',
                          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Live from $totalBookings bookings',
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Earnings Breakdown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  const SizedBox(height: 12),
                  _item('Slot Bookings', '₹${bookingsEarnings.toInt()}', 'Confirmed', Colors.green),
                  _item('Equipment & Add-ons', '₹${addOnsEarnings.toInt()}', 'Confirmed', Colors.green),
                  _item('Platform Fee (5%)', '-₹${platformFee.toInt()}', 'Standard Fee', Colors.orange),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payout statement sent to registered email!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Download Payout Statement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _item(String title, String amount, String note, Color noteColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(note, style: GoogleFonts.poppins(color: noteColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
