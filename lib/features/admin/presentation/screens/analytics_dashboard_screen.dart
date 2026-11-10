import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
      if (mounted) {
        ref.invalidate(fetchTurfStatsProvider);
        ref.invalidate(fetchTurfsProvider(null, null));
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(fetchTurfStatsProvider);
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Live Analytics Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(fetchTurfStatsProvider);
              ref.invalidate(fetchTurfsProvider(null, null));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Live Real-Time Metrics', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Icon(Icons.circle, color: AppTheme.primaryGreen, size: 10),
                ],
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Failed to load live metrics: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                ),
                data: (stats) {
                  final totalBookings = stats['total_bookings']?.toString() ?? '0';
                  final totalRev = stats['total_revenue'] != null
                      ? '₹${(stats['total_revenue'] as num).toInt()}'
                      : '₹0';
                  final todayBookings = stats['today_bookings']?.toString() ?? '0';
                  final occupancy = stats['occupancy_rate'] != null
                      ? '${(stats['occupancy_rate'] as num).toStringAsFixed(1)}%'
                      : '0.0%';

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _MetricCard('Total Bookings', totalBookings, 'Live Database', AppTheme.primaryGreen),
                      _MetricCard('Total Revenue', totalRev, 'Confirmed Payments', AppTheme.primaryGreen),
                      _MetricCard('Today\'s Bookings', todayBookings, 'Active Today', AppTheme.primaryGreen),
                      _MetricCard('Occupancy Rate', occupancy, 'Dynamic Slots', AppTheme.primaryGreen),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Live Venues', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              turfsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (err, stack) => Text('Failed to load venues: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                data: (turfs) {
                  if (turfs.isEmpty) {
                    return Text('No venues registered yet.', style: GoogleFonts.poppins(color: AppTheme.textGrey));
                  }
                  return Column(
                    children: turfs.asMap().entries.map((entry) {
                      final rank = '${entry.key + 1}';
                      final turf = entry.value;
                      return _venueRank(rank, turf.name, '${turf.location} • ₹${turf.pricePerHour.toInt()}/hr');
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _venueRank(String rank, String name, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Text(rank, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String val;
  final String growth;
  final Color color;
  const _MetricCard(this.title, this.val, this.growth, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(growth, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
