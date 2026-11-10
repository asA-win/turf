import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class EquipmentRentalScreen extends StatelessWidget {
  const EquipmentRentalScreen({super.key});

  final List<Map<String, dynamic>> items = const [
    {'name': 'Match Football', 'price': '₹100/day', 'icon': Icons.sports_soccer},
    {'name': 'Goalkeeper Gloves', 'price': '₹150/day', 'icon': Icons.front_hand},
    {'name': 'Football Shoes', 'price': '₹200/day', 'icon': Icons.roller_skating},
    {'name': 'Training Bibs (Set of 10)', 'price': '₹50/day', 'icon': Icons.checkroom},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Equipment Rental',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: GoogleFonts.poppins(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  fillColor: AppTheme.cardDark,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'] as IconData, color: AppTheme.primaryGreen, size: 36),
                        ),
                        Column(
                          children: [
                            Text(
                              item['name'],
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['price'],
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${item['name']} added to rental!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Rent Now',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
