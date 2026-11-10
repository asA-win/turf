import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/services/realtime_service.dart';

class TeamChatScreen extends ConsumerStatefulWidget {
  const TeamChatScreen({super.key});

  @override
  ConsumerState<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends ConsumerState<TeamChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  final List<Map<String, dynamic>> messages = [
    {'sender': 'John (Captain)', 'text': 'Great win today! ⚽', 'isMe': false, 'time': '6:30 PM'},
    {'sender': 'Alex', 'text': 'Thanks everyone! 🙌', 'isMe': false, 'time': '6:31 PM'},
    {'sender': 'Me', 'text': 'Well played team! 💪', 'isMe': true, 'time': '6:32 PM'},
    {'sender': 'John (Captain)', 'text': 'Next match on Saturday. Be ready!', 'isMe': false, 'time': '6:35 PM'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtime = ref.read(realtimeServiceProvider);
      _subscription = realtime.connectToChannel('chat/1').listen((data) {
        if (mounted && data.containsKey('text')) {
          setState(() {
            messages.add({
              'sender': data['sender'] ?? 'Teammate',
              'text': data['text'],
              'isMe': false,
              'time': 'Just now',
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({
        'sender': 'Me',
        'text': text,
        'isMe': true,
        'time': 'Now',
      });
    });

    _msgController.clear();

    try {
      ref.read(realtimeServiceProvider).sendMessage({
        'sender': 'Me',
        'text': text,
      }, channelPath: 'chat/1');
    } catch (_) {}

    // Simulate smart teammate response for interactive chatbox
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          messages.add({
            'sender': 'Alex Johnson',
            'text': 'Count me in! 🔥',
            'isMe': false,
            'time': 'Just now',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Turf Titans', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE WS',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
            Text('10 members • Realtime Chat', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['isMe'] as bool;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryGreen : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                        ),
                        border: Border.all(color: isMe ? AppTheme.primaryGreen : AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg['sender'],
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                            ),
                          Text(
                            msg['text'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isMe ? Colors.black : AppTheme.textWhite,
                              fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg['time'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: isMe ? Colors.black54 : AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(top: BorderSide(color: AppTheme.cardBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppTheme.textGrey),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.poppins(color: AppTheme.textWhite, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
