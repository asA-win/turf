import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Settings'),
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
              Text('Preferences', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _tile('Edit Profile', Icons.person_outline, () => context.push('/edit-profile')),
              _tile('Privacy Settings', Icons.security_outlined, () => context.push('/data-privacy')),
              _tile('Notification Settings', Icons.notifications_none, () => context.push('/notifications')),
              _tile('Account Security', Icons.lock_outline, () => context.push('/account-security')),
              const SizedBox(height: 24),
              Text('App Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _tile('Language', Icons.language, () => context.push('/language-selection'), trailingText: 'English'),
              _switch('Dark Mode', Icons.brightness_4_outlined, _darkMode, (v) => setState(() => _darkMode = v)),
              _tile('Units', Icons.straighten, () {}, trailingText: 'Metric'),
              const SizedBox(height: 24),
              Text('More', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _tile('Help & Support', Icons.help_outline, () => context.push('/support-center')),
              _tile('Terms & Conditions', Icons.description_outlined, () => context.push('/terms-conditions')),
              _tile('About Us', Icons.info_outline, () => context.push('/about-us')),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/logout'),
                  child: Text('Log Out', style: GoogleFonts.poppins(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap, {String? trailingText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) ...[
              Text(trailingText, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _switch(String title, IconData icon, bool val, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: Switch(value: val, onChanged: onChanged, activeColor: AppTheme.primaryGreen),
      ),
    );
  }
}
