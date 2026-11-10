import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class BysCoinsScreen extends StatelessWidget {
  const BysCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('BYS Coins'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text('Your BYS Coins', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 36),
                        const SizedBox(width: 8),
                        Text('1,250', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Keep playing, keep earning!', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('How to Earn', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _earnItem('Complete a Booking', '+50 Coins', Icons.calendar_today),
              _earnItem('Invite a Friend', '+100 Coins', Icons.person_add),
              _earnItem('Write a Review', '+25 Coins', Icons.rate_review),
              _earnItem('Play Streak (3 Days)', '+75 Coins', Icons.local_fire_department),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/store'),
                child: const Text('View Rewards'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: Text('Transaction History', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _earnItem(String title, String reward, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Text(reward, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}
