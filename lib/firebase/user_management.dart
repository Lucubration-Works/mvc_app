import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUser {
  final String userId;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final bool isEmailVerified;

  FirebaseUser({
    required this.userId,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.isEmailVerified,
  });

  static Future<FirebaseUser> signIn(String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if (user != null) {
      return FirebaseUser(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName ?? '',
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
      );
    } else {
      throw FirebaseAuthException(
          code: 'user-not-found', message: 'User not found.');
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<void> deleteUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}

class FirebaseUserManager {
  Future<FirebaseUser> createUser(String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if (user != null) {
      return FirebaseUser(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName ?? '',
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
      );
    } else {
      throw FirebaseAuthException(
          code: 'user-creation-failed', message: 'User creation failed.');
    }
  }

  Future<FirebaseUser?> getUser(String userId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == userId) {
      return FirebaseUser(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName ?? '',
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
      );
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == userId) {
      await user.delete();
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == userId) {
      await user.updateEmail(userData['email']);
      await user.updateDisplayName(userData['displayName']);
      await user.updatePhotoURL(userData['photoUrl']);
    }
  }

  Future<List<FirebaseUser>> listAllUsers() async {
    // Firebase Auth SDK doğrudan tüm kullanıcıları listelemek için bir işlev sunmaz.
    // Bu işlemi yapmak için bir kullanıcı veritabanı kullanmak gerekebilir.
    return [];
  }
}
