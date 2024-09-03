import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../firebase/user_management.dart';

class SignInPageController {
  TextEditingController email_controller = TextEditingController();
  TextEditingController forget_email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();

  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          return true;
        } else {
          // Kullanıcının e-posta adresi doğrulanmamış
          return false;
        }
      } else {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'User not found.');
      }
    } catch (e) {
      print('Sign In Error: $e');
      return false;
    }
  }
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

}
