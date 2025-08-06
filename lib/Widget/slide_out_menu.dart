// lib/Widget/slide_out_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/navigation_service.dart';

class SlideOutMenu extends ConsumerWidget {
  final VoidCallback onLogout;

  const SlideOutMenu({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Drawer(
            child: Center(child: Text("Not authenticated")),
          );
        }

        final menuItems = _getMenuItemsForRole(user.role ?? '', context);

        return Drawer(
          child: Column(
            children: [
              // Custom Drawer Header
              _buildDrawerHeader(user),
              
              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Role-specific menu items
                    ...menuItems.map((item) => _buildMenuItem(
                      context,
                      item['icon'] as IconData,
                      item['title'] as String,
                      item['subtitle'] as String?,
                      item['onTap'] as VoidCallback,
                      item['color'] as Color?,
                    )),
                    
                    const Divider(),
                    
                    // Common items
                    _buildMenuItem(
                      context,
                      Icons.person,
                      "Profile",
                      "Account details",
                      () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Profile")),
                      Colors.grey.shade700,
                    ),
                    
                    _buildMenuItem(
                      context,
                      Icons.settings,
                      "Settings",
                      "Account & preferences",
                      () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Settings")),
                      Colors.grey.shade700,
                    ),
                    
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      "Help & Support",
                      "Get assistance",
                      () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Help & Support")),
                      Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
              
              // Logout at bottom
              const Divider(),
              _buildMenuItem(
                context,
                Icons.logout,
                "Logout",
                "Sign out of your account",
                () => _safeNavigate(context, onLogout),
                Colors.red.shade700,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => const Drawer(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const Drawer(
        child: Center(child: Text("Error loading menu")),
      ),
    );
  }

  // Safe navigation method that properly handles drawer closing
  void _safeNavigate(BuildContext context, VoidCallback action) {
    // Check if we can pop (drawer is open)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Add a small delay to ensure drawer animation completes
    Future.delayed(const Duration(milliseconds: 250), () {
      action();
    });
  }

  Widget _buildDrawerHeader(User user) {
    Color roleColor;
    IconData roleIcon;
    String roleTitle;

    switch (user.role) {
      case 'admin':
        roleColor = Colors.red.shade700;
        roleIcon = Icons.admin_panel_settings;
        roleTitle = "Administrator";
        break;
      case 'supervisor':
        roleColor = Colors.green.shade700;
        roleIcon = Icons.supervisor_account;
        roleTitle = "Supervisor";
        break;
      case 'student':
        roleColor = Colors.blue.shade700;
        roleIcon = Icons.school;
        roleTitle = "Student";
        break;
      default:
        roleColor = Colors.grey.shade700;
        roleIcon = Icons.person;
        roleTitle = "User";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [roleColor, roleColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(roleIcon, size: 32, color: roleColor),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            roleTitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            user.email,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          if (user.department != null) ...[
            const SizedBox(height: 4),
            Text(
              "Department: ${user.department}",
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
    Color? color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? Colors.grey.shade800,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  List<Map<String, dynamic>> _getMenuItemsForRole(String role, BuildContext context) {
    switch (role) {
      case 'admin':
        return _getAdminMenuItems(context);
      case 'supervisor':
        return _getSupervisorMenuItems(context);
      case 'student':
        return _getStudentMenuItems(context);
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getAdminMenuItems(BuildContext context) {
    return [
      {
        'icon': Icons.dashboard,
        'title': 'Dashboard',
        'subtitle': 'System overview',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Admin Dashboard")),
        'color': Colors.red.shade700,
      },
      {
        'icon': Icons.people_alt,
        'title': 'User Management',
        'subtitle': 'Manage all users',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "User Management")),
        'color': Colors.blue.shade700,
      },
      {
        'icon': Icons.approval,
        'title': 'User Approvals',
        'subtitle': 'Pending registrations',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "User Approvals")),
        'color': Colors.orange.shade700,
      },
      {
        'icon': Icons.assignment,
        'title': 'Thesis Management',
        'subtitle': 'All thesis projects',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Thesis Management")),
        'color': Colors.purple.shade700,
      },
      {
        'icon': Icons.school,
        'title': 'Department Management',
        'subtitle': 'Manage departments',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Department Management")),
        'color': Colors.teal.shade700,
      },
      {
        'icon': Icons.analytics,
        'title': 'Reports & Analytics',
        'subtitle': 'System statistics',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Reports & Analytics")),
        'color': Colors.green.shade700,
      },
      {
        'icon': Icons.security,
        'title': 'System Security',
        'subtitle': 'Security settings',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "System Security")),
        'color': Colors.deepOrange.shade700,
      },
      {
        'icon': Icons.backup,
        'title': 'Backup & Restore',
        'subtitle': 'Data management',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Backup & Restore")),
        'color': Colors.indigo.shade700,
      },
    ];
  }

  List<Map<String, dynamic>> _getSupervisorMenuItems(BuildContext context) {
    return [
      {
        'icon': Icons.dashboard,
        'title': 'Dashboard',
        'subtitle': 'My overview',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Supervisor Dashboard")),
        'color': Colors.green.shade700,
      },
      {
        'icon': Icons.group,
        'title': 'My Students',
        'subtitle': 'Supervised students',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "My Students")),
        'color': Colors.blue.shade700,
      },
      {
        'icon': Icons.assignment_turned_in,
        'title': 'Thesis Reviews',
        'subtitle': 'Pending reviews',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Thesis Reviews")),
        'color': Colors.orange.shade700,
      },
      {
        'icon': Icons.schedule,
        'title': 'Meetings',
        'subtitle': 'Schedule & history',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Meetings")),
        'color': Colors.purple.shade700,
      },
      {
        'icon': Icons.rate_review,
        'title': 'Feedback & Comments',
        'subtitle': 'Student feedback',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Feedback & Comments")),
        'color': Colors.teal.shade700,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Progress Tracking',
        'subtitle': 'Student progress',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Progress Tracking")),
        'color': Colors.indigo.shade700,
      },
      {
        'icon': Icons.library_books,
        'title': 'Research Resources',
        'subtitle': 'Academic materials',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Research Resources")),
        'color': Colors.brown.shade700,
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Academic Calendar',
        'subtitle': 'Important dates',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Academic Calendar")),
        'color': Colors.deepPurple.shade700,
      },
    ];
  }

  List<Map<String, dynamic>> _getStudentMenuItems(BuildContext context) {
    return [
      {
        'icon': Icons.dashboard,
        'title': 'Dashboard',
        'subtitle': 'My overview',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Student Dashboard")),
        'color': Colors.blue.shade700,
      },
      {
        'icon': Icons.assignment,
        'title': 'My Thesis',
        'subtitle': 'Thesis progress',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "My Thesis")),
        'color': Colors.green.shade700,
      },
      {
        'icon': Icons.upload_file,
        'title': 'Submit Chapter',
        'subtitle': 'Upload documents',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Submit Chapter")),
        'color': Colors.orange.shade700,
      },
      {
        'icon': Icons.feedback,
        'title': 'Supervisor Feedback',
        'subtitle': 'View comments',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Supervisor Feedback")),
        'color': Colors.purple.shade700,
      },
      {
        'icon': Icons.schedule,
        'title': 'Schedule Meeting',
        'subtitle': 'Book appointments',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Schedule Meeting")),
        'color': Colors.teal.shade700,
      },
      {
        'icon': Icons.history,
        'title': 'Meeting History',
        'subtitle': 'Past meetings',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Meeting History")),
        'color': Colors.indigo.shade700,
      },
      {
        'icon': Icons.library_books,
        'title': 'Research Resources',
        'subtitle': 'Academic materials',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Research Resources")),
        'color': Colors.brown.shade700,
      },
      {
        'icon': Icons.timeline,
        'title': 'Progress Timeline',
        'subtitle': 'Track milestones',
        'onTap': () => _safeNavigate(context, () => NavigationService.showComingSoon(context, "Progress Timeline")),
        'color': Colors.deepOrange.shade700,
      },
    ];
  }
}
