import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class InAppMessagesScreen extends StatelessWidget {
  const InAppMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {'name': 'Rahul Sharma', 'msg': 'See you tomorrow at 6:45 PM 👍', 'time': '10:30 AM', 'unread': 2},
      {'name': 'Vignesh K', 'msg': 'Thanks! Great match yesterday 💪', 'time': 'Yesterday', 'unread': 1},
      {'name': 'Team Titans FC', 'msg': 'Match has been rescheduled to...', 'time': 'Yesterday', 'unread': 0},
      {'name': 'Arun Prasad', 'msg': 'Bro, reaching in 5 mins.', 'time': '17 May', 'unread': 0},
      {'name': 'Manoj George', 'msg': 'Payment done 💸', 'time': '17 May', 'unread': 0},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Messages'),
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () => context.push('/chat'),
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
