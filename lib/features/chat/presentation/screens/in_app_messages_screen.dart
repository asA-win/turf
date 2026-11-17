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

  void _showUserSearchDialog([String initialQuery = '']) {
    final searchCtrl = TextEditingController(text: initialQuery);
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool hasTriggeredInitialSearch = false;
    Timer? debounceTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void doSearch(String query) {
            debounceTimer?.cancel();
            final cleanQ = query.trim().replaceAll(RegExp(r'^@+'), '').trim();

            if (cleanQ.isEmpty) {
              if (ctx.mounted) {
                setModalState(() {
                  searchResults = [];
                  isSearching = false;
                });
              }
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

            if (ctx.mounted) {
              setModalState(() {
                searchResults = List<Map<String, dynamic>>.from(localMatches);
                isSearching = true;
              });
            }

            debounceTimer = Timer(const Duration(milliseconds: 250), () async {
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

          if (initialQuery.isNotEmpty && !hasTriggeredInitialSearch) {
            hasTriggeredInitialSearch = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) doSearch(initialQuery);
            });
          }

          void startChatWithUser(Map<String, dynamic> friendItem) {
            final rootContext = this.context;
            Navigator.pop(ctx);
            final uname = (friendItem['username'] ?? '').toString().toLowerCase();
            final existingIdx = chats.indexWhere(
              (c) => (c['username'] ?? '').toString().toLowerCase() == uname,
            );
            if (existingIdx == -1) {
              setState(() {
                chats.insert(0, {
                  'id': friendItem['id'],
                  'friendId': friendItem['id'],
                  'name': friendItem['name'],
                  'username': friendItem['username'],
                  'msg': 'Chat started',
                  'time': 'Just now',
                  'unread': 0,
                  'type': 'friend',
                  'avatar': friendItem['avatar'],
                });
              });
            }
            if (rootContext.mounted) {
              rootContext.push('/friend-chat', extra: friendItem);
            }
          }

          return FractionallySizedBox(
            heightFactor: 0.88,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Scaffold(
                backgroundColor: const Color(0xFF132218),
                resizeToAvoidBottomInset: true,
                body: SafeArea(
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
                                Text(
                                  'Find Friends & Chat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: AppTheme.textGrey, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Search for friends with their username or name to start chatting:',
                              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11.5),
                            ),
                            const SizedBox(height: 10),

                            // Search Box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3122),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                              ),
                              child: TextField(
                                controller: searchCtrl,
                                autofocus: true,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Search username (e.g. user12, user31) or name...',
                                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF88A090), fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen, size: 20),
                                  suffixIcon: searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                                          onPressed: () {
                                            searchCtrl.clear();
                                            doSearch('');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onChanged: doSearch,
                              ),
                            ),
                            if (isSearching) ...[
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
                    child: (searchCtrl.text.trim().isNotEmpty)
                        ? (searchResults.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSearching) ...[
                                          const CircularProgressIndicator(color: AppTheme.primaryGreen),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Searching platform players...',
                                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                            Container(
                                              padding: const EdgeInsets.all(18),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF132318),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFF26422F)),
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final rawQuery = searchCtrl.text.trim().replaceAll(RegExp(r'^@+'), '').trim();
                                                  final cleanQuery = rawQuery.isNotEmpty ? rawQuery : 'player';
                                                  final initial = cleanQuery.characters.isNotEmpty ? cleanQuery.characters.first.toUpperCase() : '?';

                                                  return Column(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 28,
                                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                                        child: Text(
                                                          initial,
                                                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        '@$cleanQuery',
                                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Start a 1-on-1 direct conversation with @$cleanQuery right now!',
                                                        textAlign: TextAlign.center,
                                                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11.5),
                                                      ),
                                                      const SizedBox(height: 14),
                                                      ElevatedButton.icon(
                                                        onPressed: () {
                                                          Navigator.pop(ctx);
                                                          final dynamicId = cleanQuery.hashCode.abs();
                                                          final displayName = cleanQuery.characters.isNotEmpty
                                                              ? cleanQuery.characters.first.toUpperCase() + cleanQuery.characters.skip(1).toString()
                                                              : 'Friend';
                                                          final friendItem = {
                                                            'id': dynamicId,
                                                            'friendId': dynamicId,
                                                            'name': displayName,
                                                            'username': cleanQuery,
                                                            'role': 'Community Player',
                                                            'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                                            'lastMsg': 'Chat started',
                                                            'time': 'Just now',
                                                            'unread': 0,
                                                            'isOnline': true,
                                                            'status': 'Online',
                                                          };
                                                          startChatWithUser(friendItem);
                                                        },
                                                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
                                                        label: Text(
                                                          'Chat with @$cleanQuery',
                                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.primaryGreen,
                                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, idx) {
                                      final user = searchResults[idx];
                                      final rawName = (user['name'] ?? '').toString().trim();
                                      final name = rawName.isNotEmpty ? rawName : 'Player';
                                      final rawUname = (user['username'] ?? '').toString().trim();
                                      final username = rawUname.isNotEmpty ? rawUname : name.toLowerCase();
                                      final role = (user['role'] ?? 'Active Player').toString();
                                      final avatar = (user['avatar'] ?? '').toString().trim();
                                      final hasValidAvatar = avatar.startsWith('http');
                                      final initial = name.characters.isNotEmpty ? name.characters.first.toUpperCase() : '?';

                                      final dynamicId = user['id'] ?? username.hashCode.abs();
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
                                            onTap: () => startChatWithUser(friendItem),
                                            borderRadius: BorderRadius.circular(14),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                                    backgroundImage: hasValidAvatar ? NetworkImage(avatar) : null,
                                                    onBackgroundImageError: hasValidAvatar ? (_, __) {} : null,
                                                    child: !hasValidAvatar
                                                        ? Text(
                                                            initial,
                                                            style: GoogleFonts.poppins(
                                                              color: AppTheme.primaryGreen,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
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
                                  if (chats.isEmpty) ...[
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
                                    ...chats.map((c) {
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
                                            onTap: () {
                                              if (c['type'] == 'team') {
                                                Navigator.pop(ctx);
                                                final rootContext = this.context;
                                                if (rootContext.mounted) {
                                                  rootContext.push('/team-chat');
                                                }
                                              } else {
                                                startChatWithUser(friendItem);
                                              }
                                            },
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
            ),
          );
        },
      ),
    ).then((_) {
      debounceTimer?.cancel();
      searchCtrl.dispose();
    });
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
