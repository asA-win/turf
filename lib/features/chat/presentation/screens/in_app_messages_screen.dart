import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class InAppMessagesScreen extends ConsumerStatefulWidget {
  const InAppMessagesScreen({super.key});

  @override
  ConsumerState<InAppMessagesScreen> createState() => _InAppMessagesScreenState();
}

class _InAppMessagesScreenState extends ConsumerState<InAppMessagesScreen> {
  StreamSubscription<Map<String, dynamic>>? _chatSub;

  final List<Map<String, dynamic>> chats = [
    {'name': 'Rahul Sharma', 'msg': 'See you tomorrow at 6:45 PM 👍', 'time': '10:30 AM', 'unread': 2, 'type': 'friend'},
    {'name': 'Vignesh K', 'msg': 'Thanks! Great match yesterday 💪', 'time': 'Yesterday', 'unread': 1, 'type': 'friend'},
    {'name': 'Team Titans FC', 'msg': 'Match has been rescheduled to...', 'time': 'Yesterday', 'unread': 0, 'type': 'team'},
    {'name': 'Arun Prasad', 'msg': 'Bro, reaching in 5 mins.', 'time': '17 May', 'unread': 0, 'type': 'friend'},
    {'name': 'Manoj George', 'msg': 'Payment done 💸', 'time': '17 May', 'unread': 0, 'type': 'friend'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _chatSub = ref.read(realtimeServiceProvider).connectToChannel('chat/1').listen((data) {
          if (mounted && data.containsKey('text')) {
            setState(() {
              final idx = chats.indexWhere((c) => c['type'] == 'team');
              if (idx != -1) {
                chats[idx]['msg'] = data['text'];
                chats[idx]['time'] = 'Just now';
                chats[idx]['unread'] = (chats[idx]['unread'] as int) + 1;
              }
            });
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Messages'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              child: TextField(
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textGrey),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final c = chats[index];
                  final unread = c['unread'] as int;
                  final isTeam = c['type'] == 'team';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (isTeam) {
                          context.push('/team-chat');
                        } else {
                          context.push('/friend-chat', extra: {'friendName': c['name']});
                        }
                      },
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.surfaceDark,
                        child: Text(c['name']![0].toString(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(c['name']!.toString(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(c['msg']!.toString(), style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(c['time']!.toString(), style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: AppTheme.primaryGreen,
                              child: Text('$unread', style: GoogleFonts.poppins(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
