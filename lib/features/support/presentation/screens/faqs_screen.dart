import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final faqs = [
    {'q': 'How do I book a turf?', 'a': 'Select your desired turf, pick a date and time slot, select players/extras, and proceed to payment.'},
    {'q': 'How do I cancel a booking?', 'a': 'Go to My Bookings, tap on the booking you want to cancel, and select Cancel Booking.'},
    {'q': 'How do I get a refund?', 'a': 'Refunds are processed automatically to your wallet or original payment method based on our cancellation policy.'},
    {'q': 'What payment methods are accepted?', 'a': 'We accept UPI, Credit/Debit Cards, Net Banking, BYS Wallet, and Pay Later options.'},
    {'q': 'How do I join a match?', 'a': 'Navigate to Join Match tab, browse upcoming public matches, select one, and pay your player fee.'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('FAQs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Booking'),
            Tab(text: 'Payment'),
            Tab(text: 'Account'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search frequently asked questions...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final item = faqs[index];
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    iconColor: AppTheme.primaryGreen,
                    collapsedIconColor: AppTheme.textGrey,
                    title: Text(item['q']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(item['a']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Still have questions?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () => context.push('/support-center'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(110, 36)),
                    child: const Text('Chat Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
