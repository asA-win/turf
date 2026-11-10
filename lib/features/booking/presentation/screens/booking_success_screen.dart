import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:turf_app/features/turf_details/domain/models/slot.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  const BookingSuccessScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final booking = data?['booking'] as Booking?;
    final turf = data?['turf'] as Turf?;
    final slot = data?['slot'] as Slot?;

    final bookingIdStr = booking != null ? 'BYS${booking.id.toString().padLeft(6, '0')}' : 'BYS202405241234';
    final turfName = turf?.name ?? 'Turf Arena';
    final priceStr = booking != null ? '₹${booking.totalPrice.toInt()}' : '₹1,200';

    final timeStr = slot != null
        ? '${DateFormat('EEE, dd MMM yyyy').format(slot.startTime.toLocal())} • ${DateFormat('hh:mm a').format(slot.startTime.toLocal())} - ${DateFormat('hh:mm a').format(slot.endTime.toLocal())}'
        : 'Confirmed Slot';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Animated / Styled Checkmark Circle
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGreen, width: 3),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.primaryGreen,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Payment Successful!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your booking is confirmed in database',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Booking ID Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          'Booking ID: $bookingIdStr',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2, size: 140, color: Colors.black),
                            const SizedBox(height: 8),
                            Text(
                              'Scan at venue gate for entry',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Booking Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              turfName,
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount Paid: $priceStr • Confirmed',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Home',
                        style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/my-bookings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'View My Bookings',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
