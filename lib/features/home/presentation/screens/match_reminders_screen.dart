import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class MatchRemindersScreen extends StatefulWidget {
  const MatchRemindersScreen({super.key});

  @override
  State<MatchRemindersScreen> createState() => _MatchRemindersScreenState();
}

class _MatchRemindersScreenState extends State<MatchRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Match Reminders'),
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
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: Column(
                  children: [
                    Text('Tomorrow • 7:00 PM', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                    Text('Green Field Arena', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Titans FC', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        Text('Strikers United', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('26 : 18 : 45', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, letterSpacing: 2)),
                    Text('HRS  MINS  SECS', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set!')));
                      },
                      icon: const Icon(Icons.alarm, color: Colors.black),
                      label: const Text('Set Reminder'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.push('/add-to-calendar'),
                icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
                label: Text('Add Custom Reminder', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
