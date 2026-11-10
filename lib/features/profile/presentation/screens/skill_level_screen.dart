import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SkillLevelScreen extends StatefulWidget {
  const SkillLevelScreen({super.key});

  @override
  State<SkillLevelScreen> createState() => _SkillLevelScreenState();
}

class _SkillLevelScreenState extends State<SkillLevelScreen> {
  String _selectedLevel = 'Intermediate';

  final levels = [
    {'title': 'Beginner', 'desc': 'Just starting out'},
    {'title': 'Amateur', 'desc': 'Play for fun'},
    {'title': 'Intermediate', 'desc': 'Regular player'},
    {'title': 'Advanced', 'desc': 'Very good player'},
    {'title': 'Professional', 'desc': 'Competitive player'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Skill Level'),
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
              Text('How would you rate your skill level?', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: levels.length,
                  itemBuilder: (context, index) {
                    final l = levels[index];
                    final isSel = l['title'] == _selectedLevel;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSel ? 2 : 1),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedLevel = l['title']!),
                        title: Text(l['title']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(l['desc']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        trailing: Icon(
                          isSel ? Icons.check_circle : Icons.radio_button_off,
                          color: isSel ? AppTheme.primaryGreen : AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Save Level'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
