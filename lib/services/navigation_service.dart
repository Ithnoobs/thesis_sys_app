import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Admin Navigation Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String userManagement = '/admin/users';
  static const String userApprovals = '/admin/approvals';
  static const String thesisManagement = '/admin/thesis';
  static const String departmentManagement = '/admin/departments';
  static const String adminReports = '/admin/reports';
  static const String systemSecurity = '/admin/security';
  static const String backupRestore = '/admin/backup';

  // Supervisor Navigation Routes
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String myStudents = '/supervisor/students';
  static const String thesisReviews = '/supervisor/reviews';
  static const String supervisorMeetings = '/supervisor/meetings';
  static const String supervisorFeedback = '/supervisor/feedback';
  static const String progressTracking = '/supervisor/progress';
  static const String supervisorResources = '/supervisor/resources';
  static const String academicCalendar = '/supervisor/calendar';

  // Student Navigation Routes
  static const String studentDashboard = '/student/dashboard';
  static const String myThesis = '/student/thesis';
  static const String submitChapter = '/student/submit';
  static const String viewFeedback = '/student/feedback';
  static const String scheduleMeeting = '/student/schedule';
  static const String meetingHistory = '/student/meetings';
  static const String studentResources = '/student/resources';
  static const String progressTimeline = '/student/timeline';

  // Common Routes
  static const String settings = '/settings';
  static const String help = '/help';
  static const String profile = '/profile';

  // Safe navigation helper methods
  static void navigateToRoute(BuildContext context, String route) {
    try {
      if (context.mounted) {
        context.go(route);
      }
    } catch (e) {
      debugPrint('[NAVIGATION] Error navigating to $route: $e');
      // Fallback: show snackbar with error
      showNavigationError(context, "Navigation failed");
    }
  }

  static void navigateToRouteWithParams(
    BuildContext context,
    String route,
    Map<String, String> params,
  ) {
    try {
      if (context.mounted) {
        String fullRoute = route;
        params.forEach((key, value) {
          fullRoute = fullRoute.replaceAll(':$key', value);
        });
        context.go(fullRoute);
      }
    } catch (e) {
      debugPrint('[NAVIGATION] Error navigating to $route with params: $e');
      showNavigationError(context, "Navigation failed");
    }
  }

  // Role-specific navigation helpers
  static void navigateToRoleDashboard(BuildContext context, String role) {
    try {
      if (!context.mounted) return;

      switch (role) {
        case 'admin':
          context.go(adminDashboard);
          break;
        case 'supervisor':
          context.go(supervisorDashboard);
          break;
        case 'student':
          context.go(studentDashboard);
          break;
        default:
          context.go('/home');
      }
    } catch (e) {
      debugPrint('[NAVIGATION] Error navigating to role dashboard: $e');
      showNavigationError(context, "Dashboard navigation failed");
    }
  }

  // Safe replacement navigation (prevents stack issues)
  static void replaceWithRoute(BuildContext context, String route) {
    try {
      if (context.mounted) {
        context.pushReplacement(route);
      }
    } catch (e) {
      debugPrint('[NAVIGATION] Error replacing with $route: $e');
      // Fallback to go
      navigateToRoute(context, route);
    }
  }

  // Quick access methods for common actions
  static void showComingSoon(BuildContext context, String feature) {
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$feature - Coming Soon"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NAVIGATION] Error showing coming soon message: $e');
    }
  }

  static void showFeatureNotAvailable(BuildContext context, String feature) {
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$feature is not available in your current role"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      debugPrint('[NAVIGATION] Error showing feature not available message: $e');
    }
  }

  static void showNavigationError(BuildContext context, String message) {
    if (!context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      debugPrint('[NAVIGATION] Error showing navigation error: $e');
    }
  }

  // Check if navigation is safe
  static bool canNavigate(BuildContext context) {
    return context.mounted;
  }

  // Safe pop with fallback
  static void safePop(BuildContext context) {
    try {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[NAVIGATION] Error popping: $e');
    }
  }
}