import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:turf_app/core/constants/api_constants.dart';

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
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        final url = e.requestOptions.uri.toString();
        final status = e.response?.statusCode;
        
        // Handle 401 Unauthorized - Token might be expired
        if (status == 401) {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint('401 Error detected, refreshing token...');
            final token = await user.getIdToken(true);
            
            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (retryError) {
              return handler.next(e);
            }
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

