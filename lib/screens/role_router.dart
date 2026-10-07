import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_home.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

/// Decides the landing screen after auth actions based on user role.
/// Admins go to [AdminHomeScreen], customers to [HomeScreen].
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.isAdmin) return const AdminHomeScreen();
    // Profile may still be loading right after login; while the
    // Firebase user exists we wait briefly for the role, then
    // default to the customer home.
    if (auth.profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }
    return const HomeScreen();
  }
}
