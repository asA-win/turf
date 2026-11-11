import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/wallet/presentation/controllers/wallet_provider.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    try {
      _wsSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
        if (mounted) {
          ref.invalidate(fetchMyBookingsProvider);
          ref.invalidate(fetchUserProfileProvider);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fetchUserProfileProvider);
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);
    final wallet = ref.watch(walletProvider);

    final bookings = bookingsAsync.valueOrNull ?? [];
    final bookingsCount = bookings.length;
    final hasWeekendBooking = bookings.any((b) => b.bookingDate.weekday == DateTime.saturday || b.bookingDate.weekday == DateTime.sunday);
    final hasNightBooking = bookings.any((b) => b.bookingDate.hour >= 20);

    final allBadges = [
      {
        'title': 'Verified Player',
        'tier': 'Gold',
        'category': 'Special',
        'icon': Icons.verified_user_rounded,
        'color': Colors.amber,
        'unlocked': true,
        'progress': 'Earned',
      },
      {
        'title': 'First Touch',
        'tier': 'Bronze',
        'category': 'Performance',
        'icon': Icons.sports_soccer_rounded,
        'color': const Color(0xFFCD7F32),
        'unlocked': bookingsCount >= 1,
        'progress': bookingsCount >= 1 ? 'Earned' : '0/1 Match',
      },
      {
        'title': 'Hat-trick Booker',
        'tier': 'Silver',
        'category': 'Performance',
        'icon': Icons.local_fire_department_rounded,
        'color': Colors.grey.shade300,
        'unlocked': bookingsCount >= 3,
        'progress': bookingsCount >= 3 ? 'Earned' : '$bookingsCount/3 Matches',
      },
      {
        'title': 'Weekend Warrior',
        'tier': 'Silver',
        'category': 'Rare',
        'icon': Icons.wb_sunny_rounded,
        'color': Colors.grey.shade300,
        'unlocked': hasWeekendBooking,
        'progress': hasWeekendBooking ? 'Earned' : 'Weekend Match Needed',
      },
      {
        'title': 'Night Owl',
        'tier': 'Rare',
        'category': 'Rare',
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFF00E5FF),
        'unlocked': hasNightBooking,
        'progress': hasNightBooking ? 'Earned' : 'Play after 8 PM',
      },
      {
        'title': 'Turf Captain',
        'tier': 'Gold',
        'category': 'Special',
        'icon': Icons.stars_rounded,
        'color': Colors.amber,
        'unlocked': bookingsCount >= 5,
        'progress': bookingsCount >= 5 ? 'Earned' : '$bookingsCount/5 Matches',
      },
      {
        'title': 'Coin Champion',
        'tier': 'Gold',
        'category': 'Special',
        'icon': Icons.monetization_on_rounded,
        'color': Colors.amber,
        'unlocked': wallet.coins >= 50,
        'progress': wallet.coins >= 50 ? 'Earned' : '${wallet.coins}/50 Coins',
      },
      {
        'title': 'Arena Master',
        'tier': 'Diamond',
        'category': 'Rare',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xFF00E676),
        'unlocked': bookingsCount >= 10,
        'progress': bookingsCount >= 10 ? 'Earned' : '$bookingsCount/10 Matches',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('Badges & Honors', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Rare'),
            Tab(text: 'Performance'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBadgeGrid(allBadges),
            _buildBadgeGrid(allBadges.where((b) => b['category'] == 'Rare').toList()),
            _buildBadgeGrid(allBadges.where((b) => b['category'] == 'Performance').toList()),
            _buildBadgeGrid(allBadges.where((b) => b['category'] == 'Special').toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No badges found in this category', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.05,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        final isUnlocked = b['unlocked'] == true;
        final color = isUnlocked ? (b['color'] as Color) : Colors.white24;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked ? color.withValues(alpha: 0.6) : AppTheme.cardBorder,
              width: isUnlocked ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(b['icon'] as IconData, color: color, size: 38),
              const SizedBox(height: 8),
              Text(
                b['title'] as String,
                style: GoogleFonts.poppins(
                  color: isUnlocked ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                b['tier'] as String,
                style: GoogleFonts.poppins(
                  color: isUnlocked ? color : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  b['progress'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? AppTheme.primaryGreen : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
