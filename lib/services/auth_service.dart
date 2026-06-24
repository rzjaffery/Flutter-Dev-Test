import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

// handles all Firebase operations related to authentication

class AuthService {
  // Firebase Singletons
  final FirebaseAuth _auth =FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Convenience getter to access the currently logged-in user
  User? get currentUser => _auth.currentUser;

  // REGISTER
  /// Registers a new user with email and password, and creates a corresponding Firestore document.
  Future<UserModel?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create the Auth account
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Update the display name on the Auth profile
      await cred.user!.updateDisplayName(displayName.trim());

      // 3. Persist extra user data to Firestore /users/{uid}
      final UserModel user = UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(cred.user!.uid).set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      // Re-throw with a readable message
      throw _handleAuthError(e);
    }
  }

  // LOGIN
  /// Logs in an existing user with email and password.
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // LOGOUT
  /// Logs out the currently authenticated user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // FORGOT PASSWORD
  /// Sends a password reset email to the specified email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // CHANGE PASSWORD
  /// Changes the password for the currently authenticated user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in.');

      // Re-authenticate first — Firebase requires a recent sign-in for sensitive ops
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Now update
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // PRIVATE: Handle FirebaseAuthException and convert to user-friendly messages
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('This email is already registered.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'weak-password':
        return Exception('Password must be at least 6 characters.');
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      case 'requires-recent-login':
        return Exception('Please log out and log back in before changing your password.');
      default:
        return Exception(e.message ?? 'An authentication error occurred.');
    }
  }
}