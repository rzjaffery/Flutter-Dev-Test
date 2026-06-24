// lib/providers/auth_provider.dart
// Bridges Firebase Auth events to the widget tree using ChangeNotifier.
// All screens read auth state from here rather than touching Firebase directly.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Possible states for async auth operations
enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State Variables
  User? _user;
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  // Getters for external access
  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  // Constructor: Listen to Firebase Auth state changes and update the provider state accordingly
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners(); // Rebuild dependent widgets whenever auth state changes
    });
  }

  // Helpers to manage state transitions and notify listeners
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void _setSuccess() {
    _status = AuthStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // Register a new user with email, password, and display name
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Login an existing user with email and password
  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      await _authService.login(email: email, password: password);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Logout the currently authenticated user
  Future<void> logout() async {
    await _authService.logout();
    _status = AuthStatus.idle;
    notifyListeners();
  }

  // Send a password reset email to the specified email address
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Change the password for the currently authenticated user
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading();
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }
}