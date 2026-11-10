import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Football', 'count': '128 Turfs', 'icon': Icons.sports_soccer},
      {'name': 'Cricket', 'count': '94 Turfs', 'icon': Icons.sports_cricket},
      {'name': 'Badminton', 'count': '56 Turfs', 'icon': Icons.sports_tennis},
      {'name': 'Tennis', 'count': '32 Turfs', 'icon': Icons.sports_tennis_outlined},
      {'name': 'Basketball', 'count': '32 Turfs', 'icon': Icons.sports_basketball},
      {'name': 'Volleyball', 'count': '18 Turfs', 'icon': Icons.sports_volleyball},
      {'name': 'Kabaddi', 'count': '12 Turfs', 'icon': Icons.sports_mma},
      {'name': 'Table Tennis', 'count': '10 Turfs', 'icon': Icons.sports_kabaddi},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: InkWell(
                  onTap: () => context.push('/search-results?query=${cat['name']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceDark,
                            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                          ),
                          child: Icon(cat['icon'] as IconData, color: AppTheme.primaryGreen, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat['name'] as String,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          cat['count'] as String,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
