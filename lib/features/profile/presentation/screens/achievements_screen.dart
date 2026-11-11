import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/wallet/presentation/controllers/wallet_provider.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final nowFormatted = DateFormat('dd MMM yyyy').format(DateTime.now());

    final List<Map<String, dynamic>> dynamicAchievements = [
      {
        'title': 'Certified Athlete',
        'desc': 'Registered verified account on Turf App',
        'date': nowFormatted,
        'icon': Icons.verified_user_rounded,
        'unlocked': true,
        'category': 'Milestones',
        'progress': 'Completed',
      },
      {
        'title': 'First Kick-off',
        'desc': 'Booked your first verified turf slot',
        'date': bookings.isNotEmpty
            ? DateFormat('dd MMM yyyy').format(bookings.first.bookingDate)
            : '0 / 1 Bookings',
        'icon': Icons.sports_soccer_rounded,
        'unlocked': bookingsCount >= 1,
        'category': 'Trophies',
        'progress': bookingsCount >= 1 ? 'Unlocked' : '0/1',
      },
      {
        'title': 'Turf Regular',
        'desc': 'Completed 3 certified matches on turf venues',
        'date': bookingsCount >= 3 ? nowFormatted : '$bookingsCount / 3 Matches',
        'icon': Icons.local_fire_department_rounded,
        'unlocked': bookingsCount >= 3,
        'category': 'Trophies',
        'progress': bookingsCount >= 3 ? 'Unlocked' : '$bookingsCount/3',
      },
      {
        'title': 'Arena Veteran',
        'desc': 'Completed 10 matches on turf venues',
        'date': bookingsCount >= 10 ? nowFormatted : '$bookingsCount / 10 Matches',
        'icon': Icons.military_tech_rounded,
        'unlocked': bookingsCount >= 10,
        'category': 'Trophies',
        'progress': bookingsCount >= 10 ? 'Unlocked' : '$bookingsCount/10',
      },
      {
        'title': 'Smart Wallet Player',
        'desc': 'Added balance or earned cash rewards in Turf Wallet',
        'date': wallet.balance > 0 ? 'Active (₹${wallet.balance.toStringAsFixed(2)})' : 'Add funds to unlock',
        'icon': Icons.account_balance_wallet_rounded,
        'unlocked': wallet.balance > 0,
        'category': 'Milestones',
        'progress': wallet.balance > 0 ? 'Unlocked' : '0/1',
      },
      {
        'title': 'Coin Collector',
        'desc': 'Accumulate 50 Turf Reward Coins',
        'date': wallet.coins >= 50 ? 'Claimed (${wallet.coins} Coins)' : '${wallet.coins} / 50 Coins',
        'icon': Icons.monetization_on_rounded,
        'unlocked': wallet.coins >= 50,
        'category': 'Milestones',
        'progress': wallet.coins >= 50 ? 'Unlocked' : '${wallet.coins}/50',
      },
      {
        'title': 'Fair Play Legend',
        'desc': 'Maintained 100% attendance on all confirmed bookings',
        'date': bookingsCount > 0 ? 'Active Honor' : 'Book a match to earn',
        'icon': Icons.shield_rounded,
        'unlocked': bookingsCount > 0,
        'category': 'Trophies',
        'progress': bookingsCount > 0 ? 'Honor Active' : 'Locked',
      },
    ];

    final unlockedCount = dynamicAchievements.where((a) => a['unlocked'] == true).length;
    final trophiesCount = dynamicAchievements.where((a) => a['unlocked'] == true && a['category'] == 'Trophies').length;
    final points = (unlockedCount * 100) + wallet.coins;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('Achievements', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
            Tab(text: 'Trophies'),
            Tab(text: 'Milestones'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatNum(val: '$unlockedCount/${dynamicAchievements.length}', label: 'Achievements'),
                  _StatNum(val: '$trophiesCount', label: 'Trophies'),
                  _StatNum(val: '$points', label: 'XP Points'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(dynamicAchievements),
                  _buildList(dynamicAchievements.where((a) => a['category'] == 'Trophies').toList()),
                  _buildList(dynamicAchievements.where((a) => a['category'] == 'Milestones').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('No achievements found', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final a = items[index];
        final isUnlocked = a['unlocked'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnlocked ? AppTheme.primaryGreen.withValues(alpha: 0.4) : AppTheme.cardBorder,
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: isUnlocked ? AppTheme.primaryGreen : Colors.white24),
              ),
              child: Icon(
                a['icon'] as IconData,
                color: isUnlocked ? AppTheme.primaryGreen : Colors.white38,
                size: 22,
              ),
            ),
            title: Text(
              a['title'] as String,
              style: GoogleFonts.poppins(
                color: isUnlocked ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(a['desc'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  a['date'] as String,
                  style: GoogleFonts.poppins(
                    color: isUnlocked ? AppTheme.primaryGreen : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                a['progress'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppTheme.primaryGreen : Colors.white38,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatNum extends StatelessWidget {
  final String val;
  final String label;
  const _StatNum({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
