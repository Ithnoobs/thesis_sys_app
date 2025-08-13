import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/interceptors/global_error_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient._internal() {
    if (kDebugMode) print('[DIO_CLIENT] Initializing DioClient...');
    dio.options.baseUrl = 'http://10.0.2.2:8000/api';
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.followRedirects = false; // Important: Don't follow redirects
    dio.options.validateStatus = (status) => status! < 400; // Treat redirects as errors
  }

  void attachContext(BuildContext context) {
    if (kDebugMode) print('[DIO_CLIENT] Attaching context and setting up interceptors...');
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (kDebugMode) print('[DIO_CLIENT] Request: ${options.method} ${options.path}');
          
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) print('[DIO_CLIENT] Added auth header with token');
          } else {
            if (kDebugMode) print('[DIO_CLIENT] No token available for request');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (kDebugMode) {
            print('[DIO_CLIENT] Error intercepted:');
            print('[DIO_CLIENT] Status: ${e.response?.statusCode}');
            print('[DIO_CLIENT] Type: ${e.type}');
            print('[DIO_CLIENT] Path: ${e.requestOptions.path}');
          }

          // Only clear tokens for 401 errors on critical endpoints (not /user or /check-session)
          if (e.response?.statusCode == 401) {
            final path = e.requestOptions.path;
            
            // Don't clear tokens for session check endpoints - let AuthService handle it
            if (path == '/user' || path == '/check-session') {
              if (kDebugMode) print('[DIO_CLIENT] 401 on session endpoint - letting AuthService handle');
            } else {
              // Clear tokens only for other endpoints with 401
              if (kDebugMode) print('[DIO_CLIENT] 401 on non-session endpoint - clearing tokens');
              await _clearTokens();
            }
          }

          // Handle 302 redirects as authentication failures (but not for session endpoints)
          if (e.response?.statusCode == 302) {
            final path = e.requestOptions.path;
            if (path != '/user' && path != '/check-session') {
              if (kDebugMode) print('[DIO_CLIENT] 302 redirect detected - clearing tokens');
              await _clearTokens();
            }
          }

          return handler.next(e);
        },
      ),
    );

    dio.interceptors.add(GlobalErrorInterceptor(context));
    if (kDebugMode) print('[DIO_CLIENT] Interceptors setup complete');
  }

  Future<void> _clearTokens() async {
    if (kDebugMode) print('[DIO_CLIENT] Clearing tokens...');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_id');
  }
}

