import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import 'admin/admin_home_screen.dart';
import 'supervisor/supervisor_home_screen.dart';
import 'student/student_home_screen.dart';

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

        // Route to appropriate home screen based on role
        switch (user.role) {
          case 'admin':
            return const AdminHomeScreen();
          case 'supervisor':
            return const SupervisorHomeScreen();
          case 'student':
            return const StudentHomeScreen();
          default:
            return Scaffold(
              appBar: AppBar(title: const Text("Unknown Role")),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      "Unknown role: ${user.role}",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              ),
            );
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text("Error: $e"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).refreshAndReturnUser();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
