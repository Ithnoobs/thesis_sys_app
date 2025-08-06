import 'package:thesis_sys_app/models/user_model.dart';

abstract class ProfileService {
  Future<void> uploadProfileImage(String filePath, String email);
  Future<void> updateProfileInfo(String name, String email);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<User?> getCurrentUser();
}
