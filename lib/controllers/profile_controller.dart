import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thesis_sys_app/models/user_model.dart';
import 'package:thesis_sys_app/services/profile_service.dart';
import 'package:thesis_sys_app/services/profile_service_impl.dart';

final profileServiceProvider = Provider<ProfileService>((ref) => ProfileServiceImpl());

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<User?>>((ref) {
  final service = ref.watch(profileServiceProvider);
  return ProfileController(service);
});

class ProfileController extends StateNotifier<AsyncValue<User?>> {
  final ProfileService _profileService;

  ProfileController(this._profileService) : super(const AsyncValue.loading());

  Future<void> loadUserProfile() async {
    if (kDebugMode) print('[PROFILE_CONTROLLER] Loading user profile...');
    state = const AsyncValue.loading();
    
    try {
      final user = await _profileService.getCurrentUser();
      state = AsyncValue.data(user);
      if (kDebugMode) print('[PROFILE_CONTROLLER] User profile loaded successfully');
    } catch (e, stackTrace) {
      if (kDebugMode) print('[PROFILE_CONTROLLER] Error loading profile: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> uploadProfileImage(String filePath, String email) async {
    if (kDebugMode) print('[PROFILE_CONTROLLER] Uploading profile image...');
    
    try {
      await _profileService.uploadProfileImage(filePath, email);
      // Refresh user profile after upload
      await loadUserProfile();
      if (kDebugMode) print('[PROFILE_CONTROLLER] Profile image uploaded and profile refreshed');
    } catch (e) {
      if (kDebugMode) print('[PROFILE_CONTROLLER] Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<void> updateProfileInfo(String name, String email) async {
    if (kDebugMode) print('[PROFILE_CONTROLLER] Updating profile info...');
    
    try {
      await _profileService.updateProfileInfo(name, email);
      // Refresh user profile after update
      await loadUserProfile();
      if (kDebugMode) print('[PROFILE_CONTROLLER] Profile info updated and profile refreshed');
    } catch (e) {
      if (kDebugMode) print('[PROFILE_CONTROLLER] Error updating profile info: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (kDebugMode) print('[PROFILE_CONTROLLER] Changing password...');
    
    try {
      await _profileService.changePassword(oldPassword, newPassword);
      if (kDebugMode) print('[PROFILE_CONTROLLER] Password changed successfully');
    } catch (e) {
      if (kDebugMode) print('[PROFILE_CONTROLLER] Error changing password: $e');
      rethrow;
    }
  }

  User? get currentUser => state.value;
}
