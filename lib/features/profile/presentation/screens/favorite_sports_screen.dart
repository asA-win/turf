import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class FavoriteSportsScreen extends StatefulWidget {
  const FavoriteSportsScreen({super.key});

  @override
  State<FavoriteSportsScreen> createState() => _FavoriteSportsScreenState();
}

class _FavoriteSportsScreenState extends State<FavoriteSportsScreen> {
  final List<Map<String, dynamic>> sports = [
    {'name': 'Football', 'icon': Icons.sports_soccer, 'selected': true},
    {'name': 'Cricket', 'icon': Icons.sports_cricket, 'selected': true},
    {'name': 'Basketball', 'icon': Icons.sports_basketball, 'selected': true},
    {'name': 'Badminton', 'icon': Icons.sports_tennis, 'selected': true},
    {'name': 'Tennis', 'icon': Icons.sports_tennis_outlined, 'selected': false},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball, 'selected': false},
    {'name': 'Table Tennis', 'icon': Icons.sports_kabaddi, 'selected': false},
    {'name': 'Hockey', 'icon': Icons.sports_hockey, 'selected': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Favorite Sports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Select your favorite sports', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: sports.length,
                itemBuilder: (context, index) {
                  final s = sports[index];
                  final isSel = s['selected'] as bool;
                  return GestureDetector(
                    onTap: () => setState(() => s['selected'] = !isSel),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSel ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s['icon'] as IconData, color: isSel ? AppTheme.primaryGreen : AppTheme.textGrey, size: 36),
                          const SizedBox(height: 8),
                          Text(s['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
