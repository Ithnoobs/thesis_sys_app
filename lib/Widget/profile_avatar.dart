import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class ProfileAvatar extends StatelessWidget {
  final User? user;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;
  final Widget? fallbackWidget;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 30,
    this.borderColor,
    this.borderWidth = 2,
    this.showBorder = true,
    this.fallbackWidget,
  });

  static String? getFullImageUrl(String? profilePicture) {
    if (kDebugMode) print('[PROFILE_AVATAR] Input profilePicture: $profilePicture');
    
    if (profilePicture == null || profilePicture.isEmpty) {
      if (kDebugMode) print('[PROFILE_AVATAR] Profile picture is null or empty');
      return null;
    }
    
    // If it's already a full URL, return as is
    if (profilePicture.startsWith('http://') || profilePicture.startsWith('https://')) {
      if (kDebugMode) print('[PROFILE_AVATAR] Already full URL: $profilePicture');
      return profilePicture;
    }
    
    // Construct full URL from base server URL (without /api for static files)
    // Laravel typically serves storage files from the base server URL
    // Try both 10.0.2.2 (Android emulator) and 127.0.0.1 (direct)
    
    // For testing: switch between these URLs
    const String baseServerUrl = 'http://10.0.2.2:8000';
    //const String baseServerUrl = 'http://127.0.0.1:8000';  // Use this if 10.0.2.2 doesn't work
    
    if (kDebugMode) print('[PROFILE_AVATAR] Using base server URL: $baseServerUrl');
    
    String finalUrl;
    
    // If it starts with /storage, it's already a proper Laravel storage path
    if (profilePicture.startsWith('/storage/')) {
      finalUrl = '$baseServerUrl$profilePicture';
      if (kDebugMode) print('[PROFILE_AVATAR] Storage path detected: $finalUrl');
      return finalUrl;
    }
    
    // If it starts with 'profiles/', it's already in the profiles directory
    // Backend returns: "profiles/filename.jpg"
    // We need: "http://127.0.0.1:8000/storage/profiles/filename.jpg"
    if (profilePicture.startsWith('profiles/')) {
      finalUrl = '$baseServerUrl/storage/$profilePicture';
      if (kDebugMode) print('[PROFILE_AVATAR] Profiles path detected: $finalUrl');
      return finalUrl;
    }
    
    // If it's just a filename, assume it's in the profiles directory
    // Laravel storage/app/public/profiles maps to /storage/profiles
    if (!profilePicture.startsWith('/')) {
      finalUrl = '$baseServerUrl/storage/profiles/$profilePicture';
      if (kDebugMode) print('[PROFILE_AVATAR] Filename detected, constructed: $finalUrl');
      return finalUrl;
    }
    
    // Default case: prepend server URL
    finalUrl = '$baseServerUrl$profilePicture';
    if (kDebugMode) print('[PROFILE_AVATAR] Default case: $finalUrl');
    return finalUrl;
  }

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    IconData roleIcon;

    switch (user?.role) {
      case 'admin':
        roleColor = Colors.red.shade700;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'supervisor':
        roleColor = Colors.green.shade700;
        roleIcon = Icons.supervisor_account;
        break;
      case 'student':
        roleColor = Colors.blue.shade700;
        roleIcon = Icons.school;
        break;
      default:
        roleColor = Colors.grey.shade700;
        roleIcon = Icons.person;
    }

    Widget defaultFallback = Icon(
      roleIcon,
      size: radius * 0.6,
      color: roleColor,
    );

    final imageUrl = getFullImageUrl(user?.profilePicture);
    if (kDebugMode) print('[PROFILE_AVATAR] Final image URL: $imageUrl');

    return CircleAvatar(
      radius: radius,
      backgroundColor: borderColor ?? Colors.white,
      child: CircleAvatar(
        radius: showBorder ? radius - borderWidth : radius,
        backgroundColor: Colors.grey.shade200,
        child: imageUrl != null
            ? ClipOval(
                child: Image.network(
                  imageUrl,
                  width: (radius - (showBorder ? borderWidth : 0)) * 2,
                  height: (radius - (showBorder ? borderWidth : 0)) * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('[PROFILE_AVATAR] Image load error for URL: $imageUrl');
                      print('[PROFILE_AVATAR] Error: $error');
                      print('[PROFILE_AVATAR] StackTrace: $stackTrace');
                    }
                    return fallbackWidget ?? defaultFallback;
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      if (kDebugMode) print('[PROFILE_AVATAR] Image loaded successfully: $imageUrl');
                      return child;
                    }
                    if (kDebugMode) {
                      print('[PROFILE_AVATAR] Loading image: $imageUrl');
                      print('[PROFILE_AVATAR] Progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(roleColor),
                      ),
                    );
                  },
                ),
              )
            : (fallbackWidget ?? defaultFallback),
      ),
    );
  }
}
