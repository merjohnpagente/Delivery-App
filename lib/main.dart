import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../firebase_options.dart';
import '../models/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/food_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BingsApp());
}

class BingsApp extends StatelessWidget {
  const BingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
      ],
      child: MaterialApp(
        title: 'Bings',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes to Home when logged in, Login when logged out,
/// showing the splash screen while auth state is loading.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // While Firebase restores the session, show the splash screen.
    if (auth.firebaseUser == null && auth.profile == null) {
      // Give Firebase a moment; if still logged out, show login.
      // AuthProvider starts with nulls, so check a short delay via
      // FutureBuilder-like behavior: show splash first.
      return const _SplashOrLogin();
    }
    if (auth.isLoggedIn) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

class _SplashOrLogin extends StatefulWidget {
  const _SplashOrLogin();

  @override
  State<_SplashOrLogin> createState() => _SplashOrLoginState();
}

class _SplashOrLoginState extends State<_SplashOrLogin> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const HomeScreen();
    if (!_splashDone) return const SplashScreen();
    return const LoginScreen();
  }
}
