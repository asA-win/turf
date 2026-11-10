import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  StreamSubscription<Map<String, dynamic>>? _bookingUpdatesSub;

  @override
  void initState() {
    super.initState();
    _bookingUpdatesSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((event) {
      if (mounted) {
        ref.invalidate(fetchMyBookingsProvider);
      }
    });
  }

  @override
  void dispose() {
    _bookingUpdatesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text('My Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
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
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookingsList(isUpcoming: true),
            BookingsList(isUpcoming: false),
          ],
        ),
        bottomNavigationBar: const BysBottomNavBar(currentIndex: -1),
      ),
    );
  }
}

class BookingsList extends ConsumerWidget {
  final bool isUpcoming;
  const BookingsList({super.key, required this.isUpcoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        final now = DateTime.now();
        final filteredBookings = bookings.where((b) {
          if (isUpcoming) {
            // Include anything today or in the future
            final today = DateTime(now.year, now.month, now.day);
            return b.status != 'cancelled' && (b.bookingDate.isAfter(today) || b.bookingDate.isAtSameMomentAs(today));
          } else {
            return b.status == 'cancelled' || b.bookingDate.isBefore(DateTime(now.year, now.month, now.day));
          }
        }).toList();

        if (filteredBookings.isEmpty) {
          return Center(
            child: Text(
              isUpcoming ? 'No upcoming bookings' : 'No past bookings',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            return BookingCard(booking: filteredBookings[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        final now = DateTime.now();
        final filteredBookings = demoSampleBookings.where((b) {
          if (isUpcoming) {
            final today = DateTime(now.year, now.month, now.day);
            return b.status != 'cancelled' && (b.bookingDate.isAfter(today) || b.bookingDate.isAtSameMomentAs(today));
          } else {
            return b.status == 'cancelled' || b.bookingDate.isBefore(DateTime(now.year, now.month, now.day));
          }
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            return BookingCard(booking: filteredBookings[index]);
          },
        );
      },
    );
  }
}

class BookingCard extends ConsumerWidget {
  final Booking booking;
  const BookingCard({super.key, required this.booking});

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/booking-details/${booking.id}', extra: booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFF152219),
                child: booking.turf?.imageUrl != null
                    ? Image.network(
                        booking.turf!.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.sports_soccer, size: 48, color: AppTheme.primaryGreen),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.turf?.name ?? 'Turf #${booking.turfId}',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(booking.status).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(booking.status),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.turf?.location ?? 'Location',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textGrey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D140F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1B2C20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textGrey),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEE, dd MMM yyyy').format(booking.bookingDate),
                              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          '₹${booking.totalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tap for details prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view booking details & receipt',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textGrey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (booking.status != 'cancelled')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openMap(booking.turf?.latitude, booking.turf?.longitude),
                            icon: const Icon(Icons.directions_outlined, size: 16),
                            label: const Text('Direction', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      if (booking.status != 'cancelled') const SizedBox(width: 8),
                      if (booking.status != 'cancelled')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.cardDark,
                                  title: const Text('Cancel Booking?'),
                                  content: const Text('Are you sure you want to cancel this booking?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Yes', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                try {
                                  await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
                                  ref.invalidate(fetchMyBookingsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      if (booking.status == 'cancelled')
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Booking Cancelled',
                              style: GoogleFonts.poppins(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return AppTheme.primaryGreen;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
