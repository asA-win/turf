import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TeamRankingScreen extends StatefulWidget {
  const TeamRankingScreen({super.key});

  @override
  State<TeamRankingScreen> createState() => _TeamRankingScreenState();
}

class _TeamRankingScreenState extends State<TeamRankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> standings = [
    {'rank': '1', 'team': 'Blasters FC', 'pts': '1820'},
    {'rank': '2', 'team': 'Warriors United', 'pts': '1680'},
    {'rank': '3', 'team': 'Titans FC', 'pts': '1560', 'isUser': true},
    {'rank': '4', 'team': 'Strikers United', 'pts': '1420'},
    {'rank': '5', 'team': 'Kings XI', 'pts': '1280'},
    {'rank': '6', 'team': 'Thunderbolts', 'pts': '1100'},
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
        title: const Text('Team Ranking'),
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
            Tab(text: 'Local'),
            Tab(text: 'Regional'),
            Tab(text: 'National'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.2), shape: BoxShape.circle),
                    child: Center(
                      child: Text('#3', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Titans FC', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      Text('1560 Points • Elite Division', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: standings.length,
                itemBuilder: (context, index) {
                  final s = standings[index];
                  final isUser = s['isUser'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isUser ? AppTheme.primaryGreen : AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 30,
                        child: Text(s['rank']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isUser ? AppTheme.primaryGreen : Colors.white, fontSize: 14)),
                      ),
                      title: Text(s['team']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      trailing: Text('${s['pts']!} pts', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Ranking updates every Monday ℹ️', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
