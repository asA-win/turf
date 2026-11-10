import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _envWsUrl = String.fromEnvironment('WS_URL');

  // Single source of truth for REST API base URL
  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) return _envApiUrl;

    if (kDebugMode) {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        return 'http://127.0.0.1:8000/api/v1';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    }
    return 'https://turf-29zo.onrender.com/api/v1';
  }

  // Single source of truth for WebSocket base URL
  static String get baseWsUrl {
    if (_envWsUrl.isNotEmpty) return _envWsUrl;

    if (kDebugMode) {
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        return 'ws://127.0.0.1:8000/api/v1/ws';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ws://10.0.2.2:8000/api/v1/ws';
      }
    }
    return 'wss://turf-29zo.onrender.com/api/v1/ws';
  }

  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get turfsUrl => '$baseUrl/turfs';
  static String get bookingsUrl => '$baseUrl/bookings';
  
  // Timeout values
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
