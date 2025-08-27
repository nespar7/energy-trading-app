import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // OK for 6.1.5

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on Exception catch (e, st) {
      // Some buggy versions throw even though the user is actually signed in.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // fabricate a minimal UserCredential-like result if you need it downstream
        // or just return null and rely on authStateChanges()
        // print('Recovered from plugin decode issue: ${user.uid}');
      } else {
        // Log & surface
        // ignore: avoid_print
        print('Error during Google sign-in: $e\n$st');
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogleNative() async {
    try {
      final googleProvider = GoogleAuthProvider();
      // Optional scopes:
      // googleProvider.addScope('email');
      // googleProvider.setCustomParameters({'prompt': 'select_account'});

      final cred = await FirebaseAuth.instance.signInWithProvider(
        googleProvider,
      );
      return cred;
    } catch (e, st) {
      // ignore: avoid_print
      print('Error during Google sign-in: $e\n$st');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Error signing out: $e');
    }
  }
}
