import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final badges = [
    {'title': 'Top Scorer', 'tier': 'Gold', 'icon': Icons.workspace_premium, 'color': Colors.amber},
    {'title': 'Playmaker', 'tier': 'Silver', 'icon': Icons.military_tech, 'color': Colors.grey},
    {'title': 'Speedster', 'tier': 'Silver', 'icon': Icons.bolt, 'color': Colors.grey},
    {'title': 'Defender', 'tier': 'Bronze', 'icon': Icons.shield, 'color': Colors.brown},
    {'title': 'Finisher', 'tier': 'Silver', 'icon': Icons.sports_soccer, 'color': Colors.grey},
    {'title': 'Captain', 'tier': 'Gold', 'icon': Icons.stars, 'color': Colors.amber},
    {'title': 'Consistent', 'tier': 'Bronze', 'icon': Icons.verified, 'color': Colors.brown},
    {'title': 'Rising Star', 'tier': 'Silver', 'icon': Icons.auto_awesome, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Badges'),
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
            Tab(text: 'Rare'),
            Tab(text: 'Performance'),
            Tab(text: 'Special'),
          ],
        ),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final b = badges[index];
            final color = b['color'] as Color;
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(b['icon'] as IconData, color: color, size: 40),
                  const SizedBox(height: 8),
                  Text(b['title'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(b['tier'] as String, style: GoogleFonts.poppins(color: color, fontSize: 11)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
