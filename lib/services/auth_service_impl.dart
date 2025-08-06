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
        final refreshToken = responseData['refresh_token'];
        final userJson = responseData['user'];
        final message = responseData['message'];

        if (kDebugMode) {
          print('[LOGIN] Success message: $message');
          print('[LOGIN] Token present: ${token != null}');
          print('[LOGIN] Refresh token present: ${refreshToken != null}');
          print('[LOGIN] User data present: ${userJson != null}');
        }

        if (token == null || refreshToken == null || userJson == null) {
          if (kDebugMode) print('[LOGIN] ERROR: Missing required fields in server response');
          throw Exception('Login failed: invalid server response');
        }

        if (kDebugMode) print('[LOGIN] Writing tokens to secure storage...');
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        if (kDebugMode) print('[LOGIN] Tokens stored successfully');

        final user = User.fromJson(userJson);
        _currentUser = user;

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
      final refreshToken = responseData['refresh_token'];
      final userJson = responseData['user'];
      final message = responseData['message'];

      if (kDebugMode) {
        print('[REGISTER] Success message: $message');
        print('[REGISTER] Token: ${token?.isNotEmpty == true ? "present" : "empty/null"}');
        print('[REGISTER] Refresh token: ${refreshToken?.isNotEmpty == true ? "present" : "empty/null"}');
        print('[REGISTER] User data: ${userJson != null ? "present" : "null"}');
      }

      final user = User.fromJson(userJson);
      _currentUser = user;

      // Handle pending activation case (token and refresh_token are empty strings)
      if ((token == null || token == '') && (refreshToken == null || refreshToken == '')) {
        if (kDebugMode) {
          print('[REGISTER] User awaiting activation - no tokens provided');
          print('[REGISTER] Registration pending for: ${user.name}');
          print('[REGISTER] User allowAccess: ${user.allowAccess}');
        }
        return user;
      }

      // User is auto-approved, store tokens
      if (token != null && token.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
        if (kDebugMode) print('[REGISTER] Writing tokens to secure storage...');
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        if (kDebugMode) print('[REGISTER] Tokens stored successfully');

        if (kDebugMode) {
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
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (kDebugMode) {
      print('[LOGOUT] Token available: ${token != null}');
      print('[LOGOUT] Refresh token available: ${refreshToken != null}');
    }

    try {
      if (kDebugMode) print('[LOGOUT] Sending logout request to server...');
      
      final response = await _dio.post(
        Endpoints.logout,
        data: {
          'email': email,
          'refresh_token': refreshToken,
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
      
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refresh_token');
      _currentUser = null;

      if (kDebugMode) print('[LOGOUT] Local cleanup completed - tokens cleared and user set to null');
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
        print('[SESSION] Sending session check request...');
      }

      final response = await _dio.post(
        Endpoints.checkSession,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (kDebugMode) {
        print('[SESSION] Session check response status: ${response.statusCode}');
        print('[SESSION] Session check response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final shouldLogout = responseData['logout'] ?? false;
        final message = responseData['message'] ?? 'Session valid';
        
        if (shouldLogout) {
          if (kDebugMode) print('[SESSION] Server instructed logout - session invalid');
          return SessionCheckResult(
            isValid: false,
            shouldLogout: true,
            message: message,
            isForceLogout: message.toLowerCase().contains('force logout'),
          );
        }

        if (responseData['user'] != null) {
          _currentUser = User.fromJson(responseData['user']);
          if (kDebugMode) print('[SESSION] User data updated from session check: ${_currentUser!.name}');
        }

        if (kDebugMode) print('[SESSION] Session is valid');
        return SessionCheckResult(
          isValid: true,
          shouldLogout: false,
          message: message,
        );
      } else {
        if (kDebugMode) print('[SESSION] Session check failed with status: ${response.statusCode}');
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
        final responseData = e.response?.data as Map<String, dynamic>?;
        final message = responseData?['message'] ?? 'Session expired';
        final shouldLogout = responseData?['logout'] ?? true;
        
        return SessionCheckResult(
          isValid: false,
          shouldLogout: shouldLogout,
          message: message,
          isForceLogout: message.toLowerCase().contains('force logout'),
        );
      }

      return SessionCheckResult(
        isValid: false,
        shouldLogout: false,
        message: 'Network error during session check',
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

  Future<bool> refreshAccessToken() async {
    if (kDebugMode) print('[REFRESH] Starting token refresh...');
    
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      if (kDebugMode) print('[REFRESH] No refresh token available');
      return false;
    }

    if (kDebugMode) {
      print('[REFRESH] Refresh token available, preview: ${refreshToken.substring(0, 20)}...');
      print('[REFRESH] Sending refresh request to ${Endpoints.refreshToken}');
    }

    try {
      final response = await _dio.post(
        Endpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (kDebugMode) {
        print('[REFRESH] Refresh response status: ${response.statusCode}');
        print('[REFRESH] Refresh response data: ${response.data}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final newToken = responseData['token'];
      final newRefreshToken = responseData['refresh_token'];

      if (newToken == null || newRefreshToken == null) {
        if (kDebugMode) print('[REFRESH] ERROR: Missing tokens in refresh response');
        await _clearTokens();
        return false;
      }

      if (kDebugMode) {
        print('[REFRESH] New tokens received');
        print('[REFRESH] New token preview: ${newToken.substring(0, 20)}...');
        print('[REFRESH] Writing new tokens to storage...');
      }

      await _storage.write(key: 'token', value: newToken);
      await _storage.write(key: 'refresh_token', value: newRefreshToken);

      if (kDebugMode) print('[REFRESH] Token refresh successful');
      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[REFRESH] DioException during token refresh:');
        print('[REFRESH] Error type: ${e.type}');
        print('[REFRESH] Response status: ${e.response?.statusCode}');
        print('[REFRESH] Response data: ${e.response?.data}');
      }
      await _clearTokens();
      return false;
    } catch (e) {
      if (kDebugMode) print('[REFRESH] Unexpected error during token refresh: $e');
      await _clearTokens();
      return false;
    }
  }

  // Helper method to clear tokens
  Future<void> _clearTokens() async {
    if (kDebugMode) print('[CLEAR_TOKENS] Clearing stored tokens...');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh_token');
    _currentUser = null;
    if (kDebugMode) print('[CLEAR_TOKENS] Tokens cleared');
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
