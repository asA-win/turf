import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AddToCalendarScreen extends StatelessWidget {
  const AddToCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Add to Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.primaryGreen),
                ),
                child: const Icon(Icons.calendar_month, size: 64, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 20),
              Text(
                'Add this booking to your calendar',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 32),
              _calBtn(context, 'Google Calendar', Icons.g_mobiledata),
              _calBtn(context, 'Apple Calendar', Icons.apple),
              _calBtn(context, 'Outlook Calendar', Icons.email_outlined),
              _calBtn(context, 'Other Calendar', Icons.edit_calendar),
              const Spacer(),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Not Now', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calBtn(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added to $title!')),
          );
          context.pop();
        },
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
