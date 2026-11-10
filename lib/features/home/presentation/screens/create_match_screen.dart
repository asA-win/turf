import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  String _selectedSport = 'Football';
  int _playersCount = 10;
  String _level = 'Intermediate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Create Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Sport', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _sportChip('Football', Icons.sports_soccer),
                  _sportChip('Cricket', Icons.sports_cricket),
                  _sportChip('Basketball', Icons.sports_basketball),
                  _sportChip('Badminton', Icons.sports_tennis),
                ],
              ),
              const SizedBox(height: 20),
              Text('Select Turf', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Green Field Arena', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Koramangala, Bangalore', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Date & Time', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18 May 2025', style: GoogleFonts.poppins(color: Colors.white)),
                    Text('7:00 PM - 8:30 PM', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Players Count', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textGrey),
                        onPressed: () {
                          if (_playersCount > 2) setState(() => _playersCount--);
                        },
                      ),
                      Text('$_playersCount', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                        onPressed: () => setState(() => _playersCount++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Skill Level', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _level,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardDark,
                    items: ['Beginner', 'Intermediate', 'Advanced', 'Professional']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.poppins(color: Colors.white))))
                        .toList(),
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Max Fee (per player)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: const InputDecoration(hintText: '₹150'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/invite-players'),
                child: const Text('Create Match'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sportChip(String label, IconData icon) {
    final isSelected = _selectedSport == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : AppTheme.primaryGreen),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
          ],
        ),
        selectedColor: AppTheme.primaryGreen,
        backgroundColor: AppTheme.cardDark,
        onSelected: (v) => setState(() => _selectedSport = label),
      ),
    );
  }
}
