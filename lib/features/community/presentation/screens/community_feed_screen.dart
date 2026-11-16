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
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';

class CommunityFeedScreen extends ConsumerStatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  ConsumerState<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends ConsumerState<CommunityFeedScreen> {
  int selectedTab = 0; // 0: Feed, 1: Trending, 2: Chats
  String _chatSearchQuery = '';
  StreamSubscription<Map<String, dynamic>>? _communitySub;
  StreamSubscription<Map<String, dynamic>>? _chatInboxSub;
  StreamSubscription<Map<String, dynamic>>? _personalInboxSub;

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

  int get _unreadCount => friendsList.fold<int>(
        0,
        (sum, f) => sum + ((f['unread'] is num) ? (f['unread'] as num).toInt() : 0),
      );

  static final List<Map<String, dynamic>> _defaultDemoFriends = [
    {
      'id': 1001,
      'name': 'Rahul Sharma',
      'username': 'rahul_sharma',
      'role': 'Striker • Titans',
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'lastMsg': 'Are you free for turf match at 7 PM? ⚽',
      'time': '10:20 AM',
      'unread': 2,
      'isOnline': true,
      'status': 'Online',
    },
    {
      'id': 1002,
      'name': 'Alex Johnson',
      'username': 'alex_j',
      'role': 'Midfielder • Play Arena',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'lastMsg': 'Booked slot at Greenfield Arena 👍',
      'time': '9:45 AM',
      'unread': 1,
      'isOnline': true,
      'status': 'Online',
    },
    {
      'id': 1003,
      'name': 'Thunder Strikers FC',
      'username': 'thunder_strikers',
      'role': 'Team Group • 12 members',
      'avatar': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=100',
      'lastMsg': 'Captain John: Lineup for Sunday Summer Cup 🏆',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'status': 'Offline',
    },
    {
      'id': 1004,
      'name': 'David Williams',
      'username': 'david_w',
      'role': 'Goalkeeper • Wolves',
      'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100',
      'lastMsg': 'Clean sheet locked in today! 🧤',
      'time': '2 days ago',
      'unread': 0,
      'isOnline': false,
      'status': 'Offline',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchServerPosts();
    _connectRealtime();
    _fetchConversations();
    _connectChatInbox();

    ref.read(fetchUserProfileProvider.future).then((profile) {
      if (mounted) {
        if (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty) {
          SessionManager.setUsername(profile.fullName!.trim());
        }
        _fetchConversations();
        _connectChatInbox();
      }
    }).catchError((_) {});
  }

  Future<void> _fetchConversations() async {
    final myUname = _getMyUsername();

    // 1. Instantly display cached conversations
    if (myUname.isNotEmpty) {
      final cached = await LocalChatStorage.getConversations(myUname);
      if (mounted && cached.isNotEmpty) {
        setState(() => friendsList = cached);
      }
    }

    if (friendsList.isEmpty) {
      setState(() => friendsList = List<Map<String, dynamic>>.from(_defaultDemoFriends));
    }

    // 2. Fetch from server
    try {
      final dio = ref.read(apiClientProvider);
      final myProfile = ref.read(fetchUserProfileProvider).valueOrNull;

      final res = await dio.get('/community/chat/conversations', queryParameters: {
        if (myUname.isNotEmpty) 'username': myUname,
        if (myProfile?.id != null) 'user_id': myProfile!.id,
      });

      if (res.statusCode == 200 && res.data is List) {
        final serverChats = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted && serverChats.isNotEmpty) {
          setState(() {
            friendsList = serverChats;
          });
          for (final c in serverChats) {
            LocalChatStorage.updateConversation(
              myUsername: myUname,
              partnerUsername: c['username'] ?? '',
              partnerName: c['name'] ?? '',
              lastMsg: c['lastMsg'] ?? '',
              time: c['time'] ?? 'Just now',
              partnerAvatar: c['avatar'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Conversations load note: $e');
    }
  }

  void _connectChatInbox() {
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

      _chatInboxSub?.cancel();
      _personalInboxSub?.cancel();

      if (myUname.isNotEmpty) {
        _personalInboxSub = realtime.connectToChannel('channel/inbox_$myUname').listen(onIncoming);
      }
      _chatInboxSub = realtime.connectToChannel('chat_inbox').listen(onIncoming);
    } catch (_) {}
  }

  Future<void> _fetchServerPosts() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/community/');
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final serverPosts = (res.data as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return {
            'id': m['id'] ?? DateTime.now().millisecondsSinceEpoch,
            'author': m['author'] ?? 'Alex Johnson',
            'role': 'Player',
            'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
            'time': m['created_at'] ?? 'Just now',
            'content': m['content'] ?? '',
            'image': m['image_url'] ?? 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
            'likes': m['likes_count'] ?? 0,
            'isLiked': false,
            'comments': m['comments_count'] ?? 0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            for (final sp in serverPosts) {
              if (!posts.any((p) => p['id'] == sp['id'])) {
                posts.insert(0, sp);
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Community feed fetch fallback: $e');
    }
  }

  void _connectRealtime() {
    final stream = ref.read(realtimeServiceProvider).connectToChannel('community');
    _communitySub = stream.listen((event) {
      debugPrint('Real-time community event: $event');
      final eventType = event['type'] as String?;
      if (eventType == 'new_post') {
        final newPost = {
          'id': event['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'author': event['author'] ?? 'Player',
          'role': event['role'] ?? 'Active Player',
          'avatar': event['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
          'time': event['time'] ?? 'Just now',
          'content': event['content'] ?? '',
          'image': event['image'] ?? 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
          'likes': event['likes'] ?? 0,
          'isLiked': false,
          'comments': event['comments'] ?? 0,
          'isLive': true,
        };

        if (mounted) {
          setState(() {
            posts.removeWhere((p) => p['id'] == newPost['id']);
            posts.insert(0, newPost);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.forum, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('⚡ New post from ${newPost['author']}!'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.cardDark,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (eventType == 'post_liked') {
        final postId = event['post_id'];
        final likes = event['likes'] as num?;
        if (mounted) {
          setState(() {
            final idx = posts.indexWhere((p) => p['id'] == postId);
            if (idx != -1 && likes != null) {
              posts[idx]['likes'] = likes.toInt();
            }
          });
        }
      } else if (eventType == 'post_comment') {
        final postId = event['post_id'] is num ? (event['post_id'] as num).toInt() : null;
        if (postId != null && mounted) {
          setState(() {
            final pIdx = posts.indexWhere((p) => p['id'] == postId);
            if (pIdx != -1) {
              final curr = (posts[pIdx]['comments'] is num) ? (posts[pIdx]['comments'] as num).toInt() : 0;
              posts[pIdx]['comments'] = curr + 1;
            }
            final list = _postComments.putIfAbsent(postId, () => []);
            list.add({
              'author': event['author'] ?? 'Player',
              'avatar': event['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
              'text': event['comment'] ?? '',
              'time': event['time'] ?? 'Just now',
            });
          });
        }
      } else if (eventType == 'new_user_joined') {
        final name = event['name'] as String? ?? 'A new player';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 $name just joined the Turf Community!'),
              backgroundColor: AppTheme.cardDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _communitySub?.cancel();
    _chatInboxSub?.cancel();
    _personalInboxSub?.cancel();
    super.dispose();
  }

  final List<Map<String, dynamic>> posts = [
    {
      'id': 1,
      'author': 'Alex Johnson',
      'role': 'Midfielder • Titans',
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      'time': '2 hrs ago • Play Arena',
      'content': 'Great match last night! ⚽🔥 What an incredible comeback victory in the 88th minute! Shoutout to the defense.',
      'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
      'likes': 104,
      'isLiked': false,
      'comments': 24,
    },
    {
      'id': 2,
      'author': 'Rahul Sharma',
      'role': 'Turf Coach',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'time': '4 hrs ago • Greenfield Arena',
      'content': 'Morning football drills underway! Working on short passing rhythm and high pressing transitions. 🏃‍♂️💨',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      'likes': 88,
      'isLiked': true,
      'comments': 12,
    },
    {
      'id': 3,
      'author': 'David Williams',
      'role': 'Goalkeeper',
      'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100',
      'time': 'Yesterday • City Arena',
      'content': 'Clean sheet locked in! 🧤 Nothing gets past this wall today. Excited for the weekend tournament playoffs!',
      'image': 'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=800',
      'likes': 142,
      'isLiked': false,
      'comments': 31,
    },
  ];

  List<Map<String, dynamic>> friendsList = [];

  final Map<int, List<Map<String, dynamic>>> _postComments = {
    1: [
      {
        'author': 'Rahul Sharma',
        'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
        'text': 'What an incredible winner in stoppage time! 🔥',
        'time': '1 hr ago',
      },
      {
        'author': 'David Williams',
        'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100',
        'text': 'Defense held strong! See you on Friday 🧤',
        'time': '35 mins ago',
      },
    ],
    2: [
      {
        'author': 'Alex Johnson',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        'text': 'Drills looked intense, coach! Ready for the match ⚽',
        'time': '2 hrs ago',
      },
    ],
    3: [
      {
        'author': 'Rahul Sharma',
        'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
        'text': 'Brick wall performance! 🧤🔥',
        'time': 'Yesterday',
      },
    ],
  };

  void _showCreatePostDialog() {
    final textController = TextEditingController();
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
                Text('Create Post', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Share your match highlights, scorelines, or team shoutout...',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  if (text.isNotEmpty) {
                    final newPostId = DateTime.now().millisecondsSinceEpoch;
                    final newPost = {
                      'id': newPostId,
                      'author': 'You',
                      'role': 'Striker • Player',
                      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      'time': 'Just now',
                      'content': text,
                      'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
                      'likes': 1,
                      'isLiked': true,
                      'comments': 0,
                    };

                    setState(() {
                      posts.insert(0, newPost);
                    });

                    // Real-time broadcast to all community participants
                    ref.read(realtimeServiceProvider).emitToChannel('community', {
                      'type': 'new_post',
                      'id': newPostId,
                      'author': 'You',
                      'role': 'Striker • Player',
                      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      'time': 'Just now',
                      'content': text,
                      'image': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
                      'likes': 1,
                      'comments': 0,
                    });

                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);

                    // REST call to persist
                    try {
                      final dio = ref.read(apiClientProvider);
                      await dio.post('/community/', data: {
                        'content': text,
                        'image_url': 'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
                      });
                    } catch (e) {
                      debugPrint('Community post REST fallback: $e');
                    }
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('⚡ Post published to Community live!'), backgroundColor: AppTheme.primaryGreen),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Publish Post', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithAuthor(String author, String? avatar) {
    final cleanUname = author.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final dynamicId = cleanUname.hashCode.abs();
    final fallbackAvatar = (avatar != null && avatar.startsWith('http'))
        ? avatar
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

    final friendItem = {
      'id': dynamicId,
      'friendId': dynamicId,
      'name': author,
      'username': cleanUname,
      'role': 'Community Player',
      'avatar': fallbackAvatar,
      'lastMsg': 'Chat started from community feed',
      'time': 'Just now',
      'unread': 0,
      'isOnline': true,
      'status': 'Online',
    };

    if (!friendsList.any((f) => (f['username'] ?? '').toString().toLowerCase() == cleanUname)) {
      setState(() => friendsList.insert(0, friendItem));
    }

    context.push('/friend-chat', extra: friendItem);
  }

  void _showPostCommentsDialog(Map<String, dynamic> post) {
    final commentCtrl = TextEditingController();
    final postId = (post['id'] is num) ? (post['id'] as num).toInt() : 0;
    final commentsList = _postComments.putIfAbsent(postId, () => []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final sheetHeight = MediaQuery.of(ctx).size.height * 0.8;

          void sendComment() {
            final text = commentCtrl.text.trim();
            if (text.isEmpty) return;

            final myName = _getMyUsername();
            final displayName = (myName.isNotEmpty && myName.toLowerCase() != 'player')
                ? (myName[0].toUpperCase() + myName.substring(1))
                : 'You';

            final newComment = {
              'author': displayName,
              'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
              'text': text,
              'time': 'Just now',
            };

            setModalState(() {
              commentsList.add(newComment);
              commentCtrl.clear();
            });

            setState(() {
              final cur = (post['comments'] is num) ? (post['comments'] as num).toInt() : 0;
              post['comments'] = cur + 1;
            });

            // WebSocket broadcast
            try {
              ref.read(realtimeServiceProvider).emitToChannel('community', {
                'type': 'post_comment',
                'post_id': postId,
                'author': displayName,
                'comment': text,
                'time': 'Just now',
              });
            } catch (_) {}

            // Backend REST call
            try {
              final dio = ref.read(apiClientProvider);
              dio.post('/community/$postId/comments', data: {
                'author': displayName,
                'comment': text,
              }).catchError((_) {});
            } catch (_) {}
          }

          return Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1B12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
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
                    Expanded(
                      child: Text(
                        'Discussion & Comments',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openChatWithAuthor(post['author'], post['avatar']);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 15, color: AppTheme.primaryGreen),
                      label: Text(
                        'DM Author',
                        style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textGrey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                // Post excerpt preview
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16251B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF243A2B)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(post['avatar'] ?? 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${post['author']}: "${post['content']}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Comments list
                Expanded(
                  child: commentsList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF384F3F)),
                              const SizedBox(height: 8),
                              Text(
                                'No comments yet. Be the first to reply!',
                                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: commentsList.length,
                          separatorBuilder: (_, __) => const Divider(color: Color(0xFF142418), height: 1),
                          itemBuilder: (context, idx) {
                            final c = commentsList[idx];
                            final cAuthor = (c['author'] ?? 'Player').toString();
                            final cText = (c['text'] ?? '').toString();
                            final cTime = (c['time'] ?? 'Just now').toString();
                            final cAvatar = (c['avatar'] ?? '').toString().trim();
                            final hasAv = cAvatar.startsWith('http');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                    backgroundImage: hasAv ? NetworkImage(cAvatar) : null,
                                    child: !hasAv
                                        ? Text(
                                            cAuthor.isNotEmpty ? cAuthor[0].toUpperCase() : '?',
                                            style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              cAuthor,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            Text(
                                              cTime,
                                              style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          cText,
                                          style: GoogleFonts.poppins(color: const Color(0xFFD6E2D9), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Comment text input bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16281C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF26422F)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Add a comment or message on this match...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF708577), fontSize: 12.5),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onSubmitted: (_) => sendComment(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppTheme.primaryGreen, size: 20),
                        onPressed: sendComment,
                      ),
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

  void _showNewChatDialog([String initialQuery = '']) {
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

            // Immediately filter local friends for fast responsive UI
            final localMatches = friendsList.where((f) {
              final name = (f['name'] ?? '').toString().toLowerCase();
              final uname = (f['username'] ?? '').toString().toLowerCase();
              final ql = cleanQ.toLowerCase();
              return name.contains(ql) || uname.contains(ql);
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
                debugPrint('Note: /users/search api lookup: $e');
                if (ctx.mounted) {
                  setModalState(() => isSearching = false);
                }
              }
            });
          }

          // Trigger initial search if provided
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

                // Results / List Area
                Expanded(
                  child: isSearching
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        )
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
                                                    if (!friendsList.any((f) => (f['username'] ?? '').toString().toLowerCase() == rawUname.toLowerCase())) {
                                                      setState(() => friendsList.insert(0, friendItem));
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

                                    void startChatWithUser() {
                                      Navigator.pop(ctx);
                                      final fallbackAvatar = hasValidAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';
                                      final dynamicId = user['id'] ?? username.hashCode.abs();
                                      final friendItem = {
                                        'id': dynamicId,
                                        'friendId': dynamicId,
                                        'name': name,
                                        'username': username,
                                        'role': role,
                                        'avatar': fallbackAvatar,
                                        'lastMsg': 'Chat started',
                                        'time': 'Just now',
                                        'unread': 0,
                                        'isOnline': true,
                                        'status': 'Online',
                                      };
                                      final existingIdx = friendsList.indexWhere(
                                        (f) => (f['username'] ?? '').toString().toLowerCase() == username.toLowerCase(),
                                      );
                                      if (existingIdx == -1) {
                                        setState(() => friendsList.insert(0, friendItem));
                                      }
                                      context.push('/friend-chat', extra: friendItem);
                                    }

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      onTap: startChatWithUser,
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                        backgroundImage: hasValidAvatar ? NetworkImage(avatar) : null,
                                        child: !hasValidAvatar
                                            ? Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: GoogleFonts.poppins(
                                                  color: AppTheme.primaryGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                                        onPressed: startChatWithUser,
                                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.black),
                                        label: Text(
                                          'Chat',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
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
                                if (friendsList.isEmpty) ...[
                                  const SizedBox(height: 40),
                                  Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF3B5242)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Search Friends by Username',
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Text(
                                            'Type your friend’s username or name in the search bar above to start a direct 1-on-1 chat.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Recent Conversations',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF8DA394),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...friendsList.map((f) {
                                    final fName = (f['name'] ?? 'Friend').toString().trim();
                                    final fDisplay = fName.isNotEmpty ? fName : 'Friend';
                                    final fAvatar = (f['avatar'] ?? '').toString().trim();
                                    final fHasAvatar = fAvatar.startsWith('http');
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        context.push('/friend-chat', extra: {
                                          'id': f['id'],
                                          'friendId': f['id'],
                                          'name': fDisplay,
                                          'username': f['username'] ?? fDisplay.toLowerCase(),
                                          'avatar': fHasAvatar ? fAvatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                                          'status': f['status'] ?? 'Online',
                                        });
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                        backgroundImage: fHasAvatar ? NetworkImage(fAvatar) : null,
                                        child: !fHasAvatar
                                            ? Text(
                                                fDisplay[0].toUpperCase(),
                                                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Text(fDisplay, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                                      subtitle: Text(
                                        f['username'] != null ? '@${f['username']}' : (f['lastMsg'] ?? 'Active chat'),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              selectedTab == 2 ? 'Community Chats' : 'Community',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
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
        actions: [
          IconButton(
            icon: Icon(
              selectedTab == 2 ? Icons.chat : Icons.add_circle_outline,
              color: AppTheme.primaryGreen,
            ),
            tooltip: selectedTab == 2 ? 'New Chat' : 'Create Post',
            onPressed: selectedTab == 2 ? _showNewChatDialog : _showCreatePostDialog,
          ),
          // Chat shortcut button with unread count
          GestureDetector(
            onTap: () => setState(() => selectedTab = 2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selectedTab == 2 ? AppTheme.primaryGreen.withValues(alpha: 0.18) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedTab == 2 ? Icons.forum_rounded : Icons.forum_outlined,
                    color: selectedTab == 2 ? AppTheme.primaryGreen : AppTheme.textWhite,
                    size: 22,
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Center(child: BysProfileAvatar(size: 34)),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Row (Feed, Trending, Chats)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _tabItem(0, 'Feed', null),
                  _tabItem(1, 'Trending', null),
                  _tabItem(2, 'Chats', _unreadCount > 0 ? _unreadCount : null),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Tab Content
            Expanded(
              child: selectedTab == 2 ? _buildChatsTab() : _buildFeedTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: selectedTab == 2
          ? FloatingActionButton(
              onPressed: _showNewChatDialog,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.chat, color: Colors.black),
            )
          : null,
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 3),
    );
  }

  Widget _tabItem(int idx, String title, int? badgeCount) {
    final isSelected = selectedTab == idx;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = idx),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E3827),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 55,
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // 1. WhatsApp-like Chats Tab
  Widget _buildChatsTab() {
    final filtered = friendsList.where((f) {
      final q = _chatSearchQuery.toLowerCase();
      final name = (f['name'] as String? ?? '').toLowerCase();
      final username = (f['username'] as String? ?? '').toLowerCase();
      final msg = (f['lastMsg'] as String? ?? '').toLowerCase();
      return name.contains(q) || username.contains(q) || msg.contains(q);
    }).toList();

    return Column(
      children: [
        // WhatsApp-style Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: TextField(
                    style: GoogleFonts.poppins(color: AppTheme.textWhite, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search username, friend name, or messages...',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF88A090), size: 20),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _chatSearchQuery = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showNewChatDialog(_chatSearchQuery),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryGreen, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Active / Online Friends Horizontal Row
        Container(
          height: 90,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // New Chat Action Avatar
              GestureDetector(
                onTap: () => _showNewChatDialog(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF14241B),
                          border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                        child: const Icon(Icons.add, color: AppTheme.primaryGreen, size: 26),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'New Chat',
                        style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textWhite),
                      ),
                    ],
                  ),
                ),
              ),

              // Friends Online Avatars
              ...friendsList.map((friend) {
                final isOnline = friend['isOnline'] == true;
                final fName = (friend['name'] ?? 'Friend').toString().trim();
                final displayName = fName.isNotEmpty ? fName : 'Friend';
                final username = (friend['username'] ?? displayName.toLowerCase()).toString();
                final avatar = (friend['avatar'] ?? '').toString().trim();
                final hasAvatar = avatar.startsWith('http');
                final dynamicId = friend['id'] ?? username.hashCode.abs();

                return GestureDetector(
                  onTap: () {
                    context.push('/friend-chat', extra: {
                      'id': dynamicId,
                      'friendId': dynamicId,
                      'name': displayName,
                      'username': username,
                      'avatar': hasAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                      'status': friend['status'] ?? 'Online',
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isOnline ? AppTheme.primaryGreen : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                                child: !hasAvatar
                                    ? Text(
                                        displayName[0].toUpperCase(),
                                        style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 3,
                                bottom: 3,
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.backgroundBlack, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 58,
                          child: Text(
                            ((friend['name'] as String?) ?? 'Friend').split(' ')[0],
                            style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textWhite),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(color: Color(0xFF162319), thickness: 1),

        // Chat Conversations List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Color(0xFF3B4E41)),
                      const SizedBox(height: 10),
                      Text(
                        'No conversation found',
                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _showNewChatDialog(_chatSearchQuery),
                        icon: const Icon(Icons.person_search_rounded, size: 16, color: Colors.black),
                        label: Text(
                          _chatSearchQuery.isNotEmpty
                              ? 'Search all players for "$_chatSearchQuery"'
                              : 'Find Player by Username',
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
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF131F17), height: 1),
                  itemBuilder: (context, index) {
                    final chat = filtered[index];
                    final unread = (chat['unread'] is num) ? (chat['unread'] as num).toInt() : 0;
                    final cName = (chat['name'] ?? 'Friend').toString().trim();
                    final displayName = cName.isNotEmpty ? cName : 'Friend';
                    final username = (chat['username'] ?? displayName.toLowerCase()).toString();
                    final avatar = (chat['avatar'] ?? '').toString().trim();
                    final hasAvatar = avatar.startsWith('http');
                    final time = (chat['time'] ?? 'Just now').toString();
                    final lastMsg = (chat['lastMsg'] ?? '').toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      onTap: () {
                        context.push('/friend-chat', extra: {
                          'id': chat['id'] ?? username.hashCode.abs(),
                          'friendId': chat['id'] ?? username.hashCode.abs(),
                          'name': displayName,
                          'username': username,
                          'avatar': hasAvatar ? avatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
                          'status': chat['status'] ?? 'Online',
                        });
                      },
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            backgroundImage: hasAvatar ? NetworkImage(avatar) : null,
                            child: !hasAvatar
                                ? Text(
                                    displayName[0].toUpperCase(),
                                    style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          if (chat['isOnline'] == true)
                            Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.backgroundBlack, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                                fontSize: 14.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            time,
                            style: GoogleFonts.poppins(
                              color: unread > 0 ? AppTheme.primaryGreen : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          if (unread == 0) ...[
                            const Icon(Icons.done_all, size: 14, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              lastMsg,
                              style: GoogleFonts.poppins(
                                color: unread > 0 ? AppTheme.textWhite : AppTheme.textGrey,
                                fontSize: 12.5,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 2. Feed & Trending Tab
  Widget _buildFeedTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Share quick input bar
        GestureDetector(
          onTap: _showCreatePostDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                ),
                const SizedBox(width: 12),
                Text('Share your match moment...', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13)),
                const Spacer(),
                const Icon(Icons.photo_camera_outlined, color: AppTheme.primaryGreen, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tournament Promo Banner
        GestureDetector(
          onTap: () => context.push('/tournaments'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF00C853)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turf Champions 2025',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Text(
                        'Register your squad now for Summer Cup 2025',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 14),
              ],
            ),
          ),
        ),

        // Community Posts List
        ...posts.map((post) {
          final isLiked = post['isLiked'] as bool;
          final likesCount = post['likes'] as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openChatWithAuthor(post['author'], post['avatar']),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        backgroundImage: (post['avatar'] != null && post['avatar'].toString().trim().startsWith('http'))
                            ? NetworkImage(post['avatar'].toString().trim())
                            : null,
                        child: (post['avatar'] == null || !post['avatar'].toString().trim().startsWith('http'))
                            ? Text(
                                post['author'].toString().isNotEmpty ? post['author'].toString()[0].toUpperCase() : 'P',
                                style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openChatWithAuthor(post['author'], post['avatar']),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['author'],
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            Text(
                              '${post['role']} • ${post['time']}',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                      tooltip: 'Message ${post['author']}',
                      onPressed: () => _openChatWithAuthor(post['author'], post['avatar']),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post['content'],
                  style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textWhite, height: 1.4),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: AppTheme.surfaceDark,
                      child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final newLiked = !isLiked;
                        final newLikesCount = newLiked ? (likesCount + 1) : (likesCount - 1).clamp(0, 99999);
                        setState(() {
                          post['isLiked'] = newLiked;
                          post['likes'] = newLikesCount;
                        });

                        // Emit live update over WebSocket
                        ref.read(realtimeServiceProvider).emitToChannel('community', {
                          'type': 'post_liked',
                          'post_id': post['id'],
                          'likes': newLikesCount,
                        });

                        // REST call
                        if (newLiked) {
                          try {
                            final dio = ref.read(apiClientProvider);
                            await dio.post('/community/${post['id']}/like');
                          } catch (e) {
                            debugPrint('Like REST fallback: $e');
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? AppTheme.errorRed : AppTheme.textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text('${post['likes']}', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () => _showPostCommentsDialog(post),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 6),
                            Text('${post['comments']}', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppTheme.textGrey, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post link copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
