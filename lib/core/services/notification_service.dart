import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

part 'notification_service.g.dart';

@Riverpod(keepAlive: true)
class NotificationService extends _$NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _isInitialized = false;
  String? _lastUserId;

  @override
  FutureOr<void> build() async {
    // Watch user profile
    final userProfileAsync = ref.watch(fetchUserProfileProvider);
    
    final userProfile = userProfileAsync.value;
    if (userProfile != null) {
      // If user changed or not initialized yet
      if (!_isInitialized || _lastUserId != userProfile.id.toString()) {
        _isInitialized = true;
        _lastUserId = userProfile.id.toString();
        await _initialize();
      }
    } else if (userProfileAsync.hasError || (userProfileAsync.hasValue && userProfile == null)) {
      // Reset if logged out or error
      _isInitialized = false;
      _lastUserId = null;
    }
  }

  Future<void> _initialize() async {
    try {
      // 1. Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        
        // 2. Get the token (with Web support if needed)
        String? token;
        try {
          if (kIsWeb) {
            // Web requires a VAPID key for many browsers. 
            // If you get errors here on Web, you must provide a valid vapidKey.
            token = await _fcm.getToken(); 
          } else {
            token = await _fcm.getToken();
          }
        } catch (e) {
          debugPrint('Error getting FCM token: $e');
        }

        if (token != null) {
          await _sendTokenToBackend(token);
        }

        // 3. Listen for token refreshes
        _fcm.onTokenRefresh.listen((newToken) {
          _sendTokenToBackend(newToken);
        });
      }
      
      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          debugPrint('Message notification: ${message.notification?.title}');
        }
      });
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post('/users/fcm-token', data: {'token': token});
      debugPrint('FCM Token synced with backend');
    } catch (e) {
      // Don't flood logs with connection errors if server is unstable
      if (e is! Exception) return; 
      debugPrint('Failed to sync FCM token with backend: $e');
    }
  }
}
