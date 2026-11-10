import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final txns = [
    {'title': 'Booking - Green Field Arena', 'date': '18 May 2025, 7:00 PM', 'amount': '- ₹2316', 'type': 'debit'},
    {'title': 'Added Money (UPI)', 'date': '18 May 2025, 09:15 AM', 'amount': '+ ₹2000', 'type': 'credit'},
    {'title': 'Refund - Play Arena', 'date': '17 May 2025, 08:20 PM', 'amount': '+ ₹920', 'type': 'credit'},
    {'title': 'Booking - Champions Turf', 'date': '17 May 2025, 06:45 PM', 'amount': '- ₹1760', 'type': 'debit'},
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
        title: const Text('Transactions'),
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
            Tab(text: 'Credits'),
            Tab(text: 'Debits'),
            Tab(text: 'Refunds'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: txns.length,
          itemBuilder: (context, index) {
            final t = txns[index];
            final isCredit = t['type'] == 'credit';
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
                  ),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? AppTheme.primaryGreen : AppTheme.errorRed,
                    size: 20,
                  ),
                ),
                title: Text(t['title']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(t['date']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                trailing: Text(
                  t['amount']!,
                  style: GoogleFonts.poppins(
                    color: isCredit ? AppTheme.primaryGreen : AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
