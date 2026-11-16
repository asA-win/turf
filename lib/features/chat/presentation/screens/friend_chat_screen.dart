import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/services/local_chat_storage.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/services/session_manager.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  final String friendName;
  final String? friendAvatar;
  final String friendStatus;
  final int? friendId;
  final String? friendUsername;

  const FriendChatScreen({
    super.key,
    required this.friendName,
    this.friendAvatar,
    this.friendStatus = 'Online',
    this.friendId,
    this.friendUsername,
  });

  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _currentStatus = 'Online';
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  StreamSubscription<Map<String, dynamic>>? _channelSub;

  late List<Map<String, dynamic>> _messages;

  String _getMyIdentifier() {
    if (SessionManager.username != null && SessionManager.username!.trim().isNotEmpty) {
      final u = SessionManager.username!.trim();
      if (u.toLowerCase() != 'user' && u.toLowerCase() != 'player') return u;
    }
    final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;
    if (myProfile?.fullName != null &&
        myProfile!.fullName!.trim().isNotEmpty &&
        myProfile.fullName!.toLowerCase() != 'user' &&
        myProfile.fullName!.toLowerCase() != 'player') {
      return myProfile.fullName!.trim();
    }
    if (SessionManager.email != null && SessionManager.email!.contains('@')) {
      return SessionManager.email!.split('@')[0].trim();
    }
    if (myProfile?.email != null && myProfile!.email!.contains('@')) {
      return myProfile.email!.split('@')[0].trim();
    }
    return 'player';
  }

  String get _roomChannel {
    final myNorm = _getMyIdentifier().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final otherRaw = (widget.friendUsername != null && widget.friendUsername!.trim().isNotEmpty)
        ? widget.friendUsername!
        : widget.friendName;
    final otherNorm = otherRaw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final names = [myNorm, otherNorm]..sort();
    return 'dm_${names[0]}_${names[1]}';
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.friendStatus;
    _messages = [];
    _setupChat();
  }

  Future<void> _setupChat() async {
    // 1. Instantly load locally cached messages
    final cached = await LocalChatStorage.getMessages(_roomChannel);
    if (mounted && cached.isNotEmpty) {
      final myNorm = _getMyIdentifier().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      setState(() {
        _messages = cached.map((c) {
          final senderNorm = (c['sender'] ?? c['sender_name'] ?? '').toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
          final bool isMe = c['isMe'] == true || (myNorm.isNotEmpty && senderNorm == myNorm);
          return {
            'id': c['id'],
            'sender': isMe ? 'Me' : (c['sender'] ?? widget.friendName),
            'isMe': isMe,
            'text': c['text'] ?? '',
            'time': c['time'] ?? 'Just now',
          };
        }).toList();
      });
      _scrollToBottom();
    }

    _initRealtime();
    _fetchHistory();

    // Re-verify when user profile resolves
    ref.read(fetchUserProfileProvider.future).then((profile) {
      if (mounted) {
        if (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty) {
          SessionManager.setUsername(profile.fullName!.trim());
        }
        _fetchHistory();
      }
    }).catchError((_) {});
  }

  Future<void> _fetchHistory() async {
    try {
      final dio = ref.read(dioClientProvider);
      final res = await dio.get('/community/chat/$_roomChannel/messages');
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final myNorm = _getMyIdentifier().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;
        final myId = myProfile?.id;

        final history = (res.data as List).map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          final senderId = m['sender_id'];
          final rawSender = (m['sender'] ?? m['sender_name'] ?? '').toString().trim();
          final senderNorm = rawSender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

          final bool isMe = (myId != null && senderId != null && senderId == myId) ||
              (myNorm.isNotEmpty && senderNorm == myNorm);

          return {
            'id': m['id'],
            'sender': isMe ? 'Me' : (m['sender'] ?? widget.friendName),
            'isMe': isMe,
            'text': m['text'] ?? '',
            'time': m['time'] ?? 'Just now',
          };
        }).toList();

        if (mounted && history.isNotEmpty) {
          setState(() {
            _messages = history;
          });
          _scrollToBottom();
          for (final h in history) {
            LocalChatStorage.saveMessage(_roomChannel, h);
          }
        }
      }
    } catch (e) {
      debugPrint('[FRIEND CHAT] Note: /community/chat messages fetch: $e');
    }
  }

  void _initRealtime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final realtime = ref.read(realtimeServiceProvider);

        void handleIncoming(Map<String, dynamic> data) {
          if (!mounted) return;
          if (data.containsKey('text')) {
            final myNorm = _getMyIdentifier().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;
            final myId = myProfile?.id;

            final senderId = data['sender_id'] ?? data['senderId'];
            final rawSender = (data['sender'] ?? data['sender_name'] ?? '').toString().trim();
            final senderNorm = rawSender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

            final bool isMe = (myId != null && senderId != null && senderId == myId) ||
                (myNorm.isNotEmpty && senderNorm == myNorm);

            final msgText = data['text']?.toString() ?? '';
            final alreadyExists = _messages.any((m) =>
                m['text'] == msgText && m['isMe'] == isMe);

            if (!isMe && !alreadyExists) {
              final newMsg = {
                'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch,
                'sender': data['sender'] ?? data['sender_name'] ?? widget.friendName,
                'isMe': false,
                'text': msgText,
                'time': data['time'] ?? 'Just now',
              };
              setState(() {
                _messages.add(newMsg);
              });
              _scrollToBottom();

              LocalChatStorage.saveMessage(_roomChannel, newMsg);
              LocalChatStorage.updateConversation(
                myUsername: _getMyIdentifier(),
                partnerUsername: widget.friendUsername ?? widget.friendName,
                partnerName: widget.friendName,
                lastMsg: msgText,
                time: data['time'] ?? 'Just now',
                partnerAvatar: widget.friendAvatar,
                partnerId: widget.friendId,
              );
            }
          }
        }

        _wsSubscription?.cancel();
        _channelSub?.cancel();
        _wsSubscription = realtime.connectToChannel('chat/$_roomChannel').listen(handleIncoming);
        _channelSub = realtime.connectToChannel('channel/$_roomChannel').listen(handleIncoming);
      } catch (e) {
        debugPrint('Friend chat realtime connection error: $e');
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _channelSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? customText}) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr = '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;
    final myId = myProfile?.id;
    final myName = _getMyIdentifier();
    final otherUsername = (widget.friendUsername ?? widget.friendName).trim().toLowerCase();

    final localMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'sender': 'Me',
      'isMe': true,
      'text': text,
      'time': timeStr,
    };

    setState(() {
      _messages.add(localMsg);
      if (customText == null) {
        _textController.clear();
        _isTyping = false;
      }
    });
    _scrollToBottom();

    // 1. Immediately persist locally
    LocalChatStorage.saveMessage(_roomChannel, localMsg);
    LocalChatStorage.updateConversation(
      myUsername: myName,
      partnerUsername: otherUsername,
      partnerName: widget.friendName,
      lastMsg: text,
      time: timeStr,
      partnerAvatar: widget.friendAvatar,
      partnerId: widget.friendId,
    );

    final payload = {
      'id': localMsg['id'],
      'room_id': _roomChannel,
      'sender': myName,
      'sender_name': myName,
      'sender_id': myId,
      'recipient_id': widget.friendId,
      'recipient_username': otherUsername,
      'text': text,
      'time': timeStr,
    };

    // 2. Broadcast via WebSocket across room and recipient inbox
    try {
      final rt = ref.read(realtimeServiceProvider);
      rt.sendMessage(payload, channelPath: 'chat/$_roomChannel');
      rt.sendMessage(payload, channelPath: 'channel/$_roomChannel');
      rt.sendMessage(payload, channelPath: 'channel/inbox_$otherUsername');
      rt.sendMessage(payload, channelPath: 'chat_inbox');
    } catch (e) {
      debugPrint('[WS SEND ERROR] $e');
    }

    // 3. Persist to backend REST API
    try {
      ref.read(dioClientProvider).post('/community/chat/send', data: {
        'room_id': _roomChannel,
        'sender_name': myName,
        'sender_id': myId,
        'recipient_id': widget.friendId,
        'text': text,
      }).catchError((err) {
        debugPrint('[BACKEND SEND NOTE] $err');
      });
    } catch (e) {
      debugPrint('[DIO SEND NOTE] $e');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share with ${widget.friendName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachmentItem(
                    icon: Icons.sports_soccer,
                    color: AppTheme.primaryGreen,
                    label: 'Turf Invite',
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(customText: '📍 Turf Match Invite: Play Arena (7:00 PM, 5v5). Are you in?');
                    },
                  ),
                  _attachmentItem(
                    icon: Icons.image,
                    color: Colors.purpleAccent,
                    label: 'Photo',
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(customText: '📷 [Photo] Match highlight photo from yesterday!');
                    },
                  ),
                  _attachmentItem(
                    icon: Icons.location_on,
                    color: Colors.redAccent,
                    label: 'Location',
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(customText: '📍 Location: Play Arena, Koramangala Bengaluru');
                    },
                  ),
                  _attachmentItem(
                    icon: Icons.shield,
                    color: Colors.blueAccent,
                    label: 'Team Invite',
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(customText: '🛡️ Join team "Thunder Strikers" for Summer Cup 2025!');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070C09),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1712),
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  backgroundImage: (widget.friendAvatar != null && widget.friendAvatar!.trim().startsWith('http'))
                      ? NetworkImage(widget.friendAvatar!.trim())
                      : const NetworkImage('https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100'),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F1712), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _currentStatus == 'typing...'
                          ? AppTheme.primaryGreen
                          : const Color(0xFF88A090),
                      fontWeight: _currentStatus == 'typing...'
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: AppTheme.textWhite),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting video call with ${widget.friendName}...'),
                  backgroundColor: AppTheme.primaryGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppTheme.textWhite),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${widget.friendName}...'),
                  backgroundColor: AppTheme.primaryGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick reply action pills
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0B140F),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickPill('⚽ I\'m in!'),
                    _quickPill('📍 Play Arena 7 PM'),
                    _quickPill('👍 On my way!'),
                    _quickPill('🧤 Need goalkeeper?'),
                    _quickPill('⚡ Call me'),
                  ],
                ),
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] as bool;
                  return _buildMessageBubble(msg, isMe);
                },
              ),
            ),

            // WhatsApp-style bottom input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1712),
                border: Border(top: BorderSide(color: AppTheme.cardBorder.withValues(alpha: 0.6))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF88A090), size: 24),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Color(0xFF88A090), size: 24),
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17241D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF22362A)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.poppins(color: AppTheme.textWhite, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(color: const Color(0xFF6B8273), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _isTyping = val.trim().isNotEmpty;
                          });
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _isTyping
                        ? () => _sendMessage()
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hold to record voice message (WhatsApp style)...'),
                                backgroundColor: AppTheme.primaryGreen,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isTyping ? Icons.send : Icons.mic,
                        color: Colors.black,
                        size: 20,
                      ),
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

  Widget _quickPill(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _sendMessage(customText: label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF152219),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryGreen : const Color(0xFF16231A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isMe ? AppTheme.primaryGreen : const Color(0xFF223629),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['text'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isMe ? Colors.black : AppTheme.textWhite,
                fontWeight: isMe ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: isMe ? Colors.black54 : AppTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 13,
                    color: Color(0xFF0F4723), // WhatsApp dark double tick on green
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
