import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thesis_sys_app/screens/home_screen.dart';
import 'package:thesis_sys_app/screens/login_screen.dart';
import 'package:thesis_sys_app/screens/register_screen.dart';
import 'package:thesis_sys_app/screens/pending_approval_screen.dart';
import 'package:thesis_sys_app/screens/unauthorized_screen.dart';
import 'package:thesis_sys_app/screens/profile_screen.dart';
import 'package:thesis_sys_app/controllers/auth_controller.dart';
import 'package:thesis_sys_app/router/navigation_service.dart' show navigatorKey;

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authControllerProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final user = auth.valueOrNull;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';

      if (auth.isLoading) return null;

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (user.role == 'supervisor' && !(user.allowAccess ?? false)) {
        return '/pending';
      }

      if (isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingApprovalScreen()),
      GoRoute(path: '/unauthorized', builder: (_, __) => const UnauthorizedScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
