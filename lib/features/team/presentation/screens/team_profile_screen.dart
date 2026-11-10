import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TeamProfileScreen extends StatelessWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Team Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Edit', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 35,
                backgroundColor: AppTheme.surfaceDark,
                child: const Icon(Icons.shield, color: AppTheme.primaryGreen, size: 40),
              ),
              const SizedBox(height: 12),
              Text('Titans FC', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Elite Division', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _InfoCol(title: 'Founded', val: 'Jan 2024'),
                  _InfoCol(title: 'Location', val: 'Bangalore'),
                  _InfoCol(title: 'Matches', val: '24'),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('About Team', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 6),
              Text(
                'We are a group of passionate players who live for the game. Our mission is to play with discipline, respect and win together.',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Team Captains', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _CapAvatar(name: 'Rahul', role: 'Captain'),
                  _CapAvatar(name: 'Vignesh', role: 'Vice Captain'),
                  _CapAvatar(name: 'Arun', role: 'Manager'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String title;
  final String val;
  const _InfoCol({required this.title, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
        Text(val, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _CapAvatar extends StatelessWidget {
  final String name;
  final String role;
  const _CapAvatar({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.surfaceDark,
            child: Text(name[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(role, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10)),
        ],
      ),
    );
  }
}
