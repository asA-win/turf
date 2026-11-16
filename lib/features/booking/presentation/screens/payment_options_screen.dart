import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/services/session_manager.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
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
    final isTournament = widget.data?['isTournamentBooking'] == true || widget.data?['tournament'] != null;
    final router = GoRouter.of(context);

    if (isTournament) {
      setState(() => isProcessing = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() => isProcessing = false);

      final tournament = widget.data?['tournament'] as Map<String, dynamic>? ?? {};
      final dynamic rawId = tournament['backendId'] ?? tournament['id'] ?? tournament['dbId'];
      final tournId = rawId?.toString() ?? '1';
      final tournName = tournament['name'] ?? tournament['title'] ?? 'Tournament Championship';
      final teamName = widget.data?['teamName'] ?? 'My Squad FC';

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F1B13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 28),
              const SizedBox(width: 10),
              Text('Payment Confirmed', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'Your entry fee has been paid successfully! Team "$teamName" is officially registered for $tournName.',
            style: GoogleFonts.poppins(color: const Color(0xFFC0D2C6), fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                router.go('/tournament-hub', extra: {
                  ...tournament,
                  'id': tournId,
                  'initialTab': 0,
                  'justRegistered': true,
                });
              },
              child: const Text('View in Tournament Hub', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    final turf = widget.data?['turf'] as Turf?;
    final slot = widget.data?['slot'] as Slot?;

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

    // Ensure native backend token is loaded/refreshed
    await SessionManager.ensureBackendToken();

    // Simulate Payment Gateway Sandbox handshake delay
    await Future.delayed(const Duration(milliseconds: 1000));

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
      if (!mounted) return;
      setState(() => isProcessing = false);

      String errorMsg = 'Failed to confirm booking. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMsg = data['detail'].toString();
        } else if (e.response?.statusCode == 409) {
          errorMsg = 'This slot has already been booked or is locked by another player.';
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'Session expired. Please log in again to book.';
        }
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                'Booking Failed',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            errorMsg,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
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
