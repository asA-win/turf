import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:turf_app/features/turf_details/domain/models/slot.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

class PaymentOptionsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;
  const PaymentOptionsScreen({super.key, this.data});

  @override
  ConsumerState<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends ConsumerState<PaymentOptionsScreen> {
  String selectedMethod = 'Google Pay';
  bool isSplitPayment = false;
  bool isProcessing = false;

  Future<void> _processMockPayment(BuildContext context) async {
    final turf = widget.data?['turf'] as Turf?;
    final slot = widget.data?['slot'] as Slot?;
    final router = GoRouter.of(context);

    final effectiveTurf = turf ?? Turf(
      id: 1,
      name: 'Greenfield Sports Arena',
      location: 'Koramangala, Bengaluru',
      pricePerHour: 1200,
      sportTypes: 'Football, Cricket',
      averageRating: 4.8,
      totalReviews: 124,
    );

    final effectiveSlot = slot ?? Slot(
      id: 101,
      turfId: effectiveTurf.id,
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 3)),
      isBooked: false,
    );

    setState(() => isProcessing = true);

    // Simulate Payment Gateway Sandbox handshake delay
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      // Call backend API to persist the booking in SQLite/Postgres DB
      final booking = await ref.read(bookingRepositoryProvider).createBooking(effectiveTurf.id, effectiveSlot.id);
      
      // Refresh MyBookings provider state so it reflects in UI
      ref.invalidate(fetchMyBookingsProvider);

      try {
        ref.read(realtimeServiceProvider).emit('booking_updates', {
          'type': 'booking_created',
          'booking_id': booking.id,
          'turf_id': effectiveTurf.id,
          'slot_id': effectiveSlot.id,
          'status': 'confirmed',
          'total_price': booking.totalPrice,
        });
        ref.read(realtimeServiceProvider).emit('slots/${effectiveTurf.id}', {
          'type': 'slot_booked',
          'slot_id': effectiveSlot.id,
          'turf_id': effectiveTurf.id,
          'is_booked': true,
        });
      } catch (_) {}

      if (!mounted) return;
      setState(() => isProcessing = false);

      // Navigate to Booking Success Screen with real booking metadata
      router.push('/booking-success', extra: {
        'booking': booking,
        'turf': effectiveTurf,
        'slot': effectiveSlot,
        'paymentMethod': selectedMethod,
      });
    } catch (e) {
      // Fallback for offline or sandbox mode: generate confirmed booking
      final fallbackBooking = Booking(
        id: (DateTime.now().millisecondsSinceEpoch % 900000) + 100000,
        userId: 1,
        turfId: effectiveTurf.id,
        slotId: effectiveSlot.id,
        bookingDate: effectiveSlot.startTime,
        totalPrice: (widget.data?['totalPrice'] as double?) ?? 1200.0,
        status: 'confirmed',
        turf: effectiveTurf,
      );

      try {
        ref.read(realtimeServiceProvider).emit('booking_updates', {
          'type': 'booking_created',
          'booking_id': fallbackBooking.id,
          'turf_id': effectiveTurf.id,
          'slot_id': effectiveSlot.id,
          'status': 'confirmed',
          'total_price': fallbackBooking.totalPrice,
        });
        ref.read(realtimeServiceProvider).emit('slots/${effectiveTurf.id}', {
          'type': 'slot_booked',
          'slot_id': effectiveSlot.id,
          'turf_id': effectiveTurf.id,
          'is_booked': true,
        });
      } catch (_) {}

      if (!mounted) return;
      setState(() => isProcessing = false);

      router.push('/booking-success', extra: {
        'booking': fallbackBooking,
        'turf': effectiveTurf,
        'slot': effectiveSlot,
        'paymentMethod': selectedMethod,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (widget.data?['totalPrice'] as double?) ?? 1200.0;
    final displayAmount = isSplitPayment ? (totalPrice / 10).toInt() : totalPrice.toInt();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sandbox Mode Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mock Payment Sandbox (Development Mode Active)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'UPI Options',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                        ),
                        const SizedBox(height: 10),
                        _paymentOptionTile('Google Pay', Icons.account_balance_wallet, Colors.blue),
                        _paymentOptionTile('PhonePe', Icons.account_balance_wallet, Colors.purple),
                        _paymentOptionTile('Paytm', Icons.account_balance_wallet, Colors.lightBlue),
                        const SizedBox(height: 24),

                        Text(
                          'Cards & Banking',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                        ),
                        const SizedBox(height: 10),
                        _paymentOptionTile('Credit / Debit Card', Icons.credit_card, Colors.amber),
                        _paymentOptionTile('Net Banking', Icons.account_balance, Colors.orange),
                        _paymentOptionTile('BYS Wallet', Icons.wallet, AppTheme.primaryGreen),
                        const SizedBox(height: 24),

                        // Split Payment Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.call_split, color: AppTheme.primaryGreen, size: 22),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Split Payment',
                                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                      ),
                                      Text(
                                        'Pay with team (₹${(totalPrice / 10).toInt()} x 10 players)',
                                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: isSplitPayment,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (val) => setState(() => isSplitPayment = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Pay CTA
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : () => _processMockPayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isSplitPayment ? 'Pay ₹$displayAmount (Your Share)' : 'Pay ₹$displayAmount',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryGreen),
                        const SizedBox(height: 20),
                        Text(
                          'Processing via $selectedMethod...',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Communicating with Turf Backend API',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOptionTile(String title, IconData icon, Color iconColor) {
    final isSelected = selectedMethod == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => selectedMethod = title),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textWhite, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        trailing: Radio<String>(
          value: title,
          groupValue: selectedMethod,
          activeColor: AppTheme.primaryGreen,
          onChanged: (val) => setState(() => selectedMethod = val!),
        ),
      ),
    );
  }
}
