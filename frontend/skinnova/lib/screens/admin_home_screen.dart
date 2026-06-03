import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

// AdminHomeScreen now delegates to the full AdminDashboard.
// The app routes here on login for role=="admin".
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminDashboard();
}
