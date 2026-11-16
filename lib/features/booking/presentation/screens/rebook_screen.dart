import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';

class RebookScreen extends ConsumerWidget {
  final String bookingId;
  const RebookScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingIdInt = int.tryParse(bookingId);
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);
    final booking = bookingsAsync.valueOrNull?.cast<Booking?>().firstWhere(
          (b) => b?.id == bookingIdInt,
          orElse: () => null,
        );

    final turfId = booking?.turfId ?? 1;
    final turfName = booking?.turf?.name ?? 'your favorite venue';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Rebook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: const Icon(Icons.refresh, size: 64, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 24),
              Text(
                'Book Again',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to rebook at $turfName or discover similar slots?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/slot-selection/$turfId'),
                child: const Text('Rebook Same Venue'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/similar-turfs/$turfId'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Find Similar Slots', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text('Back to Home', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
