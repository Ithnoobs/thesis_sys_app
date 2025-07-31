import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thesis_sys_app/controllers/auth_controller.dart';

String? authGuard(GoRouterState state, WidgetRef ref) {
  final auth = ref.read(authControllerProvider);

  final user = auth.valueOrNull;

  if (user == null) {
    return '/login';
  }

  final role = user.role;
  final allowAccess = user.allowAccess ?? false;

  if (state.fullPath == '/admin' && role != 'admin') {
    return '/unauthorized';
  }

  if (state.fullPath == '/supervisor' && role != 'supervisor') {
    return '/unauthorized';
  }

  if (state.fullPath == '/pending' && allowAccess) {
    return '/home';
  }

  return null; // allow access
}
