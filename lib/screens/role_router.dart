import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_home.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

/// Decides the landing screen after auth actions based on user role.
/// Admins go to [AdminHomeScreen], customers to [HomeScreen].
///
/// If the profile document is slow to load (or its read fails),
/// falls back to the customer home after a timeout instead of
/// spinning forever. When the profile later arrives, this widget
/// rebuilds and routes to the admin home if needed.
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.isAdmin) return const AdminHomeScreen();
    // Profile may still be loading right after login; while the
    // Firebase user exists we wait briefly for the role, then
    // default to the customer home.
    if (auth.profile == null && !_timedOut) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        ),
      );
    }
    return const HomeScreen();
  }
}
