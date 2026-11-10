import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/offer_repository.dart';
import 'package:turf_app/features/turf_details/domain/models/offer.dart';

class OffersPromotionsScreen extends ConsumerStatefulWidget {
  const OffersPromotionsScreen({super.key});

  @override
  ConsumerState<OffersPromotionsScreen> createState() => _OffersPromotionsScreenState();
}

class _OffersPromotionsScreenState extends ConsumerState<OffersPromotionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(fetchOffersProvider());

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
        child: offersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load offers: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (offers) {
            return SingleChildScrollView(
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
                              Text('SPECIAL PROMOTION', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Verified Live Deals', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Save more on your favorite slots', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.sports_soccer, size: 64, color: Colors.white38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (offers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('No active offers right now.', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                      ),
                    )
                  else
                    ...offers.map((offer) => _buildLiveOfferCard(offer)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveOfferCard(Offer offer) {
    final discountBadge = offer.discountType == 'percentage'
        ? '${offer.discountValue.toInt()}% OFF'
        : '₹${offer.discountValue.toInt()} OFF';

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
                Text(
                  offer.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                Text(
                  offer.description,
                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: offer.title));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Coupon code ${offer.title} copied!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryGreen),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Code: ${offer.title}',
                              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 12, color: AppTheme.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Min ₹${offer.minBookingAmount.toInt()}',
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                    ),
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
              discountBadge,
              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
