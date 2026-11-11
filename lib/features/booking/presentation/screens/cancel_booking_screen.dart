import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class CancelBookingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const CancelBookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends ConsumerState<CancelBookingScreen> {
  String _reason = 'Select a reason';

  final reasons = [
    'Select a reason',
    'Plans changed',
    'Weather conditions',
    'Booked by mistake',
    'Found another venue',
    'Other reason'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Cancel Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Green Field Arena', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    Text('18 May 2025 • 7:00 PM', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Cancellation Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              _policyRow('Cancel up to 12 hours before slot for full refund.'),
              _policyRow('Cancel within 12 hours for 50% refund.'),
              const SizedBox(height: 24),
              Text('Reason for Cancellation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _reason,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardDark,
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: GoogleFonts.poppins(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => _reason = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Refund Amount', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹1158', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 18)),
                        Text('(50% of ₹2316)', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final bId = widget.bookingId;
                  try {
                    final dio = ref.read(dioClientProvider);
                    await dio.post('/bookings/$bId/cancel');
                  } catch (_) {}

                  try {
                    ref.read(realtimeServiceProvider).emit('booking_updates', {
                      'type': 'booking_cancelled',
                      'booking_id': bId,
                      'status': 'cancelled',
                    });
                    ref.read(realtimeServiceProvider).emit('booking_requests', {
                      'type': 'booking_cancelled',
                      'booking_id': bId,
                    });
                  } catch (_) {}

                  ref.invalidate(fetchMyBookingsProvider);
                  ref.invalidate(fetchTurfStatsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking cancelled successfully. Refund initiated.'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                    context.go('/my-bookings');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                child: Text('Cancel Booking', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policyRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.textGrey, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
        ],
      ),
    );
  }
}
