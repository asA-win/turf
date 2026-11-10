import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class VenueSettingsScreen extends StatelessWidget {
  const VenueSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Container(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Green Field Arena', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Koramangala, Bangalore • ★ 4.6', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _item(context, 'Venue Information', Icons.info_outline, () {}),
              _item(context, 'Pricing & Time Slots', Icons.attach_money, () => context.push('/venue-calendar')),
              _item(context, 'Add-ons & Amenities', Icons.extension_outlined, () => context.push('/addons-management')),
              _item(context, 'Rules & Guidelines', Icons.gavel_outlined, () {}),
              _item(context, 'Photos & Videos', Icons.photo_library_outlined, () {}),
              _item(context, 'Payout & Bank Details', Icons.account_balance_outlined, () => context.push('/venue-earnings')),
              _item(context, 'Notifications', Icons.notifications_none, () {}),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: Text('Delete Venue', style: GoogleFonts.poppins(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
