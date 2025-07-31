// lib/screens/pending_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import 'package:thesis_sys_app/router/navigation_service.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 64, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Your account is awaiting admin approval.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please wait while an administrator reviews your request.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () async {
                  final user = await ref.read(authControllerProvider.notifier).refreshAndReturnUser();

                  if (user != null && user.allowAccess == true) {
                    navigatorKey.currentContext?.go('/home');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Still pending approval..."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                label: const Text("Retry", style: TextStyle(color: Colors.blueAccent)),
              ),


              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  await controller.logout();
                  navigatorKey.currentContext?.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
