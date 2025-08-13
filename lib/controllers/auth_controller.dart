// lib/controllers/auth_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_service_impl.dart';
import '../Widget/force_logout_banner.dart';
import '../router/navigation_service.dart' show navigatorKey;
import '../main.dart' show scaffoldMessengerKey;

final authServiceProvider = Provider<AuthService>((ref) => AuthServiceImpl());

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthController(service);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  Timer? _pollingTimer;
  bool _isPolling = false;

  AuthController(this._authService) : super(const AsyncValue.loading()) {
    if (kDebugMode) print('[AUTH_CONTROLLER] Initializing AuthController...');
    _init();
  }

  @override
  void dispose() {
    if (kDebugMode) print('[AUTH_CONTROLLER] Disposing AuthController...');
    stopPollingSession();
    super.dispose();
  }

  void startPollingSession() {
    if (_isPolling) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Session polling already active');
      return;
    }

    if (kDebugMode) print('[AUTH_CONTROLLER] Starting session polling every 30 seconds...');
    _isPolling = true;
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_isPolling) return;
      
      if (kDebugMode) print('[AUTH_CONTROLLER] Polling session check...');
      
      try {
        final sessionResult = await _authService.checkSession();
        
        if (!sessionResult.isValid && _isPolling) {
          if (kDebugMode) print('[AUTH_CONTROLLER] Session invalid - handling logout');
          await _handleSessionExpired(sessionResult);
        } else if (kDebugMode) {
          print('[AUTH_CONTROLLER] Session poll result: valid=${sessionResult.isValid}');
        }
      } catch (e) {
        if (kDebugMode) print('[AUTH_CONTROLLER] Session poll error: $e');
      }
    });
  }

  void stopPollingSession() {
    if (kDebugMode) print('[AUTH_CONTROLLER] Stopping session polling...');
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _handleSessionExpired(SessionCheckResult result) async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Handling session expiration...');
    stopPollingSession();
    
    // Only clear tokens if backend explicitly says to logout
    if (result.shouldLogout) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Backend says logout - clearing tokens');
      await _clearTokens();
    } else {
      if (kDebugMode) print('[AUTH_CONTROLLER] Keeping tokens - session temporarily invalid');
    }
    
    state = const AsyncValue.data(null);

    // Show popup for force logout - but delay to ensure UI is ready
    if (result.isForceLogout) {
      await Future.delayed(const Duration(milliseconds: 100));
      _showForceLogoutNotification(result.message);
    }
  }

  void _showForceLogoutNotification(String message) {
    if (kDebugMode) print('[AUTH_CONTROLLER] Showing force logout notification');
    
    // Show snackbar first
    _showSnackBar(
      message.contains('another device') 
        ? "🚫 You have been logged out from another device."
        : "🚫 Your session has ended. Please login again.",
      Colors.red,
      duration: 5,
    );

    // Show banner overlay if context is available
    final context = navigatorKey.currentContext;
    if (context != null) {
      _showForceLogoutBanner(context, message);
    }
  }

  void _showForceLogoutBanner(BuildContext context, String message) {
    if (kDebugMode) print('[AUTH_CONTROLLER] Showing force logout banner');
    
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => overlayEntry.remove(),
            child: ForceLogoutBanner(message: message),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        if (kDebugMode) print('[AUTH_CONTROLLER] Removing force logout banner');
        overlayEntry.remove();
      }
    });
  }

  void _showSnackBar(String message, Color color, {int duration = 3}) {
    if (kDebugMode) print('[AUTH_CONTROLLER] Showing snackbar: $message');

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      // Clear any existing snackbars first
      messenger.clearSnackBars();
      
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.red ? Icons.logout : 
                color == Colors.green ? Icons.check_circle : Icons.info,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: duration),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      if (kDebugMode) print('[AUTH_CONTROLLER] ScaffoldMessenger not available');
    }
  }

  void _showLogoutDialog(String message, bool isSuccess) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // Fallback to snackbar if no context
      _showSnackBar(
        isSuccess ? "✅ $message" : "❌ $message",
        isSuccess ? Colors.green : Colors.red,
      );
      return;
    }

    if (kDebugMode) print('[AUTH_CONTROLLER] Showing logout dialog: $message');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isSuccess ? "Logout Successful" : "Logout Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              if (isSuccess) {
                // Navigate to login page
                context.go('/login');
              }
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _clearTokens() async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Clearing stored tokens...');
    try {
      await const FlutterSecureStorage().delete(key: 'token');
      await const FlutterSecureStorage().delete(key: 'user_id');
      if (kDebugMode) print('[AUTH_CONTROLLER] Tokens and user_id cleared successfully');
    } catch (e) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Error clearing tokens: $e');
    }
  }

  Future<void> _init() async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Starting initialization...');
    
    try {
      if (kDebugMode) print('[AUTH_CONTROLLER] Checking session validity...');
      final sessionResult = await _authService.checkSession();
      
      if (!sessionResult.isValid) {
        if (kDebugMode) print('[AUTH_CONTROLLER] Session invalid - checking if should clear tokens');
        
        // Only clear tokens if backend explicitly says to logout
        if (sessionResult.shouldLogout) {
          if (kDebugMode) print('[AUTH_CONTROLLER] Backend says logout - clearing tokens');
          await _clearTokens();
        }
        
        state = const AsyncValue.data(null);
        
        if (sessionResult.isForceLogout) {
          await Future.delayed(const Duration(milliseconds: 500));
          _showForceLogoutNotification(sessionResult.message);
        }
        return;
      }
      
      if (kDebugMode) print('[AUTH_CONTROLLER] Session valid - fetching user data...');
      final user = await _authService.getUser();
      
      if (user != null) {
        state = AsyncValue.data(user);
        startPollingSession();
        if (kDebugMode) print('[AUTH_CONTROLLER] Initialization complete for user: ${user.name}');
      } else {
        if (kDebugMode) print('[AUTH_CONTROLLER] No user data found');
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[AUTH_CONTROLLER] Initialization error: $e');
        print('[AUTH_CONTROLLER] Stack trace: $st');
      }
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Starting login process...');
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.login(email, password);
      state = AsyncValue.data(user);
      startPollingSession();
      if (kDebugMode) print('[AUTH_CONTROLLER] Login successful for: ${user.name}');
      
      _showSnackBar("🎉 Welcome back, ${user.name}!", Colors.green);
    } catch (e, st) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Login failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Starting registration process...');
    state = const AsyncValue.loading();
    
    try {
      final user = await _authService.register(name, email, password, role);
      
      if (user.allowAccess == false) {
        if (kDebugMode) print('[AUTH_CONTROLLER] Registration pending approval for: ${user.name}');
        state = AsyncValue.data(user); // show pending screen
        _showSnackBar("⏳ Registration successful! Awaiting approval.", Colors.orange);
      } else {
        if (kDebugMode) print('[AUTH_CONTROLLER] Registration successful for: ${user.name}');
        state = AsyncValue.data(user);
        startPollingSession();
        _showSnackBar("🎉 Registration successful! Welcome, ${user.name}!", Colors.green);
      }
    } catch (e, st) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Registration failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  // Add confirmation dialog for logout
  Future<void> requestLogout() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // Direct logout if no context
      await logout();
      return;
    }

    final user = state.value;
    if (user == null) {
      if (kDebugMode) print('[AUTH_CONTROLLER] No user to logout');
      return;
    }

    if (kDebugMode) print('[AUTH_CONTROLLER] Showing logout confirmation dialog');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 8),
            Text("Confirm Logout"),
          ],
        ),
        content: Text("Are you sure you want to logout, ${user.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await logout();
    } else {
      if (kDebugMode) print('[AUTH_CONTROLLER] Logout cancelled by user');
    }
  }

  Future<void> logout() async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Starting logout process...');
    stopPollingSession();
    
    final user = state.value;
    if (user == null) {
      if (kDebugMode) print('[AUTH_CONTROLLER] No user to logout');
      return;
    }

    try {
      if (kDebugMode) print('[AUTH_CONTROLLER] Sending logout request for: ${user.email}');
      final logoutResult = await _authService.logout(user.email);
      
      if (kDebugMode) print('[AUTH_CONTROLLER] Logout result: $logoutResult');
      
      if (logoutResult['showPopup'] == true) {
        _showLogoutDialog(
          logoutResult['message'] ?? 'You have been logged out successfully.',
          logoutResult['success'] == true,
        );
      }
      
      if (kDebugMode) print('[AUTH_CONTROLLER] Server logout completed');
    } catch (e) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Server logout failed: $e');
      _showLogoutDialog('Logout failed: $e', false);
    } finally {
      await _clearTokens();
      state = const AsyncValue.data(null);
      if (kDebugMode) print('[AUTH_CONTROLLER] Logout completed');
    }
  }

  void clear() {
    if (kDebugMode) print('[AUTH_CONTROLLER] Clearing auth state...');
    stopPollingSession();
    state = const AsyncValue.data(null);
  }

  Future<User?> refreshAndReturnUser() async {
    if (kDebugMode) print('[AUTH_CONTROLLER] Refreshing user data...');
    
    try {
      final sessionResult = await _authService.checkSession();
      if (!sessionResult.isValid) {
        if (kDebugMode) print('[AUTH_CONTROLLER] Session invalid during refresh');
        state = const AsyncValue.data(null);
        
        if (sessionResult.isForceLogout) {
          _showForceLogoutNotification(sessionResult.message);
        }
        return null;
      }

      final user = await _authService.getUser();
      if (user != null) {
        state = AsyncValue.data(user);
        if (kDebugMode) print('[AUTH_CONTROLLER] User data refreshed: ${user.name}');
      }
      return user;
    } catch (e, st) {
      if (kDebugMode) print('[AUTH_CONTROLLER] Refresh failed: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
