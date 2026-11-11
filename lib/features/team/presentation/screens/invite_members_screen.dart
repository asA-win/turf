import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/team/presentation/screens/team_dashboard_screen.dart';

class InviteMembersScreen extends ConsumerStatefulWidget {
  const InviteMembersScreen({super.key});

  @override
  ConsumerState<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends ConsumerState<InviteMembersScreen> {
  final Set<String> _invitedNames = {};

  final suggested = [
    {'name': 'Manoj George', 'role': 'Defender • 8.2'},
    {'name': 'Karthik M', 'role': 'Midfielder • 7.8'},
    {'name': 'Sandeep Kumar', 'role': 'Forward • 8.1'},
    {'name': 'Vikram Nair', 'role': 'Goalkeeper • 7.6'},
    {'name': 'Hari Prasad', 'role': 'Midfielder • 7.4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Invite Members'),
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
              TextField(
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone number',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                ),
              ),
              const SizedBox(height: 20),
              _tile(context, 'Invite from Contacts', Icons.contacts_outlined),
              _tile(context, 'Share Invite Link', Icons.share_outlined),
              _tile(context, 'Invite via WhatsApp', Icons.chat_outlined),
              _tile(context, 'Invite via QR Code', Icons.qr_code),
              const SizedBox(height: 24),
              Text('Suggested Players', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              const SizedBox(height: 12),
              ...suggested.map((s) {
                final isInvited = _invitedNames.contains(s['name']);
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
                      child: Text(s['name']![0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(s['name']!, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(s['role']!, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: isInvited
                          ? null
                          : () async {
                              setState(() => _invitedNames.add(s['name']!));
                              try {
                                final dio = ref.read(dioClientProvider);
                                await dio.post('/teams/1/members', data: {'user_id': 2});
                              } catch (_) {}

                              try {
                                ref.read(realtimeServiceProvider).emit('teams', {
                                  'type': 'member_joined',
                                  'team_id': 1,
                                  'member_name': s['name'],
                                  'role': s['role'],
                                });
                              } catch (_) {}

                              ref.invalidate(fetchTeamsProvider);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invitation sent to ${s['name']}!'),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(70, 32),
                        backgroundColor: isInvited ? Colors.grey : AppTheme.primaryGreen,
                      ),
                      child: Text(
                        isInvited ? 'Sent' : 'Invite',
                        style: GoogleFonts.poppins(
                          color: isInvited ? Colors.white70 : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      ),
    );
  }
}
