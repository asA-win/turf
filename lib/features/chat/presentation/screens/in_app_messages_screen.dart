import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/local_chat_storage.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/services/session_manager.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class InAppMessagesScreen extends ConsumerStatefulWidget {
  const InAppMessagesScreen({super.key});

  @override
  ConsumerState<InAppMessagesScreen> createState() => _InAppMessagesScreenState();
}

class _InAppMessagesScreenState extends ConsumerState<InAppMessagesScreen> {
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _inboxSub;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> chats = [];

  String _getMyUsername() {
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

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _connectInboxListener();

    ref.read(fetchUserProfileProvider.future).then((profile) {
      if (mounted) {
        if (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty) {
          SessionManager.setUsername(profile.fullName!.trim());
        }
        _fetchConversations();
        _connectInboxListener();
      }
    }).catchError((_) {});
  }

  void _connectInboxListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final realtime = ref.read(realtimeServiceProvider);
        final myUname = _getMyUsername().toLowerCase();

        void onIncoming(Map<String, dynamic> data) {
          if (!mounted) return;
          final sender = (data['sender'] ?? data['sender_name'] ?? '').toString().trim();
          final text = (data['text'] ?? '').toString();
          final time = (data['time'] ?? 'Just now').toString();

          if (sender.isNotEmpty && sender.toLowerCase() != myUname) {
            LocalChatStorage.updateConversation(
              myUsername: myUname,
              partnerUsername: sender,
              partnerName: sender.length > 1 ? sender[0].toUpperCase() + sender.substring(1) : sender,
              lastMsg: text,
              time: time,
            );
            _fetchConversations();
          }
        }

        _inboxSub?.cancel();
        _chatSub?.cancel();

