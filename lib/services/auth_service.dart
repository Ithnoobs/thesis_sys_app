// lib/services/auth_service.dart
import '../models/user_model.dart';

abstract class AuthService {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password, String role);
  Future<void> logout(String email);
  Future<bool> checkSession();
  Future<User?> getUser(); // for token-refresh/local
}
