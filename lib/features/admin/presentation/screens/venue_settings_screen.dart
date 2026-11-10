import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class VenueSettingsScreen extends ConsumerWidget {
  const VenueSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTurfsAsync = ref.watch(fetchMyTurfsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Venue Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              myTurfsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (_, __) => _venueHeader('Greenfield Arena', 'Koramangala, Bangalore • ★ 4.8'),
                data: (turfs) {
                  final turf = turfs.isNotEmpty ? turfs.first : null;
                  final name = turf?.name ?? 'My Venue Arena';
                  final subtitle = turf != null
                      ? '${turf.location} • ★ ${turf.averageRating}'
                      : 'Active Venue Profile';
                  return _venueHeader(name, subtitle);
                },
              ),
              const SizedBox(height: 24),
              _item(context, 'Pricing & Time Slots', Icons.attach_money, () => context.push('/venue-calendar')),
              _item(context, 'Add-ons & Amenities', Icons.extension_outlined, () => context.push('/addons-management')),
              _item(context, 'Payout & Bank Details', Icons.account_balance_outlined, () => context.push('/venue-earnings')),
              _item(context, 'Customer Reviews', Icons.rate_review_outlined, () => context.push('/venue-reviews')),
              _item(context, 'Live Booking Requests', Icons.notifications_active_outlined, () => context.push('/live-booking-requests')),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Log Out Venue Account', style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _venueHeader(String name, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
      ),
    );
  }
}
