// lib/Widget/slide_out_menu.dart
import 'package:flutter/material.dart';

class SlideOutMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const SlideOutMenu({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(child: Text("Menu", style: TextStyle(fontSize: 24))),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
