import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class LiveBookingRequestsScreen extends ConsumerStatefulWidget {
  const LiveBookingRequestsScreen({super.key});

  @override
  ConsumerState<LiveBookingRequestsScreen> createState() => _LiveBookingRequestsScreenState();
}

class _LiveBookingRequestsScreenState extends ConsumerState<LiveBookingRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialRequests();
    _connectRealtime();
  }

  Future<void> _loadInitialRequests() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/bookings/requests');
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final serverRequests = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) {
          setState(() {
            _requests.clear();
            _requests.addAll(serverRequests);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Could not fetch server booking requests, using live memory list: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _connectRealtime() {
    final stream = ref.read(realtimeServiceProvider).connectToChannel('booking_requests');
    _sub = stream.listen((event) {
      debugPrint('Real-time booking request event received: $event');
      final eventType = event['type'] as String?;

      if (eventType == 'new_booking_request') {
        final newReq = {
          'id': event['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'name': event['name'] ?? 'Player',
          'slot': event['slot'] ?? 'Evening Slot',
          'sport': event['sport'] ?? 'Football (6v6)',
          'price': event['price'] ?? '₹1,200',
          'players': event['players'] ?? '10 Players',
          'turf_name': event['turf_name'] ?? 'Turf Arena',
          'status': event['status'] ?? 'pending',
          'isLive': true,
        };

        if (mounted) {
          setState(() {
            // Remove existing if duplicate
            _requests.removeWhere((r) => r['id'] == newReq['id']);
            _requests.insert(0, newReq);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bolt, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ New Booking from ${newReq['name']} (${newReq['slot']})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.cardDark,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (eventType == 'request_status_updated') {
        final bId = event['booking_id'];
        final status = event['status'] as String? ?? 'confirmed';
        if (mounted) {
          setState(() {
            final idx = _requests.indexWhere((r) => r['id'] == bId);
            if (idx != -1) {
              _requests[idx]['status'] = status;
            }
          });
        }
      } else if (eventType == 'booking_cancelled') {
        final bId = event['booking_id'];
        if (mounted) {
          setState(() {
            final idx = _requests.indexWhere((r) => r['id'] == bId);
            if (idx != -1) {
              _requests[idx]['status'] = 'declined';
            }
          });
        }
      }
    });
  }

  Future<void> _respondToBooking(Map<String, dynamic> request, String action) async {
    final bookingId = request['id'];
    final newStatus = action == 'accept' ? 'confirmed' : 'declined';

    // Optimistic UI update
    setState(() {
      request['status'] = newStatus;
    });

    // Notify backend WebSocket channel
    ref.read(realtimeServiceProvider).emitToChannel('booking_requests', {
      'type': 'request_status_updated',
      'booking_id': bookingId,
      'status': newStatus,
    });

    // REST call
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/bookings/$bookingId/respond', data: {'action': action});
    } catch (e) {
      debugPrint('Booking respond REST fallback: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept' ? '✅ Request Accepted & Confirmed Live!' : '❌ Request Declined & Slot Released Live',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: action == 'accept' ? AppTheme.primaryGreen : AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _requests.where((r) => r['status'] == 'pending').toList();
    final confirmedList = _requests.where((r) => r['status'] == 'confirmed').toList();
    final declinedList = _requests.where((r) => r['status'] == 'declined').toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Booking Requests'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
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
                    'LIVE SYNC',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: [
            Tab(text: 'Pending (${pendingList.length})'),
            Tab(text: 'Confirmed (${confirmedList.length})'),
            Tab(text: 'Declined (${declinedList.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestListView(pendingList, isPendingTab: true),
                  _buildRequestListView(confirmedList),
                  _buildRequestListView(declinedList),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestListView(List<Map<String, dynamic>> items, {bool isPendingTab = false}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              isPendingTab ? 'No pending requests' : 'No bookings in this category',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
            ),
            if (isPendingTab)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Incoming player bookings will appear here in real time.',
                  style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final isPending = r['status'] == 'pending';
        final isConfirmed = r['status'] == 'confirmed';
        final isLive = r['isLive'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? AppTheme.primaryGreen : AppTheme.cardBorder,
              width: isLive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        r['slot'] ?? 'Evening Slot',
                        style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    r['price'] ?? '₹1,200',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.surfaceDark,
                    child: Text(
                      (r['name'] as String? ?? 'P')[0].toUpperCase(),
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name'] ?? 'Player',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${r['turf_name'] ?? 'Turf'} • ${r['players'] ?? '10 Players'}',
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withValues(alpha: 0.15)
                          : (isConfirmed ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (r['status'] as String? ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: isPending
                            ? Colors.orange
                            : (isConfirmed ? Colors.green : Colors.red),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToBooking(r, 'decline'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Decline', style: GoogleFonts.poppins(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToBooking(r, 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Accept', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
