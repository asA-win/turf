import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({super.key});

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final referrals = [
    {'name': 'Vignesh K', 'date': 'Joined on 18 May 2025', 'reward': '+100 Coins'},
    {'name': 'Arun Prasad', 'date': 'Joined on 17 May 2025', 'reward': '+100 Coins'},
    {'name': 'Karthik M', 'date': 'Joined on 16 May 2025', 'reward': '+100 Coins'},
    {'name': 'Sandeep Kumar', 'date': 'Joined on 15 May 2025', 'reward': '+100 Coins'},
    {'name': 'Manoj George', 'date': 'Joined on 15 May 2025', 'reward': '+100 Coins'},
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
        title: const Text('Referral History'),
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
            Tab(text: 'Successful'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatCol(title: 'Friends Joined', val: '24'),
                  _StatCol(title: 'Total Earned', val: '₹3,450'),
                  _StatCol(title: 'BYS Coins', val: '1,250'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: referrals.length,
                itemBuilder: (context, index) {
                  final r = referrals[index];
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
                        child: Text(r['name']![0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(r['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(r['date']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      trailing: Text(r['reward']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/referral'),
                child: const Text('Invite More Friends'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String title;
  final String val;
  const _StatCol({required this.title, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
