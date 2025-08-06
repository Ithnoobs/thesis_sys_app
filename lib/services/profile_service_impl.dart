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
    } catch (e) {
      print("Error uploading profile image: $e");
      throw e; // Re-throw the error for further handling
    }
    
  }

  @override
  Future<void> updateProfileInfo(String name, String email) async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        throw Exception("User not authenticated");
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
    } catch (e) {
      print("Error updating profile info: $e");
      throw e;
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final response = await _dio.post(
        Endpoints.changePassword,
        data: {
          'current_password': oldPassword,
          'new_password': newPassword,
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        print("Password changed successfully");
        // Force logout after password change as per backend logic
        await _storage.deleteAll();
      } else {
        throw Exception("Failed to change password");
      }
    } catch (e) {
      print("Error changing password: $e");
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
    } catch (e) {
      if (kDebugMode) print('[PROFILE_SERVICE] Error fetching user profile: $e');
      throw e;
    }
  }
}
