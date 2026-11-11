import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  StreamSubscription<Map<String, dynamic>>? _teamsSub;

  final List<Map<String, String>> members = [
    {'name': 'John Doe', 'role': 'Captain', 'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'},
    {'name': 'Alex Johnson', 'role': 'Midfielder', 'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100'},
    {'name': 'Michael Brown', 'role': 'Defender', 'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'},
    {'name': 'David Williams', 'role': 'Goalkeeper', 'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _teamsSub = ref.read(realtimeServiceProvider).connectToChannel('teams').listen((event) {
          if (mounted && event['type'] == 'member_joined') {
            final m = event['member'] as Map<String, dynamic>?;
            if (m != null) {
              final name = m['name']?.toString() ?? 'New Teammate';
              final role = m['role']?.toString() ?? 'Player';
              if (!members.any((existing) => existing['name'] == name)) {
                setState(() {
                  members.add({
                    'name': name,
                    'role': role,
                    'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  });
                });
              }
            }
          }
        });
      } catch (e) {
        debugPrint('Team management realtime error: $e');
      }
    });
  }

  @override
  void dispose() {
    _teamsSub?.cancel();
    super.dispose();
  }

  void _showInvitePlayerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Forward';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invite New Teammate',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textGrey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Player Name', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: 'e.g. Samuel Green',
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 14),
            Text('Phone Number', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                hintText: '+91 98765 43210',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 14),
            Text('Position / Role', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedRole,
                  dropdownColor: AppTheme.cardDark,
                  isExpanded: true,
                  style: GoogleFonts.poppins(color: AppTheme.textWhite),
                  items: ['Forward', 'Midfielder', 'Defender', 'Goalkeeper', 'Substitute']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedRole = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team invite link copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.link, color: AppTheme.primaryGreen),
                    label: Text('Copy Link', style: GoogleFonts.poppins(color: AppTheme.primaryGreen)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          members.add({
                            'name': name,
                            'role': selectedRole,
                            'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                          });
                        });
                        try {
                          ref.read(dioClientProvider).post('/teams/1/members', data: {
                            'name': name,
                            'role': selectedRole,
                          });
                        } catch (_) {}
                        try {
                          ref.read(realtimeServiceProvider).emitToChannel('teams', {
                            'type': 'member_joined',
                            'team_id': 1,
                            'member': {
                              'name': name,
                              'role': selectedRole,
                            },
                          });
                        } catch (_) {}
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invitation sent to ${name.isEmpty ? "player" : name}!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Send Invite', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Team Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryGreen),
            onPressed: () => context.push('/chat'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Team Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Turf Titans',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bengaluru Premier League • Div A',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 16),

                    // Team Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statCol('12', 'Matches'),
                        _statCol('9', 'Wins'),
                        _statCol('32', 'Goals'),
                        _statCol('#2', 'Rank'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Team Members Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Squad Members (${members.length})',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  TextButton.icon(
                    onPressed: _showInvitePlayerDialog,
                    icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryGreen),
                    label: Text(
                      'Add Player',
                      style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...members.map((member) {
                final isCaptain = member['role'] == 'Captain';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isCaptain ? AppTheme.primaryGreen : AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(member['avatar']!),
                        onBackgroundImageError: (_, __) {},
                        child: Text(member['name']![0], style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member['name']!,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            Text(
                              member['role']!,
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                      if (isCaptain)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Captain',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Action Buttons Row (Invite Players & Team Chat)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/chat'),
                      icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryGreen, size: 18),
                      label: Text('Team Chat', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showInvitePlayerDialog,
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.black, size: 18),
                      label: Text('Invite Players', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
        ),
      ],
    );
  }
}
