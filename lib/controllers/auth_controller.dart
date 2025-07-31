// lib/controllers/auth_controller.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_service_impl.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthServiceImpl());

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthController(service);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  Timer? _pollingTimer;

  AuthController(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void startPollingSession() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final isValid = await _authService.checkSession();
      if (!isValid) {
        state = const AsyncValue.data(null);
      }
    });
  }

  void stopPollingSession() {
    _pollingTimer?.cancel();
  }

  Future<void> _init() async {
    try {
      final sessionValid = await _authService.checkSession();
      if (!sessionValid) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _authService.getUser();
      state = AsyncValue.data(user);
      startPollingSession(); // ⬅️ Start polling
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }


    Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
      startPollingSession(); 
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  Future<void> register(String name, String email, String password, String role) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(name, email, password, role);
      if (user.allowAccess == false && user.role == 'supervisor') {
        state = AsyncValue.data(user); // show pending screen
      } else {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    stopPollingSession();
    final user = state.value;
    if (user == null) return;

    try {
      await _authService.logout(user.email);
    } catch (_) {
      // ignore failure on logout
    } finally {
      await const FlutterSecureStorage().delete(key: 'token');
      state = const AsyncValue.data(null);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }

  Future<User?> refreshAndReturnUser() async {
  try {
      final sessionValid = await _authService.checkSession();
      if (!sessionValid) {
        state = const AsyncValue.data(null);
        return null;
      }

      final user = await _authService.getUser();
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

}
