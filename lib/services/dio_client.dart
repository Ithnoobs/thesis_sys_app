import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/interceptors/global_error_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio.options.baseUrl = 'http://10.0.2.2:8000/api';
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  // Call this from a screen (login/register/session check)
  void attachContext(BuildContext context) {
    dio.interceptors.clear(); // reset all to avoid duplicates
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    dio.interceptors.add(GlobalErrorInterceptor(context));
  }
}
