import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

final fetchRentalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get('/rentals/');
  return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

class EquipmentRentalScreen extends ConsumerStatefulWidget {
  const EquipmentRentalScreen({super.key});

  @override
  ConsumerState<EquipmentRentalScreen> createState() => _EquipmentRentalScreenState();
}

class _EquipmentRentalScreenState extends ConsumerState<EquipmentRentalScreen> {
  String _searchQuery = '';
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    try {
      _wsSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
        if (mounted) {
          ref.invalidate(fetchRentalsProvider);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  IconData _getIconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ball')) return Icons.sports_soccer;
    if (lower.contains('glove')) return Icons.front_hand;
    if (lower.contains('shoe') || lower.contains('boot')) return Icons.roller_skating;
    if (lower.contains('bib') || lower.contains('jersey')) return Icons.checkroom;
    if (lower.contains('bat') || lower.contains('cricket')) return Icons.sports_cricket;
    if (lower.contains('racket') || lower.contains('badminton')) return Icons.sports_tennis;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final rentalsAsync = ref.watch(fetchRentalsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Equipment Rental',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  fillColor: AppTheme.cardDark,
                ),
              ),
            ),
            Expanded(
              child: rentalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (err, stack) => Center(
                  child: Text('Failed to load rentals: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                ),
                data: (items) {
                  final filtered = items.where((i) {
                    final name = (i['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No rental equipment available.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final name = item['name']?.toString() ?? 'Equipment';
                      final price = item['price_per_day'] != null
                          ? '₹${(item['price_per_day'] as num).toInt()}/day'
                          : '₹100/day';
                      final icon = _getIconForName(name);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: AppTheme.primaryGreen, size: 36),
                            ),
                            Column(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  price,
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  try {
                                    ref.read(realtimeServiceProvider).emit('booking_requests', {
                                      'type': 'rental_booked',
                                      'name': name,
                                      'price': price,
                                      'sport': 'Equipment Rental',
                                      'status': 'confirmed',
                                      'timestamp': DateTime.now().toIso8601String(),
                                    });
                                    ref.read(realtimeServiceProvider).emit('booking_updates', {
                                      'type': 'rental_booked',
                                      'name': name,
                                      'timestamp': DateTime.now().toIso8601String(),
                                    });
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$name booked for rent at $price!'),
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Rent Now',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
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
