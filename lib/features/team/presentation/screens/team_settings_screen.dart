import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TeamSettingsScreen extends StatefulWidget {
  const TeamSettingsScreen({super.key});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  bool _approvalRequired = true;
  bool _matchReminders = true;
  bool _chatMessages = true;
  bool _teamUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Team Settings'),
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
              Text('Privacy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _tile('Team Visibility', 'Anyone can find and request to join', null),
              _switch('Approval Required', 'Manage join requests', _approvalRequired, (v) => setState(() => _approvalRequired = v)),
              const SizedBox(height: 24),
              Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _switch('Match Reminders', '', _matchReminders, (v) => setState(() => _matchReminders = v)),
              _switch('Team Chat Messages', '', _chatMessages, (v) => setState(() => _chatMessages = v)),
              _switch('Team Updates', '', _teamUpdates, (v) => setState(() => _teamUpdates = v)),
              const SizedBox(height: 24),
              Text('Other', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              _tile('Edit Team Info', '', () => context.push('/team-profile')),
              _tile('Change Team Logo', '', () {}),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                child: Text('Leave Team', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String subtitle, VoidCallback? onTap) {
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
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)) : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _switch(String title, String subtitle, bool val, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)) : null,
        trailing: Switch(value: val, onChanged: onChanged, activeColor: AppTheme.primaryGreen),
      ),
    );
  }
}
