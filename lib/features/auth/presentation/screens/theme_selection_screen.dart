import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String _selectedTheme = 'Dark Mode';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Choose Your Theme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your favorite app theme',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildThemeOption('Light Mode', Icons.wb_sunny_outlined, Colors.white, Colors.black),
              const SizedBox(height: 16),
              _buildThemeOption('Dark Mode', Icons.nightlight_round, AppTheme.surfaceDark, Colors.white),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Apply Theme'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, Color bgColor, Color textColor) {
    final isSelected = _selectedTheme == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTheme = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
