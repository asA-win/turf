import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final matches = [
    {'fixture': 'Green Field Arena', 'date': '18 May • 7:00 PM', 'score': '2 - 1', 'result': 'Won', 'color': Colors.green},
    {'fixture': 'Play Arena', 'date': '15 May • 8:00 PM', 'score': '3 - 2', 'result': 'Won', 'color': Colors.green},
    {'fixture': 'Kick Off Turf', 'date': '12 May • 9:00 PM', 'score': '1 - 1', 'result': 'Draw', 'color': Colors.orange},
    {'fixture': 'Champions Turf', 'date': '9 May • 7:00 PM', 'score': '0 - 2', 'result': 'Lost', 'color': Colors.red},
    {'fixture': 'Victory Turf', 'date': '6 May • 8:00 PM', 'score': '4 - 1', 'result': 'Won', 'color': Colors.green},
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
        title: const Text('Match History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Match Stats & Top Scorers',
            onPressed: () => context.push('/stats'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Hosted'),
            Tab(text: 'Joined'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('May 2025', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final m = matches[index];
                  final color = m['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () => context.push('/match-summary/1'),
                      title: Text(m['fixture'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      subtitle: Text(m['date'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m['score'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m['result'] as String, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 18),
                            tooltip: 'Match Stats',
                            onPressed: () {
                              context.push('/stats', extra: <String, dynamic>{
                                'sport': 'Football',
                                'turfName': m['fixture'],
                                'scoreDisplay': m['score'],
                                'result': '🏆 ${m['result']}',
                              });
                            },
                          ),
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
