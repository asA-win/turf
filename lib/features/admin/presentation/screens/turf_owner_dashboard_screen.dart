import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/services/realtime_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class TurfOwnerDashboardScreen extends ConsumerStatefulWidget {
  const TurfOwnerDashboardScreen({super.key});

  @override
  ConsumerState<TurfOwnerDashboardScreen> createState() => _TurfOwnerDashboardScreenState();
}

class _TurfOwnerDashboardScreenState extends ConsumerState<TurfOwnerDashboardScreen> {
  int? selectedTurfId;
  DateTime selectedDate = DateTime.now();
  StreamSubscription<Map<String, dynamic>>? _bookingUpdatesSub;

  @override
  void initState() {
    super.initState();
    _bookingUpdatesSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
      if (mounted) {
        ref.invalidate(fetchTurfStatsProvider);
        if (selectedTurfId != null) {
          ref.invalidate(fetchSlotsProvider(selectedTurfId!));
        }
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
    final statsAsync = ref.watch(fetchTurfStatsProvider);
    final myTurfsAsync = ref.watch(fetchMyTurfsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Turf Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Live Booking Requests',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_active_outlined),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/live-booking-requests'),
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _buildStatGrid(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading stats: $err'),
            ),
            const SizedBox(height: 32),
            myTurfsAsync.when(
              data: (turfs) {
                if (turfs.isEmpty) return const Center(child: Text('No turfs found. Add one below!'));
                selectedTurfId ??= turfs.first.id;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Turfs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: turfs.length,
                        itemBuilder: (context, index) {
                          final turf = turfs[index];
                          final isSelected = selectedTurfId == turf.id;
                          return GestureDetector(
                            onTap: () => setState(() => selectedTurfId = turf.id),
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
                                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    turf.name, 
                                    style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.edit, color: isSelected ? Colors.white : Colors.blue, size: 20),
                                        onPressed: () => context.push('/add-turf', extra: turf),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Manage Slots', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _showAddSlotsDialog(context),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Slots'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildSlotManager(selectedTurfId!),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading turfs: $err'),
            ),
            const SizedBox(height: 32),
            Text('Today\'s Bookings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTodaysBookings(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-turf'),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Turf', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(14, (index) {
          final date = DateTime.now().add(Duration(days: index));
          bool isSelected = selectedDate.day == date.day && selectedDate.month == date.month;
          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(DateFormat('E').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10)),
                  Text(DateFormat('d MMM').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showAddSlotsDialog(BuildContext context) {
    int startHour = 6;
    int endHour = 22;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Slots for ${DateFormat('d MMM').format(selectedDate)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Generate 1-hour slots'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('From: '),
                  DropdownButton<int>(
                    value: startHour,
                    items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                    onChanged: (val) => setDialogState(() => startHour = val!),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('To: '),
                  DropdownButton<int>(
                    value: endHour,
                    items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('$i:00'))),
                    onChanged: (val) => setDialogState(() => endHour = val!),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _generateSlots(startHour, endHour);
              }, 
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSlots(int start, int end) async {
    if (selectedTurfId == null) return;
    
    try {
      final repo = ref.read(turfRepositoryProvider);
      for (int i = start; i < end; i++) {
        final startTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, i);
        final endTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, i + 1);
        await repo.createSlot(turfId: selectedTurfId!, startTime: startTime, endTime: endTime);
      }
      ref.invalidate(fetchSlotsProvider(selectedTurfId!));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slots generated successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating slots: $e')));
    }
  }

  Widget _buildStatGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard('Total Revenue', 'Rs. ${stats['total_revenue']}', Icons.payments, Colors.green),
        _statCard('Total Bookings', '${stats['total_bookings']}', Icons.calendar_month, Colors.orange),
        _statCard('Active Turfs', '${stats['active_turfs']}', Icons.sports_soccer, Colors.blue),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSlotManager(int turfId) {
    final slotsAsync = ref.watch(fetchSlotsProvider(turfId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: slotsAsync.when(
        data: (slots) {
          if (slots.isEmpty) return const Center(child: Text('No slots for this date. Click "Add Slots" to create some.'));
          return Column(
            children: slots.map((slot) => _slotItem(slot)).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error: $err'),
      ),
    );
  }

  Widget _slotItem(slot) {
    final timeStr = DateFormat('h a').format(slot.startTime);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeStr, style: GoogleFonts.poppins()),
          Row(
            children: [
              if (slot.isBooked) const Text('BOOKED ', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              Switch(
                value: !slot.isBooked, 
                onChanged: (val) async {
                  try {
                    await ref.read(turfRepositoryProvider).toggleSlot(slot.id);
                    ref.invalidate(fetchSlotsProvider(selectedTurfId!));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                activeColor: AppTheme.primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysBookings() {
    final bookings = [
      {'name': 'Alwin Joseph', 'time': '07:00 AM - 08:00 AM', 'status': 'Paid', 'amount': '1200'},
      {'name': 'Arun Kumar', 'time': '05:00 PM - 06:00 PM', 'status': 'Pending', 'amount': '1200'},
      {'name': 'Vijay Sethi', 'time': '06:00 PM - 07:00 PM', 'status': 'Paid', 'amount': '1200'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(booking['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(booking['time']!),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: booking['status'] == 'Paid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking['status']!, 
                style: TextStyle(
                  color: booking['status'] == 'Paid' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                )
              ),
            ),
          ),
        );
      },
    );
  }
}
