import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AvailableSportsScreen extends StatefulWidget {
  final String turfId;
  const AvailableSportsScreen({super.key, required this.turfId});

  @override
  State<AvailableSportsScreen> createState() => _AvailableSportsScreenState();
}

class _AvailableSportsScreenState extends State<AvailableSportsScreen> {
  String _selectedSport = 'Football';

  final sports = [
    {'name': 'Football', 'count': '4 Turfs', 'icon': Icons.sports_soccer},
    {'name': 'Cricket', 'count': '2 Turfs', 'icon': Icons.sports_cricket},
    {'name': 'Badminton', 'count': '3 Turfs', 'icon': Icons.sports_tennis},
    {'name': 'Tennis', 'count': '1 Turf', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Basketball', 'count': '1 Turf', 'icon': Icons.sports_basketball},
    {'name': 'Volleyball', 'count': '1 Turf', 'icon': Icons.sports_volleyball},
    {'name': 'Kabaddi', 'count': '1 Turf', 'icon': Icons.sports_mma},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Available Sports'),
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
                itemCount: sports.length,
                itemBuilder: (context, index) {
                  final item = sports[index];
                  final isSelected = item['name'] == _selectedSport;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedSport = item['name'] as String),
                      leading: Icon(item['icon'] as IconData, color: AppTheme.primaryGreen),
                      title: Text(item['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(item['count'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_off,
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => context.push('/slot-selection/${widget.turfId}'),
                child: const Text('View Available Slots'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
