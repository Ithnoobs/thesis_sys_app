import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thesis_sys_app/constants/endpoints.dart';
import 'package:thesis_sys_app/services/dio_client.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  final Dio _dio = DioClient().dio;
  final _storage = const FlutterSecureStorage();
  User? _currentUser;

  @override
  Future<User> login(String email, String password) async {
    if (kDebugMode) print('[LOGIN] Starting login for email: $email');
    
    try {
      if (kDebugMode) print('[LOGIN] Sending POST request to ${Endpoints.login}');
      
      final response = await _dio.post(Endpoints.login, data: {
        'email': email,
        'password': password,
      });

      if (kDebugMode) {
        print('[LOGIN] Response status: ${response.statusCode}');
        print('[LOGIN] Response data: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        if (kDebugMode) print('[LOGIN] ERROR: Server returned non-JSON: ${response.data}');
        throw Exception('Server returned non-JSON: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      
      // Handle different status codes based on backend logic
      if (response.statusCode == 400) {
        // User exists but access not allowed
        final message = responseData['message'] ?? 'Access not allowed';
        if (kDebugMode) print('[LOGIN] Access denied: $message');
        throw Exception(message);
      }

      if (response.statusCode == 404) {
        // User not found or invalid credentials
        final message = responseData['message'] ?? 'User not found';
        if (kDebugMode) print('[LOGIN] User not found: $message');
        throw Exception(message);
      }

      if (response.statusCode == 200) {
        final token = responseData['token'];
        final userJson = responseData['user'];
        final message = responseData['message'];

        if (kDebugMode) {
          print('[LOGIN] Success message: $message');
          print('[LOGIN] Token present: ${token != null}');
          print('[LOGIN] User data present: ${userJson != null}');
        }

        if (token == null || userJson == null) {
          if (kDebugMode) print('[LOGIN] ERROR: Missing required fields in server response');
          throw Exception('Login failed: invalid server response');
        }

        if (kDebugMode) print('[LOGIN] Writing token to secure storage...');
        await _storage.write(key: 'token', value: token);
        if (kDebugMode) print('[LOGIN] Token stored successfully');

        final user = User.fromJson(userJson);
        _currentUser = user;
        
        // Store user_id for profile operations
        if (user.id != null) {
          await _storage.write(key: 'user_id', value: user.id.toString());
          if (kDebugMode) print('[LOGIN] User ID stored: ${user.id}');
        }

        if (kDebugMode) {
          print('[LOGIN] User object created: ${user.name} (${user.email})');
          print('[LOGIN] User role: ${user.role}');
          print('[LOGIN] User allowAccess: ${user.allowAccess}');
          print('[LOGIN] Login successful for: ${user.name}');
        }
        return user;
      }

      throw Exception('Unexpected response status: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[LOGIN] DioException occurred:');
        print('[LOGIN] Error type: ${e.type}');
        print('[LOGIN] Error message: ${e.message}');
        print('[LOGIN] Response status: ${e.response?.statusCode}');
        print('[LOGIN] Response data: ${e.response?.data}');
      }
      
      final errorMessage = _extractErrorMessage(e, 'Login failed');
      if (kDebugMode) print('[LOGIN] Throwing exception: $errorMessage');
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LOGIN] Unexpected error: $e');
        print('[LOGIN] Stack trace: $stackTrace');
      }
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<User> register(String name, String email, String password, String role) async {
    if (kDebugMode) {
      print('[REGISTER] Starting registration for:');
      print('[REGISTER] Name: $name');
      print('[REGISTER] Email: $email');
      print('[REGISTER] Role: $role');
    }

    try {
      if (kDebugMode) print('[REGISTER] Sending POST request to ${Endpoints.register}');
      
      final response = await _dio.post(Endpoints.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      if (kDebugMode) {
        print('[REGISTER] Response status: ${response.statusCode}');
        print('[REGISTER] Response data: ${response.data}');
      }

      if (response.data is! Map<String, dynamic>) {
        if (kDebugMode) print('[REGISTER] ERROR: Server returned non-JSON: ${response.data}');
        throw Exception('Server returned non-JSON: ${response.data}');
      }
      
      final responseData = response.data as Map<String, dynamic>;
      final token = responseData['token'];
      final userJson = responseData['user'];
      final message = responseData['message'];

      if (kDebugMode) {
        print('[REGISTER] Success message: $message');
        print('[REGISTER] Token: ${token?.isNotEmpty == true ? "present" : "empty/null"}');
        print('[REGISTER] User data: ${userJson != null ? "present" : "null"}');
      }

      final user = User.fromJson(userJson);
      _currentUser = user;

      // Handle pending activation case (token is empty string)
      if (token == null || token == '') {
        if (kDebugMode) {
          print('[REGISTER] User awaiting activation - no token provided');
          print('[REGISTER] Registration pending for: ${user.name}');
          print('[REGISTER] User allowAccess: ${user.allowAccess}');
        }
        return user;
      }

      // User is auto-approved, store token
      if (token.isNotEmpty) {
        if (kDebugMode) print('[REGISTER] Writing token to secure storage...');
        await _storage.write(key: 'token', value: token);
        
        // Store user_id for profile operations
        if (user.id != null) {
          await _storage.write(key: 'user_id', value: user.id.toString());
          if (kDebugMode) print('[REGISTER] User ID stored: ${user.id}');
        }

        if (kDebugMode) print('[REGISTER] Token stored successfully');        if (kDebugMode) {
          print('[REGISTER] User object created: ${user.name} (${user.email})');
          print('[REGISTER] User role: ${user.role}');
          print('[REGISTER] User allowAccess: ${user.allowAccess}');
          print('[REGISTER] Registration successful for: ${user.name}');
        }
      }

      return user;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[REGISTER] DioException occurred:');
        print('[REGISTER] Error type: ${e.type}');
        print('[REGISTER] Error message: ${e.message}');
        print('[REGISTER] Response status: ${e.response?.statusCode}');
        print('[REGISTER] Response data: ${e.response?.data}');
      }
      
      final errorMessage = _extractErrorMessage(e, 'Registration failed');
      if (kDebugMode) print('[REGISTER] Throwing exception: $errorMessage');
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[REGISTER] Unexpected error: $e');
        print('[REGISTER] Stack trace: $stackTrace');
      }
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> logout(String email) async {
    if (kDebugMode) print('[LOGOUT] Starting logout for email: $email');
    
    final token = await _storage.read(key: 'token');

    if (kDebugMode) {
      print('[LOGOUT] Token available: ${token != null}');
    }

    try {
      if (kDebugMode) print('[LOGOUT] Sending logout request to server...');
      
      final response = await _dio.post(
        Endpoints.logout,
        data: {
          'email': email,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (kDebugMode) {
        print('[LOGOUT] Server logout request successful');
        print('[LOGOUT] Response: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final message = responseData['message'] ?? 'You are logged out.';

      return {
        'success': true,
        'message': message,
        'showPopup': true,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[LOGOUT] DioException during server logout:');
        print('[LOGOUT] Error type: ${e.type}');
        print('[LOGOUT] Error message: ${e.message}');
        print('[LOGOUT] Response status: ${e.response?.statusCode}');
        print('[LOGOUT] Response data: ${e.response?.data}');
      }

      final errorMessage = _extractErrorMessage(e, 'Logout failed');
      if (kDebugMode) print('[LOGOUT] Server logout failed: $errorMessage');
      
      return {
        'success': false,
        'message': errorMessage,
        'showPopup': true,
      };
    } catch (e) {
      if (kDebugMode) print('[LOGOUT] Unexpected error during logout: $e');
      return {
        'success': false,
        'message': 'Logout failed: $e',
        'showPopup': true,
      };
    } finally {
      if (kDebugMode) print('[LOGOUT] Clearing local storage and user data...');
      
      await _clearTokens();

      if (kDebugMode) print('[LOGOUT] Local cleanup completed - tokens and user_id cleared, user set to null');
    }
  }

  @override
  Future<SessionCheckResult> checkSession() async {
    if (kDebugMode) print('[SESSION] Starting session check...');

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (kDebugMode) print('[SESSION] No token found in storage - user not logged in');
        return SessionCheckResult(
          isValid: false,
          shouldLogout: false,
          message: 'No token found',
        );
      }

      if (kDebugMode) {
        print('[SESSION] Token found, preview: ${token.substring(0, 20)}...');
        print('[SESSION] Using /user endpoint for session validation...');
      }

      // Use the /user endpoint instead of /check-session to avoid backend bugs
      final response = await _dio.get(
        Endpoints.user,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        print('[SESSION] User endpoint response status: ${response.statusCode}');
        print('[SESSION] User endpoint response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        _currentUser = user;

        // Check force_logout flag to determine if we should logout
        if (user.forceLogout == true) {
          if (kDebugMode) print('[SESSION] User has force_logout=true - session invalid');
          return SessionCheckResult(
            isValid: false,
            shouldLogout: true,
            message: 'Force logout - you have been logged out from another device',
            isForceLogout: true,
          );
        }

        // Check if user has API tokens (hasApiTokens from backend)
        if (user.hasApiTokens == false) {
          if (kDebugMode) print('[SESSION] User has no API tokens - session invalid');
          return SessionCheckResult(
            isValid: false,
            shouldLogout: true,
            message: 'No valid API tokens found',
          );
        }

        if (kDebugMode) print('[SESSION] Session is valid via user endpoint');
        return SessionCheckResult(
          isValid: true,
          shouldLogout: false,
          message: 'Session valid',
        );
      } else {
        if (kDebugMode) print('[SESSION] User endpoint failed with status: ${response.statusCode}');
        return SessionCheckResult(
          isValid: false,
          shouldLogout: false,
          message: 'Session check failed',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[SESSION] DioException during session check:');
        print('[SESSION] Error type: ${e.type}');
        print('[SESSION] Response status: ${e.response?.statusCode}');
        print('[SESSION] Response data: ${e.response?.data}');
      }

      if (e.response?.statusCode == 401) {
        // Token is invalid or expired
        return SessionCheckResult(
          isValid: false,
          shouldLogout: true,
          message: 'Session expired or invalid',
        );
      }

      // For other errors (network, 404, etc), don't clear tokens - just mark session as temporarily invalid
      if (kDebugMode) print('[SESSION] Network/other error - keeping tokens but marking session invalid');
      return SessionCheckResult(
        isValid: false,
        shouldLogout: false,
        message: 'Network error during session check - keeping session',
      );
    } catch (e) {
      if (kDebugMode) print('[SESSION] Unexpected error during session check: $e');
      return SessionCheckResult(
        isValid: false,
        shouldLogout: false,
        message: 'Unexpected error during session check',
      );
    }
  }

  @override
  Future<User?> getUser() async {
    if (kDebugMode) print('[GET_USER] Fetching user data...');
    
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (kDebugMode) print('[GET_USER] No token available');
        return null;
      }

      if (kDebugMode) {
        print('[GET_USER] Token available, sending request...');
        print('[GET_USER] Request URL: ${Endpoints.user}');
      }

      final response = await _dio.get(
        Endpoints.user,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        print('[GET_USER] Response status: ${response.statusCode}');
        print('[GET_USER] Response data type: ${response.data.runtimeType}');
      }

      final user = User.fromJson(response.data);
      _currentUser = user;

      if (kDebugMode) {
        print('[GET_USER] User fetched successfully: ${user.name} (${user.email})');
        print('[GET_USER] User role: ${user.role}');
        print('[GET_USER] User allowAccess: ${user.allowAccess}');
      }
      return user;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[GET_USER] DioException occurred:');
        print('[GET_USER] Error type: ${e.type}');
        print('[GET_USER] Response status: ${e.response?.statusCode}');
        print('[GET_USER] Response data: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('[GET_USER] Unexpected error: $e');
      return null;
    }
  }

  // Helper method to clear tokens
  Future<void> _clearTokens() async {
    if (kDebugMode) print('[CLEAR_TOKENS] Clearing stored tokens...');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_id');
    _currentUser = null;
    if (kDebugMode) print('[CLEAR_TOKENS] Token and user_id cleared');
  }

  // Helper method to extract error messages consistently
  String _extractErrorMessage(DioException e, String defaultMessage) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['message'] ?? defaultMessage;
    }
    return defaultMessage;
  }

  // Getter for current user (useful for debugging)
  User? get currentUser {
    if (kDebugMode && _currentUser != null) {
      print('[CURRENT_USER] ${_currentUser!.name} (${_currentUser!.email})');
    }
    return _currentUser;
  }
}

// Helper class for session check results
class SessionCheckResult {
  final bool isValid;
  final bool shouldLogout;
  final String message;
  final bool isForceLogout;

  SessionCheckResult({
    required this.isValid,
    required this.shouldLogout,
    required this.message,
    this.isForceLogout = false,
  });
}
