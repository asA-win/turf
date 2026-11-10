import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final members = [
    {'name': 'Rahul Sharma', 'role': 'Forward', 'rating': '8.7', 'cap': 'C'},
    {'name': 'Vignesh K', 'role': 'Midfielder', 'rating': '8.1', 'cap': 'VC'},
    {'name': 'Arun Prasad', 'role': 'Defender', 'rating': '7.8', 'cap': ''},
    {'name': 'Karthik M', 'role': 'Midfielder', 'rating': '7.2', 'cap': ''},
    {'name': 'Manoj George', 'role': 'Defender', 'rating': '6.9', 'cap': ''},
    {'name': 'Vikram Nair', 'role': 'Goalkeeper', 'rating': '7.6', 'cap': ''},
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
        title: const Text('Team Members'),
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
            Tab(text: 'All (10)'),
            Tab(text: 'Players (9)'),
            Tab(text: 'Staff (1)'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final m = members[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.surfaceDark,
                        child: Text(m['name']![0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Row(
                        children: [
                          Text(m['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          if (m['cap']!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(m['cap']!, style: GoogleFonts.poppins(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(m['role']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(m['rating']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/invite-members'),
                icon: const Icon(Icons.person_add, color: Colors.black),
                label: const Text('Invite Members'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
