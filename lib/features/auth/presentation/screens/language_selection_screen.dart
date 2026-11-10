import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'name': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳'},
    {'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    {'name': 'Kannada', 'native': 'கன்னட', 'flag': '🇮🇳'},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'flag': '🇮🇳'},
    {'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇮🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Choose Language'),
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
                'Select your preferred language',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final item = _languages[index];
                    final isSelected = item['name'] == _selectedLang;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedLang = item['name']!),
                        leading: Text(item['flag']!, style: const TextStyle(fontSize: 22)),
                        title: Text(
                          '${item['native']} (${item['name']})',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                            : const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
