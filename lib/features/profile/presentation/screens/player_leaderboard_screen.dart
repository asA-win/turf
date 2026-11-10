import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/booking/data/repositories/booking_repository.dart';
import 'package:turf_app/features/wallet/presentation/controllers/wallet_provider.dart';

class PlayerLeaderboardScreen extends ConsumerStatefulWidget {
  const PlayerLeaderboardScreen({super.key});

  @override
  ConsumerState<PlayerLeaderboardScreen> createState() => _PlayerLeaderboardScreenState();
}

class _PlayerLeaderboardScreenState extends ConsumerState<PlayerLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(fetchUserProfileProvider);
    final bookingsAsync = ref.watch(fetchMyBookingsProvider);
    final wallet = ref.watch(walletProvider);

    final user = userAsync.valueOrNull;
    final userName = user?.fullName?.trim().isNotEmpty == true ? user!.fullName!.trim() : 'You';
    final bookings = bookingsAsync.valueOrNull ?? [];
    final userXp = (bookings.length * 150) + wallet.coins;

    final List<Map<String, dynamic>> players = [
      {'name': 'Vikram Rathore', 'xp': 2850, 'isUser': false},
      {'name': 'Aditya Verma', 'xp': 2450, 'isUser': false},
      {'name': 'Sameer Khan', 'xp': 2100, 'isUser': false},
      {'name': 'Rohan Nair', 'xp': 1850, 'isUser': false},
      {'name': 'Karthik Menon', 'xp': 1620, 'isUser': false},
      {'name': 'Farhan Qureshi', 'xp': 1400, 'isUser': false},
      {'name': userName, 'xp': userXp, 'isUser': true},
    ];

    players.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    for (int i = 0; i < players.length; i++) {
      players[i]['rank'] = '${i + 1}';
    }

    final top3 = players.take(3).toList();
    final remaining = players.skip(3).toList();
    final userRankIdx = players.indexWhere((p) => p['isUser'] == true);
    final userRank = userRankIdx != -1 ? players[userRankIdx]['rank'] : '1';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
            Tab(text: 'Top Players'),
            Tab(text: 'Top Scorers'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top 3 Podium
            if (top3.length >= 3)
              Container(
                color: AppTheme.surfaceDark,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _podiumItem('2', top3[1]['name'], '${top3[1]['xp']} XP', 70, const Color(0xFFC0C0C0), top3[1]['isUser'] == true),
                    _podiumItem('1', top3[0]['name'], '${top3[0]['xp']} XP', 92, Colors.amber, top3[0]['isUser'] == true, isCrown: true),
                    _podiumItem('3', top3[2]['name'], '${top3[2]['xp']} XP', 60, const Color(0xFFCD7F32), top3[2]['isUser'] == true),
                  ],
                ),
              ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: remaining.length,
                itemBuilder: (context, index) {
                  final r = remaining[index];
                  final isUser = r['isUser'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser ? AppTheme.primaryGreen : AppTheme.cardBorder,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text(
                          r['rank']!,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: isUser ? AppTheme.primaryGreen : AppTheme.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            r['name']!,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: isUser ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'YOU',
                                style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        '${r['xp']} XP',
                        style: GoogleFonts.poppins(
                          color: isUser ? AppTheme.primaryGreen : AppTheme.textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Persistent "Your Standing" Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF132B1A),
                border: Border(top: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.4))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: AppTheme.primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Current Standing', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                        Text('Rank #$userRank • $userName', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                  Text(
                    '$userXp XP',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(String rank, String name, String xp, double height, Color color, bool isUser, {bool isCrown = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrown)
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22)
        else
          const SizedBox(height: 22),
        const SizedBox(height: 4),
        Container(
          width: 80,
          alignment: Alignment.center,
          child: Text(
            name,
            style: GoogleFonts.poppins(
              color: isUser ? AppTheme.primaryGreen : Colors.white,
              fontSize: 11,
              fontWeight: isUser ? FontWeight.bold : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Text(xp, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          width: 64,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              rank,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    );
  }
}
