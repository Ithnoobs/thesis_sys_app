// lib/services/auth_service.dart
import '../models/user_model.dart';
import 'auth_service_impl.dart';

abstract class AuthService {
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password, String role);
  Future<Map<String, dynamic>> logout(String email);
  Future<SessionCheckResult> checkSession();
  Future<User?> getUser();
}
