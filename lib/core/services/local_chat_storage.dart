import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalChatStorage {
  static const String _historyPrefix = 'chat_hist_';
  static const String _convsPrefix = 'chat_convs_';

  /// Save direct message to persistent room history
  static Future<void> saveMessage(String roomId, Map<String, dynamic> msg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_historyPrefix$roomId';
      final list = prefs.getStringList(key) ?? [];

      final text = (msg['text'] ?? '').toString().trim();
      final sender = (msg['sender'] ?? msg['sender_name'] ?? '').toString().trim();
      final time = (msg['time'] ?? '').toString().trim();
      final isMe = msg['isMe'] == true;

      // Deduplicate to avoid repeating identical items
      final exists = list.any((item) {
        try {
          final m = jsonDecode(item) as Map<String, dynamic>;
          final mText = (m['text'] ?? '').toString().trim();
          final mSender = (m['sender'] ?? m['sender_name'] ?? '').toString().trim();
          return mText == text && (m['isMe'] == isMe || mSender == sender);
        } catch (_) {
          return false;
        }
      });

      if (!exists) {
        list.add(jsonEncode({
          'id': msg['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'sender': sender.isNotEmpty ? sender : (isMe ? 'Me' : 'Player'),
          'sender_name': sender,
          'sender_id': msg['sender_id'],
          'isMe': isMe,
          'text': text,
          'time': time.isNotEmpty ? time : 'Just now',
          'timestamp': DateTime.now().toIso8601String(),
        }));
        if (list.length > 250) {
          list.removeAt(0);
        }
        await prefs.setStringList(key, list);
      }
    } catch (e) {
      debugPrint('[LOCAL CHAT STORAGE] Error saving message: $e');
    }
  }

  /// Get cached messages for a room
  static Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_historyPrefix$roomId';
      final list = prefs.getStringList(key) ?? [];
      return list.map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map)).toList();
    } catch (e) {
      debugPrint('[LOCAL CHAT STORAGE] Error loading messages: $e');
      return [];
    }
  }

  /// Save or update conversation summary for a user
  static Future<void> updateConversation({
    required String myUsername,
    required String partnerUsername,
    required String partnerName,
    required String lastMsg,
    required String time,
    String? partnerAvatar,
    int? partnerId,
  }) async {
    try {
      final cleanMy = myUsername.trim().toLowerCase();
      final cleanPartner = partnerUsername.trim().toLowerCase();
      if (cleanMy.isEmpty || cleanPartner.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final key = '$_convsPrefix$cleanMy';
      final list = prefs.getStringList(key) ?? [];

      final current = list.map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map)).toList();
      current.removeWhere((c) => (c['username'] ?? '').toString().toLowerCase() == cleanPartner);

      final displayName = partnerName.isNotEmpty
          ? partnerName
          : (cleanPartner.length > 1
              ? cleanPartner[0].toUpperCase() + cleanPartner.substring(1)
              : cleanPartner);

      final dynamicId = partnerId ?? cleanPartner.hashCode.abs();

      current.insert(0, {
        'id': dynamicId,
        'friendId': dynamicId,
        'name': displayName,
        'username': cleanPartner,
        'msg': lastMsg,
        'lastMsg': lastMsg,
        'time': time,
        'unread': 0,
        'type': 'friend',
        'avatar': partnerAvatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'isOnline': true,
        'status': 'Online',
        'role': 'Community Player',
      });

      final encoded = current.map((c) => jsonEncode(c)).toList();
      await prefs.setStringList(key, encoded);
    } catch (e) {
      debugPrint('[LOCAL CHAT STORAGE] Error updating conversation: $e');
    }
  }

  /// Get cached conversations for a user
  static Future<List<Map<String, dynamic>>> getConversations(String myUsername) async {
    try {
      final cleanMy = myUsername.trim().toLowerCase();
      if (cleanMy.isEmpty) return [];

      final prefs = await SharedPreferences.getInstance();
      final key = '$_convsPrefix$cleanMy';
      final list = prefs.getStringList(key) ?? [];
      return list.map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map)).toList();
    } catch (e) {
      debugPrint('[LOCAL CHAT STORAGE] Error loading conversations: $e');
      return [];
    }
  }
}
