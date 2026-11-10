import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SelectDurationScreen extends StatefulWidget {
  const SelectDurationScreen({super.key});

  @override
  State<SelectDurationScreen> createState() => _SelectDurationScreenState();
}

class _SelectDurationScreenState extends State<SelectDurationScreen> {
  String _selectedDuration = '1.5 Hours';

  final options = [
    {'duration': '1.5 Hours', 'price': '₹1600'},
    {'duration': '2 Hours', 'price': '₹2000'},
    {'duration': '2.5 Hours', 'price': '₹2400'},
    {'duration': '3 Hours', 'price': '₹2800'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Select Duration'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Slot', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        Text('18 May 2025', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen),
                      ),
                      child: Text('7:00 PM - 8:30 PM', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Extend Duration', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options[index];
                    final isSelected = item['duration'] == _selectedDuration;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder),
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedDuration = item['duration']!),
                        title: Text(item['duration']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        trailing: Text(item['price']!, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/select-players'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
