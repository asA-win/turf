import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PlayerPerformanceScreen extends StatefulWidget {
  final String matchId;
  const PlayerPerformanceScreen({super.key, required this.matchId});

  @override
  State<PlayerPerformanceScreen> createState() => _PlayerPerformanceScreenState();
}

class _PlayerPerformanceScreenState extends State<PlayerPerformanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final players = [
    {'name': 'Rahul Sharma', 'goals': '1', 'assists': '1', 'rating': '8.7'},
    {'name': 'Vignesh K', 'goals': '1', 'assists': '0', 'rating': '8.1'},
    {'name': 'Arun Prasad', 'goals': '0', 'assists': '1', 'rating': '7.8'},
    {'name': 'Karthik M', 'goals': '0', 'assists': '0', 'rating': '7.2'},
    {'name': 'Manoj George', 'goals': '0', 'assists': '0', 'rating': '6.9'},
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
        title: const Text('Player Performance'),
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
            Tab(text: 'Turf Titans'),
            Tab(text: 'Goal Diggers'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Player', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Goals', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Assists', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Rating', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final p = players[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(p['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(p['goals']!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(p['assists']!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('★ ${p['rating']}', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/stats', extra: <String, dynamic>{
                  'sport': 'Football',
                  'teamA': 'Turf Titans',
                  'teamB': 'Goal Diggers',
                  'scoreDisplay': '2 - 1',
                  'result': '🏆 Turf Titans Won 2-1',
                  'mvp': 'Rahul Sharma (Rating: 8.7)',
                }),
                child: const Text('View Full Statistics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
