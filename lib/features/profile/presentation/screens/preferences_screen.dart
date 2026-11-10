import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _confirmations = true;
  bool _reminders = true;
  bool _offers = true;
  bool _chat = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Preferences'),
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
              Text('PLAY PREFERENCES', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 8),
              _tile('Preferred Sports', 'Football, Cricket', () => context.push('/favorite-sports')),
              _tile('Preferred Time', 'Evening (5 PM - 10 PM)', () {}),
              _tile('Skill Level', 'Intermediate', () => context.push('/skill-level')),
              _tile('Preferred Location', 'Bangalore, India', () {}),
              const SizedBox(height: 24),
              Text('NOTIFICATIONS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 8),
              _switch('Booking Confirmations', _confirmations, (v) => setState(() => _confirmations = v)),
              _switch('Reminders', _reminders, (v) => setState(() => _reminders = v)),
              _switch('Offers & Promotions', _offers, (v) => setState(() => _offers = v)),
              _switch('Team Chat Messages', _chat, (v) => setState(() => _chat = v)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _switch(String title, bool val, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Switch(value: val, onChanged: onChanged, activeColor: AppTheme.primaryGreen),
      ),
    );
  }
}
