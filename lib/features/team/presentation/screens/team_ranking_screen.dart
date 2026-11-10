import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/team/presentation/screens/team_dashboard_screen.dart';

class TeamRankingScreen extends ConsumerStatefulWidget {
  const TeamRankingScreen({super.key});

  @override
  ConsumerState<TeamRankingScreen> createState() => _TeamRankingScreenState();
}

class _TeamRankingScreenState extends ConsumerState<TeamRankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(fetchTeamsProvider);

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
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load rankings: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (teams) {
            final standings = teams.isNotEmpty
                ? teams.map((t) => {
                      'rank': '${t['rank'] ?? 1}',
                      'team': '${t['name'] ?? 'Team'}',
                      'pts': '${((t['wins'] as num? ?? 0) * 30 + 1000)}',
                      'isUser': true,
                    }).toList()
                : [
                    {'rank': '1', 'team': 'Turf Titans', 'pts': '1820', 'isUser': true},
                  ];

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: standings.length,
                    itemBuilder: (context, index) {
                      final item = standings[index];
                      final isUser = item['isUser'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primaryGreen.withOpacity(0.12) : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUser ? AppTheme.primaryGreen : AppTheme.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '#${item['rank']}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: isUser ? AppTheme.primaryGreen : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['team'] as String,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              '${item['pts']} pts',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
