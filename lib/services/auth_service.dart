import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Register with email + password, then create the user document.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await _db.collection('users').doc(credential.user!.uid).set(
          AppUser(
            uid: credential.user!.uid,
            name: name.trim(),
            email: email.trim(),
          ).toMap(),
        );
    return credential;
  }

  /// Sign in with email + password.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Google. Creates the user document on first login.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final doc =
        await _db.collection('users').doc(userCredential.user!.uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(userCredential.user!.uid).set(
            AppUser(
              uid: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Bings User',
              email: userCredential.user!.email ?? '',
              photoUrl: userCredential.user!.photoURL,
            ).toMap(),
          );
    }
    return userCredential;
  }

  /// Send a password reset email.
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out from Firebase + Google.
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Stream of the signed-in user's Firestore profile document.
  Stream<AppUser?> userProfileStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.data()!) : null);
  }

  /// Update profile fields (name, address, phone).
  Future<void> updateProfile(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).update(data);
  }
}
