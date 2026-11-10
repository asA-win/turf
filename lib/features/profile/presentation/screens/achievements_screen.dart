import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final achievements = [
    {'title': 'Hat-trick Hero', 'desc': 'Scored 3 goals in a match', 'date': '12 May 2025', 'icon': Icons.sports_soccer},
    {'title': 'Top Scorer', 'desc': 'Scored 10 goals in a season', 'date': '28 Apr 2025', 'icon': Icons.emoji_events},
    {'title': 'Winning Streak', 'desc': 'Won 5 matches in a row', 'date': '15 Apr 2025', 'icon': Icons.local_fire_department},
    {'title': 'Playmaker', 'desc': 'Provided 5 assists in a match', 'date': '02 Apr 2025', 'icon': Icons.stars},
    {'title': 'Iron Man', 'desc': 'Played 10 matches in a month', 'date': '20 Mar 2025', 'icon': Icons.shield},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Achievements'),
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
                children: const [
                  _StatNum(val: '12', label: 'Achievements'),
                  _StatNum(val: '5', label: 'Trophies'),
                  _StatNum(val: '320', label: 'Points'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final a = achievements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGreen),
                        ),
                        child: Icon(a['icon'] as IconData, color: AppTheme.primaryGreen, size: 22),
                      ),
                      title: Text(a['title'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['desc'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          Text(a['date'] as String, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
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
