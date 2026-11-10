import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ShareMatchScreen extends StatelessWidget {
  final String matchId;
  const ShareMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Text(
          'Share Match',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Great Match! ⚽', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Turf Titans 2 - 1 Goal Diggers', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('18 May 2025 • Green Field Arena', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(12),
                child: Text('BYS', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _btn('WhatsApp', Icons.chat, Colors.green),
                  _btn('Instagram', Icons.camera_alt, Colors.purple),
                  _btn('Stories', Icons.auto_awesome, Colors.orange),
                  _btn('More', Icons.more_horiz, Colors.white),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.black),
                label: const Text('Download Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.surfaceDark,
          radius: 24,
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}
