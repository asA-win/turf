import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class InvitePlayersScreen extends StatefulWidget {
  const InvitePlayersScreen({super.key});

  @override
  State<InvitePlayersScreen> createState() => _InvitePlayersScreenState();
}

class _InvitePlayersScreenState extends State<InvitePlayersScreen> {
  final List<Map<String, dynamic>> friends = [
    {'name': 'Rahul Sharma', 'level': 'Intermediate', 'invited': true},
    {'name': 'Vignesh K', 'level': 'Advanced', 'invited': true},
    {'name': 'Arun Prasad', 'level': 'Beginner', 'invited': false},
    {'name': 'Karthik M', 'level': 'Intermediate', 'invited': false},
    {'name': 'Sandeep Kumar', 'level': 'Advanced', 'invited': false},
    {'name': 'Manoj George', 'level': 'Intermediate', 'invited': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Invite Players'),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Friends on BYS', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
                      Text('3 / 10 Joined', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search friends...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final f = friends[index];
                  final isInv = f['invited'] as bool;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.surfaceDark,
                        child: Text(f['name']![0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(f['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(f['level']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                      trailing: Checkbox(
                        value: isInv,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (v) => setState(() => f['invited'] = v!),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.surfaceDark,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialAction('WhatsApp', Icons.chat, Colors.green),
                  _socialAction('Share Link', Icons.share, AppTheme.primaryGreen),
                  _socialAction('Copy Link', Icons.copy, Colors.white),
                  _socialAction('More', Icons.more_horiz, Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialAction(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10)),
      ],
    );
  }
}
