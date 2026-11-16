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
    final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;
    return SessionManager.username ??
        (myProfile?.fullName != null && myProfile!.fullName!.isNotEmpty && myProfile.fullName!.toLowerCase() != 'user' ? myProfile.fullName! : '') ??
        myProfile?.email?.split('@')[0] ??
        '';
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

  void _showUserSearchDialog([String initialQuery = '']) {
    final searchCtrl = TextEditingController(text: initialQuery);
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    Timer? debounceTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void doSearch(String query) {
            debounceTimer?.cancel();
            final cleanQ = query.trim().replaceAll(RegExp(r'^@+'), '').trim();

            if (cleanQ.isEmpty) {
              setModalState(() {
                searchResults = [];
                isSearching = false;
              });
              return;
            }

            final localMatches = chats.where((c) {
              final name = (c['name'] ?? '').toString().toLowerCase();
              final uname = (c['username'] ?? '').toString().toLowerCase();
              final ql = cleanQ.toLowerCase();
              return name.contains(ql) || uname.contains(ql);
            }).map((c) => {
              'id': c['id'] ?? cleanQ.hashCode.abs(),
              'name': c['name'] ?? 'Friend',
              'username': c['username'] ?? cleanQ,
              'role': 'Community Friend',
              'avatar': c['avatar'] ?? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
            }).toList();

            setModalState(() {
              searchResults = List<Map<String, dynamic>>.from(localMatches);
              isSearching = true;
            });

            debounceTimer = Timer(const Duration(milliseconds: 200), () async {
              try {
                final dio = ref.read(apiClientProvider);
                final res = await dio.get('/users/search', queryParameters: {'q': cleanQ, 'query': cleanQ});
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

                  if (ctx.mounted) {
                    setModalState(() {
                      searchResults = combined;
                      isSearching = false;
                    });
                  }
                } else {
                  if (ctx.mounted) setModalState(() => isSearching = false);
                }
              } catch (e) {
                debugPrint('Note: /users/search api note: $e');
                if (ctx.mounted) {
                  setModalState(() => isSearching = false);
                }
              }
            });
          }

          if (initialQuery.isNotEmpty && searchResults.isEmpty && !isSearching) {
            WidgetsBinding.instance.addPostFrameCallback((_) => doSearch(initialQuery));
          }

          final sheetHeight = MediaQuery.of(ctx).size.height * 0.85;

          return Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1B12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 18,
              right: 18,
              top: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Find Friends & Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textGrey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Search for friends with their username or name to start chatting:',
                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 14),

                // Search Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16281C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF26422F)),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search username (e.g. user12, user31) or name...',
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF708577), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                doSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: doSearch,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                      : (searchCtrl.text.trim().isNotEmpty)
                          ? (searchResults.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF132318),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFF26422F)),
                                            ),
                                            child: Column(
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                                  child: Text(
                                                    searchCtrl.text.trim().replaceAll('@', '').isNotEmpty
                                                        ? searchCtrl.text.trim().replaceAll('@', '')[0].toUpperCase()
                                                        : '?',
                                                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  '@${searchCtrl.text.trim().replaceAll('@', '')}',
                                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Start a 1-on-1 direct conversation with @${searchCtrl.text.trim().replaceAll('@', '')} right now!',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    final rawUname = searchCtrl.text.trim().replaceAll('@', '');
                                                    Navigator.pop(ctx);
                                                    final dynamicId = rawUname.hashCode.abs();
                                                    final friendItem = {
                                                      'id': dynamicId,
                                                      'friendId': dynamicId,
                                                      'name': rawUname.isNotEmpty ? rawUname[0].toUpperCase() + rawUname.substring(1) : 'Friend',
                                                      'username': rawUname,
                                                      'role': 'Community Player',
                                                      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                                      'lastMsg': 'Chat started',
                                                      'time': 'Just now',
                                                      'unread': 0,
                                                      'isOnline': true,
                                                      'status': 'Online',
                                                    };
                                                    if (!chats.any((f) => (f['username'] ?? '').toString().toLowerCase() == rawUname.toLowerCase())) {
                                                      setState(() => chats.insert(0, friendItem));
                                                    }
                                                    context.push('/friend-chat', extra: friendItem);
                                                  },
                                                  icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                                                  label: Text(
                                                    'Chat with @${searchCtrl.text.trim().replaceAll('@', '')}',
                                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryGreen,
                                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: searchResults.length,
                                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF16251C), height: 1),
                                  itemBuilder: (context, idx) {
                                    final user = searchResults[idx];
                                    final rawName = (user['name'] ?? '').toString().trim();
                                    final name = rawName.isNotEmpty ? rawName : 'Player';
                                    final rawUname = (user['username'] ?? '').toString().trim();
                                    final username = rawUname.isNotEmpty ? rawUname : name.toLowerCase();
                                    final role = (user['role'] ?? 'Active Player').toString();
                                    final avatar = (user['avatar'] ?? '').toString().trim();
                                    final hasValidAvatar = avatar.startsWith('http');

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                        backgroundImage: hasValidAvatar ? NetworkImage(avatar) : null,
                                        child: !hasValidAvatar
                                            ? Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '@$username • $role',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.primaryGreen,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      trailing: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          final fallbackAvatar = hasValidAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';
                                          final dynamicId = user['id'] ?? username.hashCode.abs();
                                          final existingIdx = chats.indexWhere(
                                            (c) => (c['username'] ?? '').toString().toLowerCase() == username.toLowerCase(),
                                          );
                                          if (existingIdx == -1) {
                                            setState(() {
                                              chats.insert(0, {
                                                'id': dynamicId,
                                                'name': name,
                                                'username': username,
                                                'msg': 'Chat started',
                                                'time': 'Just now',
                                                'unread': 0,
                                                'type': 'friend',
                                                'avatar': fallbackAvatar,
                                              });
                                            });
                                          }
                                          context.push('/friend-chat', extra: {
                                            'id': dynamicId,
                                            'friendId': dynamicId,
                                            'name': name,
                                            'username': username,
                                            'avatar': fallbackAvatar,
                                            'status': 'Online',
                                          });
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.black),
                                        label: Text(
                                          'Chat',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryGreen,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    );
                                  },
                                ))
                          : ListView(
                              children: [
                                if (chats.isEmpty) ...[
                                  const SizedBox(height: 36),
                                  Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF384A3E)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Search Friends by Username',
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Text(
                                            'Type your friend’s username in the search bar above to start a 1-on-1 chat.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
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
                                  ...chats.map((c) {
                                    final cName = (c['name'] ?? 'Friend').toString().trim();
                                    final displayName = cName.isNotEmpty ? cName : 'Friend';
                                    final username = (c['username'] ?? displayName.toLowerCase()).toString();
                                    final avatar = (c['avatar'] ?? '').toString().trim();
                                    final hasAvatar = avatar.startsWith('http');
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        if (c['type'] == 'team') {
                                          context.push('/team-chat');
                                        } else {
                                          context.push('/friend-chat', extra: {
                                            'id': c['id'] ?? username.hashCode.abs(),
                                            'friendId': c['id'] ?? username.hashCode.abs(),
                                            'name': displayName,
                                            'username': username,
                                            'avatar': hasAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                            'status': c['status'] ?? 'Online',
                                          });
                                        }
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                        backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                                        child: !hasAvatar
                                            ? Text(
                                                displayName[0].toUpperCase(),
                                                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        displayName,
                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        c['username'] != null ? '@${c['username']}' : (c['msg']?.toString() ?? ''),
                                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                      ),
                                      trailing: const Icon(Icons.chat, color: AppTheme.primaryGreen, size: 20),
                                    );
                                  }),
                                ],
                              ],
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = chats.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] as String? ?? '').toLowerCase();
      final username = (c['username'] as String? ?? '').toLowerCase();
      final msg = (c['msg'] as String? ?? '').toLowerCase();
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
                                      displayName[0].toUpperCase(),
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
