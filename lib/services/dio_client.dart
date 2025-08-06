import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thesis_sys_app/services/auth_service_impl.dart';
import '../core/interceptors/global_error_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

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

          // Handle 302 redirects as authentication failures
          if (e.response?.statusCode == 302 || e.response?.statusCode == 401) {
            if (kDebugMode) print('[DIO_CLIENT] Authentication error detected');

            if (!_isRefreshing) {
              _isRefreshing = true;
              
              try {
                if (kDebugMode) print('[DIO_CLIENT] Attempting token refresh...');
                final refreshed = await AuthServiceImpl().refreshAccessToken();

                if (refreshed) {
                  if (kDebugMode) print('[DIO_CLIENT] Token refresh successful, retrying request...');
                  final newToken = await _storage.read(key: 'token');
                  final options = e.requestOptions;

                  options.headers['Authorization'] = 'Bearer $newToken';

                  try {
                    final response = await dio.fetch(options);
                    _isRefreshing = false;
                    return handler.resolve(response);
                  } catch (retryError) {
                    if (kDebugMode) print('[DIO_CLIENT] Retry failed: $retryError');
                    _isRefreshing = false;
                    return handler.reject(retryError as DioException);
                  }
                } else {
                  if (kDebugMode) print('[DIO_CLIENT] Token refresh failed - clearing tokens');
                  await _clearTokens();
                  _isRefreshing = false;
                }
              } catch (refreshError) {
                if (kDebugMode) print('[DIO_CLIENT] Refresh error: $refreshError');
                _isRefreshing = false;
              }
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
    await _storage.delete(key: 'refresh_token');
  }
}

