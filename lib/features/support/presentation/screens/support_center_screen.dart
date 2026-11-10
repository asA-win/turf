import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Support Center'),
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
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.headset_mic, color: AppTheme.primaryGreen, size: 48),
                    const SizedBox(height: 12),
                    Text('How can we help you?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("We're here to assist you 24/7", style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Contact Us', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              _contactOption(context, 'Live Chat', 'Chat with our support team', Icons.chat_bubble_outline, () => context.push('/chat'), isOnline: true),
              _contactOption(context, 'Email Support', 'support@bysapp.com', Icons.email_outlined, () {}),
              _contactOption(context, 'Call Us', '+91 98765 43210', Icons.phone_outlined, () {}),
              _contactOption(context, 'Report an Issue', 'Found a bug or facing an issue?', Icons.bug_report_outlined, () {}),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppTheme.textGrey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('We usually respond within a few minutes.', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactOption(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap, {bool isOnline = false}) {
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
        title: Row(
          children: [
            Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            if (isOnline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                child: Text('Online', style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
