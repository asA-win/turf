import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/constants/api_constants.dart';
import 'package:turf_app/core/services/session_manager.dart';

part 'api_client.g.dart';

@riverpod
Dio dioClient(Ref ref) {
  final options = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
  );

  final dio = Dio(options);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final isUserRegistration = (options.path.endsWith('/users') ||
                options.path.endsWith('/users/') ||
                options.path == '/users/' ||
                options.path == '/users') &&
            options.method.toUpperCase() == 'POST';

        final isAuthOrPublic = options.path.contains('/auth/') ||
            options.path.contains('check-availability') ||
            isUserRegistration;

        if (!isAuthOrPublic) {
          // 1. Check or automatically resolve native backend JWT
          final token = await SessionManager.ensureBackendToken(dio: dio);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          }

          // 2. Fallback to Firebase ID token if available
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final fbToken = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $fbToken';
            } catch (_) {}
          }
        }

        return handler.next(options);
      },
      onError: (e, handler) async {
        final url = e.requestOptions.uri.toString();
        final status = e.response?.statusCode;
        final isRetry = e.requestOptions.extra['is_token_retry'] == true;
        final isUserRegistration = (url.endsWith('/users') || url.endsWith('/users/')) &&
            e.requestOptions.method.toUpperCase() == 'POST';
        final isAuthOrPublic = url.contains('/auth/') ||
            url.contains('check-availability') ||
            isUserRegistration;

        // If 401 on non-auth endpoint and not already retried, refresh backend JWT
        if (status == 401 && !isAuthOrPublic && !isRetry) {
          debugPrint('401 detected at $url, refreshing native backend JWT token...');
          try {
            final newToken = await SessionManager.refreshBackendToken(dio: dio);
            if (newToken != null && newToken.isNotEmpty) {
              final options = e.requestOptions;
              options.extra['is_token_retry'] = true;
              options.headers['Authorization'] = 'Bearer $newToken';

              final response = await dio.fetch(options);
              return handler.resolve(response);
            }
          } catch (retryError) {
            debugPrint('Automatic JWT token refresh failed: $retryError');
          }
        }

        debugPrint('API Error [$status] at $url: ${e.message}');
        if (e.response?.data != null) {
          debugPrint('Error Data: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}

final apiClientProvider = dioClientProvider;

