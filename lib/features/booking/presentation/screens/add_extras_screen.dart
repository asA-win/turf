import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AddExtrasScreen extends StatefulWidget {
  const AddExtrasScreen({super.key});

  @override
  State<AddExtrasScreen> createState() => _AddExtrasScreenState();
}

class _AddExtrasScreenState extends State<AddExtrasScreen> {
  final List<Map<String, dynamic>> extras = [
    {'name': 'Flood Lights', 'price': 300, 'count': 1, 'icon': Icons.lightbulb_outline},
    {'name': 'Referee', 'price': 500, 'count': 1, 'icon': Icons.sports},
    {'name': 'Scoreboard', 'price': 200, 'count': 0, 'icon': Icons.score},
    {'name': 'Water Bottles (6)', 'price': 120, 'count': 1, 'icon': Icons.water_drop},
    {'name': 'First Aid Kit', 'price': 100, 'count': 0, 'icon': Icons.medical_services},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Add Extras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: extras.length,
                itemBuilder: (context, index) {
                  final item = extras[index];
                  final cnt = item['count'] as int;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, color: AppTheme.primaryGreen, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('₹${item['price']}', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textGrey),
                              onPressed: () {
                                if (cnt > 0) {
                                  setState(() => item['count'] = cnt - 1);
                                }
                              },
                            ),
                            Text('$cnt', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                              onPressed: () {
                                setState(() => item['count'] = cnt + 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/promo-code'),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
