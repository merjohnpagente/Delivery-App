import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Exposes Firebase auth state + profile to the widget tree.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  AppUser? _profile;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _authService.userProfileStream(user.uid).listen((profile) {
        _profile = profile;
        notifyListeners();
      });
    } else {
      _profile = null;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _guard(() => _authService.register(
          name: name,
          email: email,
          password: password,
        ));
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _guard(
        () => _authService.login(email: email, password: password));
  }

  Future<bool> signInWithGoogle() async {
    return _guard(() => _authService.signInWithGoogle());
  }

  Future<bool> sendPasswordReset(String email) async {
    return _guard(() => _authService.sendPasswordReset(email));
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_firebaseUser == null) return false;
    return _guard(
        () => _authService.updateProfile(_firebaseUser!.uid, data));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _guard(Future Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'cancelled':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
