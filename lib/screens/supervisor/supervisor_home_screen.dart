import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../Widget/slide_out_menu.dart';

class SupervisorHomeScreen extends ConsumerWidget {
  const SupervisorHomeScreen({super.key});

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
            title: const Text("Supervisor Dashboard"),
            backgroundColor: Colors.green.shade700,
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
                      colors: [Colors.green.shade700, Colors.green.shade900],
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
                          Icon(Icons.supervisor_account, 
                               color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            "Supervisor Dashboard",
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
                      if (user.department != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Department: ${user.department}",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Stats
                const Text(
                  "My Students Overview",
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
                        "Total Students",
                        "12",
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Active Thesis",
                        "8",
                        Icons.assignment,
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
                        "Pending Reviews",
                        "3",
                        Icons.rate_review,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        "Completed",
                        "5",
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Supervisor Actions
                const Text(
                  "Supervisor Actions",
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
                      "My Students",
                      Icons.group,
                      Colors.blue,
                      () => _navigateToStudents(context),
                    ),
                    _buildActionCard(
                      "Thesis Reviews",
                      Icons.rate_review,
                      Colors.orange,
                      () => _navigateToReviews(context),
                    ),
                    _buildActionCard(
                      "Schedule Meeting",
                      Icons.schedule,
                      Colors.purple,
                      () => _navigateToSchedule(context),
                    ),
                    _buildActionCard(
                      "Progress Reports",
                      Icons.trending_up,
                      Colors.green,
                      () => _navigateToProgress(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent Activities
                const Text(
                  "Recent Activities",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildRecentActivities(),
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

  Widget _buildRecentActivities() {
    final activities = [
      {
        'title': 'John Doe submitted Chapter 3',
        'time': '2 hours ago',
        'icon': Icons.upload_file,
        'color': Colors.blue,
      },
      {
        'title': 'Meeting scheduled with Jane Smith',
        'time': '1 day ago',
        'icon': Icons.schedule,
        'color': Colors.green,
      },
      {
        'title': 'Review completed for Mike Johnson',
        'time': '2 days ago',
        'icon': Icons.check_circle,
        'color': Colors.orange,
      },
    ];

    return Container(
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
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
            ),
            title: Text(activity['title'] as String),
            subtitle: Text(activity['time'] as String),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Activity: ${activity['title']}")),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToStudents(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("My Students - Coming Soon")),
    );
  }

  void _navigateToReviews(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thesis Reviews - Coming Soon")),
    );
  }

  void _navigateToSchedule(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Schedule Meeting - Coming Soon")),
    );
  }

  void _navigateToProgress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progress Reports - Coming Soon")),
    );
  }
}