import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SelectPlayersScreen extends StatefulWidget {
  const SelectPlayersScreen({super.key});

  @override
  State<SelectPlayersScreen> createState() => _SelectPlayersScreenState();
}

class _SelectPlayersScreenState extends State<SelectPlayersScreen> {
  final List<Map<String, dynamic>> players = [
    {'name': 'Rahul', 'selected': true},
    {'name': 'Vignesh', 'selected': true},
    {'name': 'Karthik', 'selected': true},
    {'name': 'Arun', 'selected': true},
    {'name': 'Vikram', 'selected': true},
    {'name': 'Manoj', 'selected': false},
    {'name': 'Ajith', 'selected': false},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCount = players.where((p) => p['selected'] as bool).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Select Players'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Teammates', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  Text('Max Players: 10', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: players.length + 1,
                  itemBuilder: (context, index) {
                    if (index == players.length) {
                      return Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGreen),
                            ),
                            child: const Icon(Icons.add, color: AppTheme.primaryGreen),
                          ),
                          const SizedBox(height: 4),
                          Text('+ Guest', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11)),
                        ],
                      );
                    }
                    final p = players[index];
                    final isSel = p['selected'] as bool;
                    return GestureDetector(
                      onTap: () => setState(() => p['selected'] = !isSel),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 27,
                                backgroundColor: AppTheme.surfaceDark,
                                child: Text(p['name'][0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              if (isSel)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Selected Players', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                  Text('$selectedCount / 10', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/add-extras'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
