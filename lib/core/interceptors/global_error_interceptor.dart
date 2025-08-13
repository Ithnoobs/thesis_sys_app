// lib/core/interceptors/global_error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thesis_sys_app/Widget/force_logout_banner.dart';
import 'package:thesis_sys_app/controllers/auth_controller.dart';

class GlobalErrorInterceptor extends Interceptor {
  final BuildContext context;


  void showForceLogoutBanner(BuildContext context) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: ForceLogoutBanner(message: 'You have been logged out.'),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 4), () {
    overlayEntry.remove();
  });
}


  GlobalErrorInterceptor(this.context);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    final path = err.requestOptions.path;

    if (res != null) {
      final statusCode = res.statusCode;
      final message = res.data?['message'] ?? 'Unexpected error';

      // Don't intercept auth-related endpoints - let the auth service handle them completely
      final isAuthEndpoint = path.contains('/login') || path.contains('/register');
      final isProfileEndpoint = path.contains('/profile-');
      
      if (!isAuthEndpoint && !isProfileEndpoint) {
        switch (statusCode) {
          case 400:
            _showSnackBar("⏳ $message", Colors.orange);
            break;
          case 401:
          final container = ProviderScope.containerOf(context, listen: false);
          final lowerMsg = message.toString().toLowerCase();

          // Force logout case (from check-session)
          if (lowerMsg.contains('force logout')) {
            container.read(authControllerProvider.notifier).clear();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text("Session Ended"),
                content: const Text("You have been logged out from another device."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      context.go('/login');
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          } else {
            // Normal 401 (e.g., expired token or manual logout fallback)
            _showSnackBar("🔒 $message", Colors.red);
            container.read(authControllerProvider.notifier).clear();
            context.go('/login');
          }
          break;
          case 404:
            _showSnackBar("❌ $message", Colors.red);
            break;
          default:
            _showSnackBar("⚠️ $message", Colors.grey);
        }
      } else if (statusCode == 401 && path.contains('/check-session')) {
        // Handle session check 401s specially
        final container = ProviderScope.containerOf(context, listen: false);
        final lowerMsg = message.toString().toLowerCase();

        // Force logout case (from check-session)
        if (lowerMsg.contains('force logout')) {
          container.read(authControllerProvider.notifier).clear();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Session Ended"),
              content: const Text("You have been logged out from another device."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    context.go('/login');
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } else {
      // Only show network errors for non-auth endpoints
      final isAuthEndpoint = path.contains('/login') || path.contains('/register');
      if (!isAuthEndpoint) {
        _showSnackBar("🚫 Network error: ${err.message}", Colors.red);
      }
    }

    // Always pass the error through unchanged
    handler.next(err);
  }

  void _showSnackBar(String text, Color color) {
    final snackBar = SnackBar(
      content: Text(text),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
