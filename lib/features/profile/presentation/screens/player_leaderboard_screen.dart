import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PlayerLeaderboardScreen extends StatefulWidget {
  const PlayerLeaderboardScreen({super.key});

  @override
  State<PlayerLeaderboardScreen> createState() => _PlayerLeaderboardScreenState();
}

class _PlayerLeaderboardScreenState extends State<PlayerLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ranked = [
    {'rank': '4', 'name': 'Karthik M', 'xp': '1,800 XP'},
    {'rank': '5', 'name': 'Sandeep Kumar', 'xp': '1,650 XP'},
    {'rank': '6', 'name': 'Manoj George', 'xp': '1,520 XP'},
    {'rank': '7', 'name': 'Praveen N', 'xp': '1,400 XP'},
    {'rank': '8', 'name': 'Santhosh R', 'xp': '1,250 XP'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Leaderboard'),
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
            Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _podiumItem('2', 'Vignesh K', '2,150 XP', 70, const Color(0xFFC0C0C0)),
                  _podiumItem('1', 'Rahul Sharma', '2,450 XP', 90, Colors.amber, isCrown: true),
                  _podiumItem('3', 'Arun Prasad', '1,950 XP', 60, Colors.brown),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: ranked.length,
                itemBuilder: (context, index) {
                  final r = ranked[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 24,
                        child: Text(r['rank']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                      ),
                      title: Text(r['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: Text(r['xp']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(String rank, String name, String xp, double height, Color color, {bool isCrown = false}) {
    return Column(
      children: [
        if (isCrown) const Text('👑', style: TextStyle(fontSize: 20)),
        CircleAvatar(
          radius: isCrown ? 28 : 22,
          backgroundColor: color.withValues(alpha: 0.3),
          child: Text(name[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 6),
        Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isCrown ? 13 : 11)),
        Text(xp, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text('#$rank', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}
