import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TeamScheduleScreen extends StatefulWidget {
  const TeamScheduleScreen({super.key});

  @override
  State<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends State<TeamScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final fixtures = [
    {'time': 'Tomorrow • 7:00 PM', 'teamA': 'Titans FC', 'teamB': 'Strikers United', 'venue': 'Green Field Arena'},
    {'time': '25 May • 8:30 PM', 'teamA': 'Titans FC', 'teamB': 'Victory Turf', 'venue': 'Victory Turf'},
    {'time': '01 Jun • 6:00 PM', 'teamA': 'Thunderbolts', 'teamB': 'Titans FC', 'venue': 'Play Arena'},
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
        title: const Text('Team Schedule'),
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
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: fixtures.length,
                itemBuilder: (context, index) {
                  final f = fixtures[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Text(f['time']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(f['teamA']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('VS', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(f['teamB']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, color: AppTheme.textGrey, size: 12),
                            const SizedBox(width: 4),
                            Text(f['venue']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                          ],
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
                onPressed: () => context.pop(),
                child: const Text('View Full Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
