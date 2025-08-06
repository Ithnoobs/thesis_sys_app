import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../Widget/slide_out_menu.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

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

        return Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).requestLogout();
                },
                tooltip: "Logout",
              ),
            ],
          ),
          drawer: SlideOutMenu(
            onLogout: () async {
              await ref.read(authControllerProvider.notifier).requestLogout();
            },
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.admin_panel_settings, 
                               color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            "Admin Dashboard",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Welcome back, ${user.name}!",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Stats
                const Text(
                  "Quick Overview",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Total Users",
                        "125",
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Pending Approvals",
                        "8",
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Active Supervisors",
                        "15",
                        Icons.supervisor_account,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Active Students",
                        "102",
                        Icons.school,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Admin Actions
                const Text(
                  "Admin Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      "User Management",
                      Icons.manage_accounts,
                      Colors.blue,
                      () => _navigateToUserManagement(context),
                    ),
                    _buildActionCard(
                      "Approve Users",
                      Icons.approval,
                      Colors.orange,
                      () => _navigateToApprovalPage(context),
                    ),
                    _buildActionCard(
                      "System Settings",
                      Icons.settings,
                      Colors.grey,
                      () => _navigateToSettings(context),
                    ),
                    _buildActionCard(
                      "Reports",
                      Icons.analytics,
                      Colors.green,
                      () => _navigateToReports(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUserManagement(BuildContext context) {
    // TODO: Navigate to user management page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User Management - Coming Soon")),
    );
  }

  void _navigateToApprovalPage(BuildContext context) {
    // TODO: Navigate to approval page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User Approval - Coming Soon")),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // TODO: Navigate to settings page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("System Settings - Coming Soon")),
    );
  }

  void _navigateToReports(BuildContext context) {
    // TODO: Navigate to reports page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reports - Coming Soon")),
    );
  }
}