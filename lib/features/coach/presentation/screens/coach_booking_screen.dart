import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

final fetchCoachesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/coaches/');
  return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

class CoachBookingScreen extends ConsumerStatefulWidget {
  const CoachBookingScreen({super.key});

  @override
  ConsumerState<CoachBookingScreen> createState() => _CoachBookingScreenState();
}

class _CoachBookingScreenState extends ConsumerState<CoachBookingScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    try {
      _realtimeSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
        if (mounted) {
          ref.invalidate(fetchCoachesProvider);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  void _showBookingModal(Map<String, dynamic> coach) {
    String selectedSlot = 'Today • 06:00 PM';
    final coachName = coach['full_name'] ?? coach['name'] ?? 'Coach';
    final coachRole = coach['role'] ?? 'Specialist Coach';
    final coachPrice = coach['price_per_session'] != null 
        ? '₹${(coach['price_per_session'] as num).toInt()}/session' 
        : (coach['price'] ?? '₹1,200/session');
    final avatar = coach['image_url'] ?? coach['avatar'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Book Coaching Session', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatar)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(coachName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                        Text(coachRole, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                      ],
                    ),
                  ),
                  Text(coachPrice, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Select Training Slot', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Today • 06:00 PM',
                  'Today • 07:30 PM',
                  'Tomorrow • 06:30 AM',
                  'Tomorrow • 05:00 PM',
                ].map((slot) {
                  final isSel = selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSel,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: GoogleFonts.poppins(
                      color: isSel ? Colors.black : AppTheme.textWhite,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder),
                    onSelected: (val) => setModalState(() => selectedSlot = slot),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                      ref.read(realtimeServiceProvider).emit('booking_requests', {
                        'type': 'coach_booked',
                        'name': coachName,
                        'slot': selectedSlot,
                        'price': coachPrice,
                        'sport': 'Coaching Session',
                        'status': 'confirmed',
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                      ref.read(realtimeServiceProvider).emit('booking_updates', {
                        'type': 'coach_booked',
                        'name': coachName,
                        'slot': selectedSlot,
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                    } catch (_) {}
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Session booked with $coachName for $selectedSlot!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirm Coaching Session', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coachesAsync = ref.watch(fetchCoachesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Coach Booking',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                style: GoogleFonts.poppins(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search coaches by name, sport...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  fillColor: AppTheme.cardDark,
                ),
              ),
            ),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['All', 'Football', 'Cricket', 'Racquet', 'Fitness'].map((cat) {
                  final isSel = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSel,
                      label: Text(cat),
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.black : AppTheme.textWhite,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.cardDark,
                      side: BorderSide(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder),
                      onSelected: (val) => setState(() => selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Coaches List
            Expanded(
              child: coachesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (err, stack) => Center(
                  child: Text('Failed to load coaches: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                ),
                data: (allCoaches) {
                  final filtered = allCoaches.where((c) {
                    final name = (c['full_name'] ?? c['name'] ?? '').toString().toLowerCase();
                    final role = (c['role'] ?? '').toString().toLowerCase();
                    final cat = (c['category'] ?? (role.contains('cricket') ? 'Cricket' : role.contains('fitness') ? 'Fitness' : role.contains('tennis') || role.contains('badminton') ? 'Racquet' : 'Football')).toString();
                    
                    final matchesSearch = name.contains(searchQuery.toLowerCase()) || role.contains(searchQuery.toLowerCase());
                    final matchesCategory = selectedCategory == 'All' || cat.toLowerCase() == selectedCategory.toLowerCase();
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No coaches found matching "$searchQuery"', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final coach = filtered[index];
                      final name = coach['full_name'] ?? coach['name'] ?? 'Coach';
                      final role = coach['role'] ?? 'Specialist Coach';
                      final rating = coach['rating']?.toString() ?? '4.8';
                      final price = coach['price_per_session'] != null
                          ? '₹${(coach['price_per_session'] as num).toInt()}/session'
                          : (coach['price'] ?? '₹1,200/session');
                      final avatar = coach['image_url'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100';
                      final exp = coach['experience'] ?? 'Certified Professional Coach';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(avatar),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                      ),
                                      Text(
                                        role,
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating,
                                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  price,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(exp, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton(
                                onPressed: () => _showBookingModal(coach),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  'Book a Session',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
