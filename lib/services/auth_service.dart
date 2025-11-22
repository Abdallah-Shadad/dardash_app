import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In with Email
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthErrors(e.code));
    }
  }

  // Sign Up with Email & Save User Data
  Future<UserCredential> signUpWithEmail(
      String email, String password, String username) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Save user info to Firestore
      await _saveUserToFirestore(cred.user!, username);

      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthErrors(e.code));
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential cred = await _auth.signInWithCredential(credential);

      // Check if user exists, if not, save them
      final userDoc =
          await _firestore.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        await _saveUserToFirestore(
            cred.user!, cred.user!.displayName ?? 'User');
      }
      return cred;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Helper: Save User Data
  Future<void> _saveUserToFirestore(User user, String username) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': username,
      'createdAt': Timestamp.now(),
    });
  }

  // Helper: Error Messages
  String _handleAuthErrors(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'An authentication error occurred.';
    }
  }
}
