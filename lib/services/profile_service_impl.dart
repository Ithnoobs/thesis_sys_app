import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:thesis_sys_app/constants/endpoints.dart';
import 'package:thesis_sys_app/models/user_model.dart';
import 'package:thesis_sys_app/services/dio_client.dart';
import 'package:thesis_sys_app/services/profile_service.dart';

class ProfileServiceImpl implements ProfileService {
  final Dio _dio = DioClient().dio;
  final _storage = const FlutterSecureStorage();
  User? _currentUser;

  @override
  Future<void> uploadProfileImage(String filePath, String email) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
      'email': email,
    });

    try {
      final response = await _dio.post(
        Endpoints.profileUpload,
        data: formData,
      );

      if (response.statusCode == 200) {
        // Handle successful upload
        print("Profile image uploaded successfully");
      } else {
        throw Exception("Failed to upload profile image");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("DioException uploading profile image:");
        print("Error type: ${e.type}");
        print("Response status: ${e.response?.statusCode}");
        print("Response data: ${e.response?.data}");
      }
      
      final errorMessage = _extractErrorMessage(e, 'Failed to upload profile image');
      throw Exception(errorMessage);
    } catch (e) {
      print("Error uploading profile image: $e");
      throw e; // Re-throw the error for further handling
    }
    
  }

  @override
  Future<void> updateProfileInfo(String name, String email) async {
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr == null) {
        throw Exception("User not authenticated");
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        throw Exception("Invalid user ID");
      }

      final response = await _dio.post(
        Endpoints.updateProfile,
        data: {
          'name': name,
          'email': email,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        print("Profile info updated successfully");
      } else {
        throw Exception("Failed to update profile info");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("DioException updating profile info:");
        print("Error type: ${e.type}");
        print("Response status: ${e.response?.statusCode}");
        print("Response data: ${e.response?.data}");
      }
      
      final errorMessage = _extractErrorMessage(e, 'Failed to update profile info');
      throw Exception(errorMessage);
    } catch (e) {
      print("Error updating profile info: $e");
      throw e;
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr == null) {
        throw Exception("User not authenticated");
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        throw Exception("Invalid user ID");
      }

      if (kDebugMode) {
        print('[PROFILE_SERVICE] Changing password for user ID: $userId');
        print('[PROFILE_SERVICE] Endpoint: ${Endpoints.changePassword}');
        print('[PROFILE_SERVICE] Request data: {current_password: [hidden], new_password: [hidden], user_id: $userId}');
      }

      final requestData = {
        'current_password': oldPassword,
        'new_password': newPassword,
        'user_id': userId,
      };

      final response = await _dio.post(
        Endpoints.changePassword,
        data: requestData,
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('[PROFILE_SERVICE] Password changed successfully');
        print("Password changed successfully");
        // Force logout after password change as per backend logic
        await _storage.deleteAll();
      } else {
        throw Exception("Failed to change password: Status ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("[PROFILE_SERVICE] DioException changing password:");
        print("[PROFILE_SERVICE] Error type: ${e.type}");
        print("[PROFILE_SERVICE] Error message: ${e.message}");
        print("[PROFILE_SERVICE] Response status: ${e.response?.statusCode}");
        print("[PROFILE_SERVICE] Response data: ${e.response?.data}");
        print("[PROFILE_SERVICE] Request options: ${e.requestOptions.path}");
      }
      
      // Handle specific error cases
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] ?? 'Invalid request data';
        throw Exception(message);
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Current password is incorrect');
      } else {
        final errorMessage = _extractErrorMessage(e, 'Failed to change password');
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) print("[PROFILE_SERVICE] Error changing password: $e");
      throw e;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      if (kDebugMode) print('[PROFILE_SERVICE] Fetching user from ${Endpoints.user}');
      final response = await _dio.get(Endpoints.user);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[PROFILE_SERVICE] User data received: ${response.data}');
          print('[PROFILE_SERVICE] Profile picture field: ${response.data['profile_picture']}');
        }
        _currentUser = User.fromJson(response.data);
        if (kDebugMode) print('[PROFILE_SERVICE] User object created with profile picture: ${_currentUser?.profilePicture}');
        return _currentUser;
      } else {
        if (kDebugMode) print('[PROFILE_SERVICE] Failed to fetch user profile, status: ${response.statusCode}');
        throw Exception("Failed to fetch user profile");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[PROFILE_SERVICE] DioException fetching user profile:');
        print('[PROFILE_SERVICE] Error type: ${e.type}');
        print('[PROFILE_SERVICE] Response status: ${e.response?.statusCode}');
        print('[PROFILE_SERVICE] Response data: ${e.response?.data}');
      }
      
      final errorMessage = _extractErrorMessage(e, 'Failed to fetch user profile');
      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) print('[PROFILE_SERVICE] Error fetching user profile: $e');
      throw e;
    }
  }

  // Helper method to extract error messages consistently
  String _extractErrorMessage(DioException e, String defaultMessage) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['message'] ?? defaultMessage;
    }
    return defaultMessage;
  }
}
