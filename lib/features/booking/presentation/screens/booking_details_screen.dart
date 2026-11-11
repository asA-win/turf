import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final Booking? booking;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  StreamSubscription<Map<String, dynamic>>? _bookingSub;
  String? _liveStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _bookingSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((event) {
          if (!mounted) return;
          ref.invalidate(fetchMyBookingsProvider);
          final bId = event['booking_id']?.toString() ?? event['id']?.toString();
          final newStatus = event['status']?.toString();
          if (bId == widget.bookingId && newStatus != null) {
            setState(() {
              _liveStatus = newStatus;
            });
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    super.dispose();
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve booking from param, or watch repository / demo sample
    Booking? resolvedBooking = widget.booking;
    if (resolvedBooking == null) {
      final myBookings = ref.watch(fetchMyBookingsProvider).valueOrNull ?? demoSampleBookings;
      final matchId = int.tryParse(widget.bookingId);
      resolvedBooking = myBookings.cast<Booking?>().firstWhere(
            (b) => b?.id == matchId,
            orElse: () => null,
          );
    }

    final turfName = resolvedBooking?.turf?.name ?? 'Green Field Arena';
    final location = resolvedBooking?.turf?.location ?? 'Indiranagar, Bengaluru';
    final bookingDate = resolvedBooking?.bookingDate ?? DateTime.now();
    final totalPrice = resolvedBooking?.totalPrice ?? 1500.0;
    final status = _liveStatus ?? resolvedBooking?.status ?? 'confirmed';
    final imageUrl = resolvedBooking?.turf?.imageUrl ??
        'https://images.unsplash.com/photo-1529900241452-4467c6ebc4ae?auto=format&fit=crop&w=600&q=80';
    final isCancelled = status.toLowerCase() == 'cancelled';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C140F),
        title: Text(
          'Booking Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/my-bookings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Share Receipt',
            onPressed: () => context.push('/share-booking'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Status & ID Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCancelled ? AppTheme.errorRed : AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCancelled ? 'CANCELLED' : 'CONFIRMED & RESERVED',
                          style: GoogleFonts.poppins(
                            color: isCancelled ? AppTheme.errorRed : AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'ID: #${widget.bookingId}',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Turf Header Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          color: const Color(0xFF152219),
                          child: const Center(
                            child: Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            turfName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Get direction shortcut
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: () => _openMap(
                                resolvedBooking?.turf?.latitude ?? 12.9716,
                                resolvedBooking?.turf?.longitude ?? 77.5946,
                              ),
                              icon: const Icon(Icons.directions_outlined, size: 16),
                              label: Text('Open Location on Google Maps', style: GoogleFonts.poppins(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(color: Color(0xFF1F3A27)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. QR Entry Pass Banner
              if (!isCancelled)
                GestureDetector(
                  onTap: () => context.push('/qr-entry-pass'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2B18), Color(0xFF143B22)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Digital Entry Pass',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Show QR code at venue gate for entry',
                                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFB5C8BC)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 4. Booking Slot Details Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Slot & Reservation Details',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    _item('Date', DateFormat('EEEE, dd MMMM yyyy').format(bookingDate)),
                    _item('Time Slot', '07:00 PM - 08:30 PM'),
                    _item('Duration', '1.5 Hours (90 mins)'),
                    _item('Court / Pitch', 'Main Pitch A (Artificial Turf)'),
                    _item('Sport Category', resolvedBooking?.turf?.sportTypes?.split(',').first.trim() ?? 'Football 5v5'),
                    _item('Included Amenities', 'Floodlights, Changing Room, Filtered Water'),
                    _item('Booking Type', resolvedBooking?.bookingType == 'join' ? 'Public / Open Join' : 'Full Pitch Booking'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Payment & Invoice Breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment & Invoice Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    _item('Base Slot Fee', '₹${(totalPrice * 0.9).toStringAsFixed(0)}'),
                    _item('Platform & Convenience Fee', '₹${(totalPrice * 0.05).toStringAsFixed(0)}'),
                    _item('GST (18% Included)', '₹${(totalPrice * 0.05).toStringAsFixed(0)}'),
                    const Divider(color: AppTheme.cardBorder, height: 20),
                    _item('Total Amount Paid', '₹${totalPrice.toStringAsFixed(0)}', isBold: true),
                    _item('Payment Mode', 'Paid via UPI (Ref #TXN9842104)'),
                    _item('Payment Status', isCancelled ? 'Refund Processed' : 'Successful / Settled'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/invite-players'),
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                      label: Text('Invite Squad', style: GoogleFonts.poppins(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-to-calendar'),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black),
                      label: Text(
                        'Add to Calendar',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (!isCancelled)
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/cancel-booking/${widget.bookingId}'),
                    icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorRed, size: 16),
                    label: Text(
                      'Cancel Booking',
                      style: GoogleFonts.poppins(
                        color: AppTheme.errorRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String k, String v, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12.5)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: isBold ? AppTheme.primaryGreen : Colors.white,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 14 : 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
