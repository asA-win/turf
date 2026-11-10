import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class OffersPromotionsScreen extends StatefulWidget {
  const OffersPromotionsScreen({super.key});

  @override
  State<OffersPromotionsScreen> createState() => _OffersPromotionsScreenState();
}

class _OffersPromotionsScreenState extends State<OffersPromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        title: const Text('Offers & Promotions'),
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
            Tab(text: 'All Offers'),
            Tab(text: 'Discounts'),
            Tab(text: 'Cashback'),
            Tab(text: 'Deals'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mega Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MEGA WEEKEND OFFER', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Get up to 25% OFF', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('On all turf bookings • Code: WEEKEND25', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.sports_soccer, size: 64, color: Colors.white38),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _promoCard('FLAT 15% OFF', 'On your first booking', 'FIRST15', 'Valid till 31 May 2025', '15% OFF'),
              _promoCard('CASHBACK OFFER', 'Get 10% cashback on min ₹800', 'CASH10', 'Valid till 25 May 2025', '10% CASHBACK'),
              _promoCard('EARLY BIRD OFFER', 'Book 2 days in advance & get 20% OFF', 'EARLY20', 'Valid till 30 May 2025', '20% OFF'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promoCard(String title, String desc, String code, String validity, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                Text(desc, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: Text('Use Code: $code', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Text(validity, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
