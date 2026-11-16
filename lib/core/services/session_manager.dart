import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turf_app/core/constants/api_constants.dart';

const _secureStorage = FlutterSecureStorage();

class SessionManager {
  static String? _cachedToken;
  static String? _cachedEmail;
  static String? _cachedPassword;
  static String? _cachedUsername;
  static bool _isRefreshing = false;

  static String? get token => _cachedToken;
  static String? get email => _cachedEmail;
  static String? get username => _cachedUsername ?? (_cachedEmail != null && _cachedEmail!.contains('@') ? _cachedEmail!.split('@')[0] : null);

  static void setToken(String? token) {
    _cachedToken = token;
  }

  static void setUsername(String? username) {
    if (username != null && username.trim().isNotEmpty) {
      _cachedUsername = username.trim();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('saved_auth_username', _cachedUsername!);
      }).catchError((_) {});
    }
  }

  /// Load session from local storage into memory on app launch
  static Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
      _cachedEmail = prefs.getString('saved_auth_email');
      _cachedPassword = prefs.getString('saved_auth_pwd');
      _cachedUsername = prefs.getString('saved_auth_username');

      if (_cachedToken == null || _cachedToken!.isEmpty) {
        _cachedToken = await _secureStorage.read(key: 'auth_token');
      }

      debugPrint('[SESSION MANAGER] Loaded token: ${_cachedToken != null ? "present (${_cachedToken!.length} chars)" : "null"}');
    } catch (e) {
      debugPrint('[SESSION MANAGER] Error loading session: $e');
    }
  }

  /// Get currently active token (memory -> SharedPreferences -> FlutterSecureStorage)
  static Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }
    await loadSession();
    return _cachedToken;
  }

  /// Save session credentials to memory, SharedPreferences, and FlutterSecureStorage
  static Future<void> saveSession({
    required String token,
    String? email,
    String? password,
    String? username,
  }) async {
    _cachedToken = token;
    if (email != null && email.isNotEmpty) _cachedEmail = email;
    if (password != null && password.isNotEmpty) _cachedPassword = password;
    if (username != null && username.isNotEmpty) {
      _cachedUsername = username;
    } else if (email != null && email.contains('@')) {
      _cachedUsername = email.split('@')[0];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      if (email != null && email.isNotEmpty) {
        await prefs.setString('saved_auth_email', email);
      }
      if (password != null && password.isNotEmpty) {
        await prefs.setString('saved_auth_pwd', password);
      }
      if (_cachedUsername != null && _cachedUsername!.isNotEmpty) {
        await prefs.setString('saved_auth_username', _cachedUsername!);
      }
    } catch (e) {
      debugPrint('[SESSION MANAGER] SharedPreferences save error: $e');
    }

    try {
      await _secureStorage.write(key: 'auth_token', value: token);
    } catch (e) {
      debugPrint('[SESSION MANAGER] SecureStorage save error: $e');
    }
    debugPrint('[SESSION MANAGER] Successfully saved session token.');
  }

  /// Clear all stored credentials
  static Future<void> clearSession() async {
    _cachedToken = null;
    _cachedEmail = null;
    _cachedPassword = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('saved_auth_email');
      await prefs.remove('saved_auth_pwd');
    } catch (_) {}

    try {
      await _secureStorage.delete(key: 'auth_token');
    } catch (_) {}
    debugPrint('[SESSION MANAGER] Cleared session.');
  }

  /// Ensure we have a valid native backend JWT.
  /// If missing, attempts auto-login with backend using stored credentials or Firebase user.
  static Future<String?> ensureBackendToken({Dio? dio}) async {
    final currentToken = await getToken();
    if (currentToken != null && currentToken.isNotEmpty) {
      return currentToken;
    }

    return await refreshBackendToken(dio: dio);
  }

  /// Acquire a fresh backend JWT token from /auth/login
  static Future<String?> refreshBackendToken({Dio? dio}) async {
    if (_isRefreshing) {
      // Prevent concurrent redundant refresh calls
      await Future.delayed(const Duration(milliseconds: 600));
      return _cachedToken;
    }
    _isRefreshing = true;

    try {
      final fbUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final effectiveEmail = _cachedEmail ?? prefs.getString('saved_auth_email') ?? fbUser?.email;
      final effectivePassword = _cachedPassword ?? prefs.getString('saved_auth_pwd') ?? 'password123';

      if (effectiveEmail == null || effectiveEmail.isEmpty) {
        debugPrint('[SESSION MANAGER] Cannot refresh token: No email available');
        return null;
      }

      debugPrint('[SESSION MANAGER] Requesting fresh backend JWT for: $effectiveEmail');
      final client = dio ?? Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        contentType: 'application/json',
      ));

      final res = await client.post('/auth/login', data: {
        'email': effectiveEmail.trim().toLowerCase(),
        'password': effectivePassword.trim(),
      });

      final newToken = res.data['access_token']?.toString();
      if (newToken != null && newToken.isNotEmpty) {
        await saveSession(
          token: newToken,
          email: effectiveEmail,
          password: effectivePassword,
        );
        debugPrint('[SESSION MANAGER] Successfully acquired fresh JWT token.');
        return newToken;
      }
    } catch (e) {
      debugPrint('[SESSION MANAGER] Failed to acquire backend JWT: $e');
    } finally {
      _isRefreshing = false;
    }
    return null;
  }
}
