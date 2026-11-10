import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _bookingSub;
  StreamSubscription<Map<String, dynamic>>? _scoreboardSub;

  final List<Map<String, dynamic>> _notifications = [
    {
      'category': 'Booking',
      'title': 'Booking Confirmed',
      'body': 'Your booking at Green Field Arena on 18 May 2025, 7:00 PM is confirmed.',
      'time': '10:30 AM',
      'isToday': true,
      'unread': true,
      'icon': Icons.calendar_today,
    },
    {
      'category': 'Match',
      'title': 'Match Reminder',
      'body': 'You have a match today at Goal Diggers ground at 7:00 PM.',
      'time': '08:15 AM',
      'isToday': true,
      'unread': true,
      'icon': Icons.sports_soccer,
    },
    {
      'category': 'Offer',
      'title': 'Special Offer',
      'body': 'Get 20% off on your next booking. Use code: BYS20',
      'time': '08:45 AM',
      'isToday': true,
      'unread': false,
      'icon': Icons.local_offer,
    },
    {
      'category': 'Booking',
      'title': 'Payment Successful',
      'body': 'Payment of ₹1200 for booking was successful.',
      'time': '07:30 PM',
      'isToday': false,
      'unread': false,
      'icon': Icons.payment,
    },
    {
      'category': 'Booking',
      'title': 'Review Request',
      'body': 'How was your experience at Kick Off Turf?',
      'time': '06:20 PM',
      'isToday': false,
      'unread': false,
      'icon': Icons.rate_review,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _bookingSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((event) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, {
            'category': 'Booking',
            'title': '⚡ Live Booking Update',
            'body': 'Your booking was updated live in the system.',
            'time': 'Just now',
            'isToday': true,
            'unread': true,
            'icon': Icons.bolt,
          });
        });
      }
    });

    _scoreboardSub = ref.read(realtimeServiceProvider).connectToChannel('scoreboard').listen((event) {
      final type = event['type'] as String?;
      if (type == 'score_update') {
        final teamA = event['teamA'] ?? 'Team A';
        final teamB = event['teamB'] ?? 'Team B';
        final scoreA = event['scoreA'] ?? '0';
        final scoreB = event['scoreB'] ?? '0';
        final ev = event['event'] as String? ?? 'Score updated';

        if (mounted) {
          setState(() {
            _notifications.insert(0, {
              'category': 'Match',
              'title': '⚽ Live Match Update: $teamA vs $teamB',
              'body': '$ev (Score: $scoreA - $scoreB)',
              'time': 'Just now',
              'isToday': true,
              'unread': true,
              'icon': Icons.sports_soccer,
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _scoreboardSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Bookings'),
            Tab(text: 'Matches'),
            Tab(text: 'Offers'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationList(),
            _buildNotificationList(filterCategory: 'Booking'),
            _buildNotificationList(filterCategory: 'Match'),
            _buildNotificationList(filterCategory: 'Offer'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList({String? filterCategory}) {
    final filtered = filterCategory == null
        ? _notifications
        : _notifications.where((n) => n['category'] == filterCategory).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final unread = item['unread'] as bool;
        final isJustNow = item['time'] == 'Just now';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isJustNow
                  ? AppTheme.primaryGreen
                  : (unread ? AppTheme.primaryGreen.withValues(alpha: 0.3) : AppTheme.cardBorder),
              width: isJustNow ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isJustNow
                  ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                  : (unread ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.surfaceDark),
              child: Icon(
                item['icon'] as IconData,
                color: isJustNow || unread ? AppTheme.primaryGreen : AppTheme.textGrey,
                size: 20,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['title'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                      color: unread ? AppTheme.textWhite : AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  item['time'] as String,
                  style: GoogleFonts.poppins(
                    color: isJustNow ? AppTheme.primaryGreen : AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: isJustNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                item['body'] as String,
                style: GoogleFonts.poppins(
                  color: AppTheme.textGrey,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                item['unread'] = false;
              });
            },
          ),
        );
      },
    );
  }
}