        if (myUname.isNotEmpty) {
          _inboxSub = realtime.connectToChannel('channel/inbox_$myUname').listen(onIncoming);
        }
        _chatSub = realtime.connectToChannel('chat_inbox').listen(onIncoming);
      } catch (_) {}
    });
  }

  Future<void> _fetchConversations() async {
    final myUname = _getMyUsername();

    // 1. Immediately display cached local conversations
    if (myUname.isNotEmpty) {
      final cached = await LocalChatStorage.getConversations(myUname);
      if (mounted && cached.isNotEmpty && chats.isEmpty) {
        setState(() => chats = cached);
      }
    }

    // 2. Query server for active conversations
    try {
      final dio = ref.read(apiClientProvider);
      final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;

      final res = await dio.get('/community/chat/conversations', queryParameters: {
        if (myUname.isNotEmpty) 'username': myUname,
        if (myProfile?.id != null) 'user_id': myProfile!.id,
      });

      if (res.statusCode == 200 && res.data is List) {
        final serverChats = (res.data as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return {
            'id': m['id'],
            'friendId': m['id'],
            'name': m['name'] ?? 'Friend',
            'username': m['username'] ?? 'friend',
            'msg': m['lastMsg'] ?? '',
            'time': m['time'] ?? 'Just now',
            'unread': m['unread'] ?? 0,
            'type': 'friend',
            'avatar': m['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          };
        }).toList();

        if (mounted && serverChats.isNotEmpty) {
          setState(() {
            chats = serverChats;
          });
          for (final c in serverChats) {
            LocalChatStorage.updateConversation(
              myUsername: myUname,
              partnerUsername: c['username'],
              partnerName: c['name'],
              lastMsg: c['msg'],
              time: c['time'],
              partnerAvatar: c['avatar'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('InAppMessages fetch note: $e');
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _inboxSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showUserSearchDialog([String initialQuery = '']) async {
    final selectedFriend = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatUserSearchSheet(
        initialQuery: initialQuery,
        chats: chats,
        dioClient: ref.read(apiClientProvider),
      ),
    );

    if (selectedFriend != null && mounted) {
      if (selectedFriend['type'] == 'team') {
        context.push('/team-chat');
        return;
      }
      final uname = (selectedFriend['username'] ?? '').toString().toLowerCase();
      final existingIdx = chats.indexWhere(
        (c) => (c['username'] ?? '').toString().toLowerCase() == uname,
      );
      if (existingIdx == -1) {
        setState(() {
          chats.insert(0, {
            'id': selectedFriend['id'],
            'friendId': selectedFriend['id'],
            'name': selectedFriend['name'],
            'username': selectedFriend['username'],
            'msg': 'Chat started',
            'time': 'Just now',
            'unread': 0,
            'type': 'friend',
            'avatar': selectedFriend['avatar'],
          });
        });
      }
      context.push('/friend-chat', extra: selectedFriend);
    }
  }
  @override
  Widget build(BuildContext context) {
    final filteredChats = chats.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final username = (c['username'] ?? '').toString().toLowerCase();
      final msg = (c['msg'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q) || msg.contains(q);
    }).toList();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Find Friends & Chat',
            onPressed: () => _showUserSearchDialog(_searchQuery),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search username, friend name, or messages...',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey, size: 20),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
            ),
            Expanded(
              child: filteredChats.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF384A3E)),
                            const SizedBox(height: 12),
                            Text(
                              'No conversations found',
                              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () => _showUserSearchDialog(_searchQuery),
                              icon: const Icon(Icons.person_search_rounded, size: 16, color: Colors.black),
                              label: Text(
                                _searchQuery.isNotEmpty ? 'Search players for "$_searchQuery"' : 'Find Friends by Username',
                                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final c = filteredChats[index];
                        final unread = (c['unread'] is num) ? (c['unread'] as num).toInt() : 0;
                        final isTeam = c['type'] == 'team';
                        final cName = (c['name'] ?? 'Friend').toString().trim();
                        final displayName = cName.isNotEmpty ? cName : 'Friend';
                        final username = (c['username'] ?? displayName.toLowerCase()).toString();
                        final msg = (c['msg'] ?? '').toString();
                        final time = (c['time'] ?? 'Just now').toString();
                        final avatar = (c['avatar'] ?? '').toString().trim();
                        final hasAvatar = avatar.startsWith('http');

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
                                context.push('/friend-chat', extra: {
                                  'id': c['id'] ?? username.hashCode.abs(),
                                  'friendId': c['id'] ?? username.hashCode.abs(),
                                  'name': displayName,
                                  'username': username,
                                  'avatar': hasAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                });
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.surfaceDark,
                              backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                              child: !hasAvatar
                                  ? Text(
                                      displayName.characters.isNotEmpty ? displayName.characters.first.toUpperCase() : '?',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              username.isNotEmpty ? '@$username • $msg' : msg,
                              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(time, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
                                if (unread > 0) ...[
                                  const SizedBox(height: 4),
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: AppTheme.primaryGreen,
                                    child: Text(
                                      '$unread',
                                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
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


class _ChatUserSearchSheet extends StatefulWidget {
  final String initialQuery;
  final List<Map<String, dynamic>> chats;
  final dynamic dioClient;

  const _ChatUserSearchSheet({
    required this.initialQuery,
    required this.chats,
    required this.dioClient,
  });

  @override
  State<_ChatUserSearchSheet> createState() => _ChatUserSearchSheetState();
}

class _ChatUserSearchSheetState extends State<_ChatUserSearchSheet> {
  late final TextEditingController _searchCtrl;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _doSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _doSearch(String query) {
    _debounceTimer?.cancel();
    final cleanQ = query.trim().replaceAll(RegExp(r'^@+'), '').trim();

    if (cleanQ.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    final localMatches = widget.chats.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final uname = (c['username'] ?? '').toString().toLowerCase();
      final ql = cleanQ.toLowerCase();
      return name.contains(ql) || uname.contains(ql);
    }).toList();

    if (mounted) {
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(localMatches);
        _isSearching = true;
      });
    }

    _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final res = await widget.dioClient.get('/users/search', queryParameters: {'q': cleanQ, 'query': cleanQ});
        if (res.statusCode == 200 && res.data is List) {
          final serverUsers = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          final combined = <Map<String, dynamic>>[...serverUsers];
          final seenUsernames = serverUsers.map((u) => (u['username'] ?? '').toString().toLowerCase()).toSet();

          for (final loc in localMatches) {
            final uName = (loc['username'] ?? '').toString().toLowerCase();
            if (!seenUsernames.contains(uName)) {
              combined.add(loc);
            }
          }

          if (mounted) {
            setState(() {
              _searchResults = combined;
              _isSearching = false;
            });
          }
        } else {
          if (mounted) setState(() => _isSearching = false);
        }
      } catch (e) {
        debugPrint('Note: /users/search api lookup: $e');
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF132218),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_search_rounded, color: AppTheme.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Start New Chat',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textGrey, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2B4734)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
                        autofocus: widget.initialQuery.isEmpty,
                        decoration: InputDecoration(
                          hintText: 'Search player by username or name...',
                          hintStyle: GoogleFonts.poppins(color: const Color(0xFF6E8A77), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppTheme.textGrey, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _doSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        onChanged: (val) {
                          setState(() {});
                          _doSearch(val);
                        },
                      ),
                    ),
                    if (_isSearching) ...[
                      const SizedBox(height: 4),
                      const LinearProgressIndicator(
                        color: AppTheme.primaryGreen,
                        backgroundColor: Colors.transparent,
                        minHeight: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: (_searchCtrl.text.trim().isNotEmpty)
                      ? (_searchResults.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isSearching) ...[
                                      const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryGreen),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Searching platform players...',
                                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16251C),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: const Color(0xFF26422F)),
                                      ),
                                      child: Builder(
                                        builder: (_) {
                                          final rawQuery = _searchCtrl.text.trim().replaceAll(RegExp(r'^@+'), '').trim();
                                          final directMatch = widget.chats.firstWhere(
                                            (c) => (c['username'] ?? '').toString().toLowerCase() == rawQuery.toLowerCase(),
                                            orElse: () => <String, dynamic>{},
                                          );
                                          final fallbackId = (directMatch['id'] is num)
                                              ? (directMatch['id'] as num).toInt()
                                              : (directMatch['friendId'] is num)
                                                  ? (directMatch['friendId'] as num).toInt()
                                                  : (rawQuery.isNotEmpty ? rawQuery.hashCode.abs() : 9999);
                                          final fallbackItem = {
                                            'id': fallbackId,
                                            'friendId': fallbackId,
                                            'name': directMatch['name'] ?? rawQuery,
                                            'username': rawQuery,
                                            'avatar': (directMatch['avatar'] != null && directMatch['avatar'].toString().startsWith('http'))
                                                ? directMatch['avatar'].toString()
                                                : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                            'status': 'Online',
                                          };

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.person_search_rounded, size: 40, color: AppTheme.primaryGreen),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No registered matches for "@$rawQuery"',
                                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'You can still start a direct conversation with @$rawQuery right away.',
                                                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 14),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.send_rounded, size: 16),
                                                  label: Text(
                                                    'Direct Message @$rawQuery',
                                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.5),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryGreen,
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, fallbackItem),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, idx) {
                                final user = _searchResults[idx];
                                final rawName = (user['name'] ?? '').toString().trim();
                                final rawUname = (user['username'] ?? '').toString().trim();
                                final name = rawName.isNotEmpty ? rawName : (rawUname.isNotEmpty ? rawUname : 'Player');
                                final username = rawUname.isNotEmpty ? rawUname : name.toLowerCase().replaceAll(' ', '');
                                final role = (user['role'] ?? 'Community Player').toString();
                                final avatar = (user['avatar'] ?? '').toString().trim();
                                final hasValidAvatar = avatar.startsWith('http');
                                final initial = name.characters.isNotEmpty ? name.characters.first.toUpperCase() : '?';
                                final dynamicId = (user['id'] is num) ? (user['id'] as num).toInt() : username.hashCode.abs();
                                final fallbackAvatar = hasValidAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

                                final friendItem = {
                                  'id': dynamicId,
                                  'friendId': dynamicId,
                                  'name': name,
                                  'username': username,
                                  'role': role,
                                  'avatar': fallbackAvatar,
                                  'status': 'Online',
                                };

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16251C),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF233B2C)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context, friendItem),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                              backgroundImage: hasValidAvatar ? NetworkImage(avatar) : null,
                                              onBackgroundImageError: hasValidAvatar ? (_, __) {} : null,
                                              child: !hasValidAvatar
                                                  ? Text(
                                                      initial,
                                                      style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '@$username • $role',
                                                    style: GoogleFonts.poppins(
                                                      color: AppTheme.primaryGreen,
                                                      fontSize: 11.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGreen,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.black),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Chat',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ))
                      : ListView(
                          children: [
                            if (widget.chats.isEmpty) ...[
                              const SizedBox(height: 30),
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.person_search_rounded, size: 44, color: Color(0xFF384A3E)),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Search Friends by Username',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text(
                                        'Type your friend’s username in the search bar above to start a 1-on-1 chat.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Recent Contacts',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF8DA394),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...widget.chats.map((c) {
                                final cName = (c['name'] ?? 'Friend').toString().trim();
                                final displayName = cName.isNotEmpty ? cName : 'Friend';
                                final username = (c['username'] ?? displayName.toLowerCase()).toString();
                                final avatar = (c['avatar'] ?? '').toString().trim();
                                final hasAvatar = avatar.startsWith('http');
                                final initial = displayName.characters.isNotEmpty ? displayName.characters.first.toUpperCase() : '?';
                                final dynamicId = c['id'] ?? username.hashCode.abs();
                                final fallbackAvatar = hasAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

                                final friendItem = {
                                  'id': dynamicId,
                                  'friendId': dynamicId,
                                  'name': displayName,
                                  'username': username,
                                  'avatar': fallbackAvatar,
                                  'status': c['status'] ?? 'Online',
                                  'type': c['type'],
                                };

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16251C),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF233B2C)),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context, friendItem),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                              backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                                              onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                                              child: !hasAvatar
                                                  ? Text(
                                                      initial,
                                                      style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    c['username'] != null ? '@${c['username']}' : (c['msg']?.toString() ?? ''),
                                                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
