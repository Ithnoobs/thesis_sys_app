import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thesis_sys_app/Widget/slide_out_menu.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text("Not authenticated")),
          );
        }

        Widget _buildContent(User user) {
          switch (user.role) {
            case 'admin':
              return _AdminView(user: user);
            case 'supervisor':
              return _SupervisorView(user: user);
            case 'student':
              return _StudentView(user: user);
            default:
              return const Center(child: Text("Unknown role"));
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Home")),
          drawer: SlideOutMenu(
            onLogout: () async {
              final user = ref.read(authControllerProvider).value;
              if (user == null) return;

              // Force logout everywhere
              await ref.read(authServiceProvider).logout(user.email);
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
          body: _buildContent(user),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _AdminView extends StatelessWidget {
  final User user;
  const _AdminView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("👑 Welcome Admin ${user.name}", style: const TextStyle(fontSize: 18)),
    );
  }
}

class _SupervisorView extends StatelessWidget {
  final User user;
  const _SupervisorView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("🧑‍🏫 Welcome Supervisor ${user.name}", style: const TextStyle(fontSize: 18)),
    );
  }
}

class _StudentView extends StatelessWidget {
  final User user;
  const _StudentView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("🎓 Welcome Student ${user.name}", style: const TextStyle(fontSize: 18)),
    );
  }
}
