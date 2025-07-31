import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thesis_sys_app/constants/endpoints.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:8000/api'));
  final _storage = const FlutterSecureStorage();
  User? _currentUser;

@override
Future<User> login(String email, String password) async {
  try {
    final response = await _dio.post(Endpoints.login, data: {
      'email': email,
      'password': password,
    });

    final token = response.data['token'];
    final userJson = response.data['user'];

    if (token == null || userJson == null) {
      throw Exception('Login failed: invalid server response');
    }

    await _storage.write(key: 'token', value: token);

    final user = User.fromJson(userJson);
    _currentUser = user;

    if (kDebugMode) print('Login successful: ${user.name}');
    return user;
  } on DioException catch (e) {
    if (kDebugMode) print('Login error: ${e.response?.data}');
    throw Exception(
      e.response?.data is Map<String, dynamic> && e.response?.data['message'] != null
          ? e.response?.data['message']
          : 'Login failed',
    );
  }
}


  @override
  Future<User> register(String name, String email, String password, String role) async {
    try {
      final response = await _dio.post(Endpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      final token = response.data['token'];
      final userJson = response.data['user'];

      if (token == null || userJson == null) {
      throw Exception('Login failed: invalid server response');
    }

      await _storage.write(key: 'token', value: token);

      final user = User.fromJson(response.data['user']);
      _currentUser = user;

      if (kDebugMode) print('Registration successful: ${user.name}');
      return user;
    } on DioException catch (e) {
      if (kDebugMode) print('Registration error: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<void> logout(String email) async {
    try {
      final token = await _storage.read(key: 'token');
      if (kDebugMode) print('Logout: Using token: $token');
      if (kDebugMode) print('Logout: Sending email: $email');

      final response = await _dio.post(
        Endpoints.logout,
        data: {'email': email},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        print('Logout response status code: ${response.statusCode}');
        print('Logout response headers: ${response.headers}');
        print('Logout response data: ${response.data}');
      }

      await _storage.delete(key: 'token');
      _currentUser = null;

      if (kDebugMode) print('Logout successful');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Logout DioException error message: ${e.message}');
        print('Logout DioException request options: ${e.requestOptions}');
        print('Logout DioException response status code: ${e.response?.statusCode}');
        print('Logout DioException response headers: ${e.response?.headers}');
        print('Logout DioException response data: ${e.response?.data}');
      }

      throw Exception(
        e.response?.data is Map<String, dynamic> && e.response?.data['message'] != null
            ? e.response?.data['message']
            : 'Logout failed',
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('Logout unknown error: $e');
        print('Logout stack trace: $st');
      }
      throw Exception('Logout failed due to unknown error');
    }
  }

  @override
  Future<bool> checkSession() async {
    if (kDebugMode) print('[DEBUG] Checking session...');

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (kDebugMode) print('[DEBUG] No token found. User is not logged in.');
        return false;
      }

      final response = await _dio.post(
        Endpoints.checkSession,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        print('[DEBUG] Session check response status: ${response.statusCode}');
        print('[DEBUG] Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final logoutFlag = response.data['logout'];
        
        if (logoutFlag == true) {
          if (kDebugMode) print('[DEBUG] Server instructed to force logout.');
          return false;
        }

        if (response.data['user'] != null) {
          _currentUser = User.fromJson(response.data['user']);
          if (kDebugMode) print('[DEBUG] User is still logged in. force_logout == false');
        }

        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[DEBUG] Session check error: $e');
    }

    return false;
  }



  @override
  Future<User?> getUser() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return null;

      final response = await _dio.get(
        Endpoints.user,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final user = User.fromJson(response.data);
      _currentUser = user;

      if (kDebugMode) print('Fetched user: ${user.name}');
      return user;
    } on DioException catch (e) {
      if (kDebugMode) print('Get user error: ${e.response?.data}');
      return null;
    }
  }
}
