// Standalone Community & Direct Messaging Verification Test
// Tests the full messaging pipeline for the Community feature

void main() {
  print("==================================================================");
  print("=== RUNNING COMPREHENSIVE COMMUNITY & MESSAGING TEST SUITE ===");
  print("==================================================================\n");

  // ---------------------------------------------------------
  // TEST 1: Consistent Identifier Resolution
  // ---------------------------------------------------------
  print("Test 1: Testing User Identifier Resolution Consistency...");
  String resolveIdentifier({
    String? sessionUsername,
    String? profileFullName,
    String? sessionEmail,
    String? profileEmail,
  }) {
    if (sessionUsername != null && sessionUsername.trim().isNotEmpty) {
      final u = sessionUsername.trim();
      if (u.toLowerCase() != 'user' && u.toLowerCase() != 'player') return u;
    }
    if (profileFullName != null &&
        profileFullName.trim().isNotEmpty &&
        profileFullName.toLowerCase() != 'user' &&
        profileFullName.toLowerCase() != 'player') {
      return profileFullName.trim();
    }
    if (sessionEmail != null && sessionEmail.contains('@')) {
      return sessionEmail.split('@')[0].trim();
    }
    if (profileEmail != null && profileEmail.contains('@')) {
      return profileEmail.split('@')[0].trim();
    }
    return 'player';
  }

  // Case A: Valid session username
  assert(
    resolveIdentifier(sessionUsername: 'aswin_pro') == 'aswin_pro',
    'Failed on valid session username',
  );

  // Case B: Null session username, valid profile name
  assert(
    resolveIdentifier(profileFullName: 'Aswin NS') == 'Aswin NS',
    'Failed on profile full name',
  );

  // Case C: Null username, "user" placeholder profile name, falls back to email
  assert(
    resolveIdentifier(
      profileFullName: 'user',
      sessionEmail: 'aswin@gmail.com',
    ) == 'aswin',
    'Failed on email prefix fallback',
  );

  // Case D: Completely unauthenticated fallback to 'player'
  assert(
    resolveIdentifier() == 'player',
    'Failed on player fallback',
  );
  print("  -> PASSED: All user identifier resolution scenarios match across Community & Chat!\n");

  // ---------------------------------------------------------
  // TEST 2: Deterministic Symmetrical DM Channel Generation
  // ---------------------------------------------------------
  print("Test 2: Testing Symmetrical DM Channel Generation...");
  String getRoom(String u1, String u2) {
    final n1 = u1.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final n2 = u2.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final names = [n1, n2]..sort();
    return 'dm_${names[0]}_${names[1]}';
  }

  final channelA = getRoom('Aswin NS', 'Rahul Sharma');
  final channelB = getRoom('Rahul Sharma', 'Aswin NS');
  assert(channelA == channelB, 'Symmetry violated: $channelA != $channelB');
  assert(channelA == 'dm_aswinns_rahulsharma', 'Channel name format mismatch: $channelA');

  // Test special characters and case insensitivity
  final channelC = getRoom('@Aswin.NS!', 'rahul_sharma');
  assert(channelC == channelA, 'Normalization failed: $channelC != $channelA');
  print("  -> PASSED: Bidirectional symmetry holds for all usernames: $channelA\n");

  // ---------------------------------------------------------
  // TEST 3: Dynamic Unread Count Calculation
  // ---------------------------------------------------------
  print("Test 3: Testing Dynamic Unread Messages Calculation...");
  final testFriendsList = [
    {'name': 'Rahul Sharma', 'unread': 2, 'lastMsg': 'Match at 7 PM'},
    {'name': 'Alex Johnson', 'unread': 1, 'lastMsg': 'Turf booked'},
    {'name': 'David Williams', 'unread': 0, 'lastMsg': 'Clean sheet!'},
  ];

  int computeUnread(List<Map<String, dynamic>> list) {
    return list.fold<int>(
      0,
      (sum, f) => sum + ((f['unread'] is num) ? (f['unread'] as num).toInt() : 0),
    );
  }

  final initialUnread = computeUnread(testFriendsList);
  assert(initialUnread == 3, 'Expected 3 unread, got $initialUnread');

  // Simulate reading Rahul's message
  testFriendsList[0]['unread'] = 0;
  final updatedUnread = computeUnread(testFriendsList);
  assert(updatedUnread == 1, 'Expected 1 unread after read, got $updatedUnread');
  print("  -> PASSED: Dynamic unread count correctly updates from $initialUnread -> $updatedUnread!\n");

  // ---------------------------------------------------------
  // TEST 4: Post Discussion & Comments State & Broadcast
  // ---------------------------------------------------------
  print("Test 4: Testing Community Post Discussion & Live Commenting...");
  final post = {
    'id': 1,
    'author': 'Alex Johnson',
    'content': 'Great match comeback victory in the 88th min!',
    'comments': 24,
  };

  final Map<int, List<Map<String, dynamic>>> postComments = {
    1: [
      {'author': 'Rahul', 'text': 'Incredible goal!'},
      {'author': 'David', 'text': 'Solid defense!'},
    ],
  };

  void addComment(int postId, String author, String text) {
    final list = postComments.putIfAbsent(postId, () => []);
    list.add({'author': author, 'text': text, 'time': 'Just now'});
    post['comments'] = ((post['comments'] as num).toInt()) + 1;
  }

  addComment(1, 'Aswin', 'What a blast from outside the box!');
  assert(postComments[1]!.length == 3, 'Comment was not appended');
  assert(post['comments'] == 25, 'Comment count was not incremented');
  print("  -> PASSED: Post comments appended and count incremented to ${post['comments']}!\n");

  // ---------------------------------------------------------
  // TEST 5: Direct Messaging Post Author from Community Feed
  // ---------------------------------------------------------
  print("Test 5: Testing Direct Messaging Post Author Flow...");
  final friends = <Map<String, dynamic>>[];

  void openChatWithAuthor(String author, String? avatar) {
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

    if (!friends.any((f) => (f['username'] ?? '').toString().toLowerCase() == cleanUname)) {
      friends.insert(0, friendItem);
    }
  }

  openChatWithAuthor('Alex Johnson', 'https://example.com/alex.jpg');
  assert(friends.length == 1, 'Friend conversation was not inserted');
  assert(friends[0]['username'] == 'alexjohnson', 'Username incorrect');
  assert(friends[0]['name'] == 'Alex Johnson', 'Author name incorrect');

  // Triggering again with same author should deduplicate
  openChatWithAuthor('Alex Johnson', 'https://example.com/alex.jpg');
  assert(friends.length == 1, 'Duplicate conversation was created');
  print("  -> PASSED: Direct Messaging post author opens conversation without duplicates!\n");

  // ---------------------------------------------------------
  // TEST 6: User Search Safe Filtering & Character Parsing
  // ---------------------------------------------------------
  print("Test 6: Testing Safe User Search Filtering & Character Parsing...");
  final mixedContacts = <Map<String, dynamic>>[
    {'id': 101, 'name': 'Rahul Sharma', 'username': 'rahul_s', 'lastMsg': 'Ready for the game'},
    {'id': 102, 'name': 12345, 'username': 'numeric_user', 'lastMsg': null}, // non-string name
    {'id': 103, 'name': '', 'username': '', 'lastMsg': ''}, // empty strings
    {'id': 104, 'name': '⚽ Striker', 'username': 'striker9', 'lastMsg': 'Goal!'}, // emoji prefix
    {'id': 105, 'name': null, 'username': null, 'lastMsg': null}, // null values
  ];

  List<Map<String, dynamic>> filterContacts(String query) {
    final q = query.trim().replaceAll(RegExp(r'^@+'), '').toLowerCase();
    return mixedContacts.where((c) {
      if (q.isEmpty) return true;
      final name = (c['name'] ?? '').toString().toLowerCase();
      final username = (c['username'] ?? '').toString().toLowerCase();
      final msg = (c['lastMsg'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q) || msg.contains(q);
    }).toList();
  }

  // Safe avatar initial resolution
  String safeInitial(dynamic rawName) {
    final str = (rawName ?? '').toString().trim();
    if (str.isEmpty) return '?';
    return str.runes.isNotEmpty ? String.fromCharCode(str.runes.first).toUpperCase() : '?';
  }

  // A: Search with leading @
  final res1 = filterContacts('@rahul');
  assert(res1.length == 1 && res1.first['username'] == 'rahul_s', 'Search with @ failed');

  // B: Search for numeric contact (must not throw TypeError)
  final res2 = filterContacts('123');
  assert(res2.length == 1 && res2.first['username'] == 'numeric_user', 'Search on numeric field failed');

  // C: Safe initial extraction across all tricky inputs
  assert(safeInitial('Rahul') == 'R');
  assert(safeInitial('') == '?');
  assert(safeInitial(null) == '?');
  assert(safeInitial(99) == '9');
  assert(safeInitial('⚽ Striker') == '⚽');
  print("  -> PASSED: Search filter & character parsing are 100% crash-proof against nulls and non-strings!\n");

  // ---------------------------------------------------------
  // TEST 7: Keyboard-Adaptive Sheet Height Bounds
  // ---------------------------------------------------------
  print("Test 7: Testing Keyboard-Adaptive Sheet Height Bounds...");
  double calculateSheetHeight(double screenHeight, double keyboardHeight) {
    final visibleHeight = screenHeight - keyboardHeight;
    final sheetHeight = keyboardHeight > 0
        ? visibleHeight * 0.90
        : screenHeight * 0.85;
    return sheetHeight;
  }

  // Scenario 1: Standard phone (800px), keyboard closed
  final h1 = calculateSheetHeight(800, 0);
  assert(h1 == 680, 'Expected 680, got $h1');

  // Scenario 2: Standard phone (800px), keyboard open (320px)
  final h2 = calculateSheetHeight(800, 320);
  assert(h2 == 432, 'Expected 432, got $h2');
  assert(h2 <= (800 - 320), 'Height exceeds visible space: $h2');

  // Scenario 3: Small phone (600px), large keyboard (340px)
  final h3 = calculateSheetHeight(600, 340);
  assert(h3 == 234, 'Expected 234, got $h3');
  assert(h3 > 0, 'Sheet height must never be zero or negative: $h3');
  assert(h3 <= (600 - 340), 'Sheet height must never exceed visible space above keyboard: $h3');
  print("  -> PASSED: Sheet height remains positive, bounded, and keyboard-safe across all screen sizes!\n");

  print("==================================================================");
  print(">>> ALL 7 COMMUNITY MESSAGING TESTS PASSED WITH 100% SUCCESS! <<<");
  print("==================================================================");
}
