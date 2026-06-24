import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:product_catalogue/services/auth_service.dart';

// Bridges Firebase Auth events to the widget tree using ChangeNotifier.
// All screens read auth state from here rather than touching Firebase directly.

// AuthStatus represents the current authentication state of the user.
enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State variables
  AuthStatus _status = AuthStatus.idle;
  User? _user;
  String? _errorMessage;

  // Getters for external access
  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  // Constructor: Listen to Firebase auth state changes
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Helpers
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

  // REGISTER
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

  // LOGIN
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

  // LOGOUT
  Future<void> logout() async {
    await _authService.logout();
    _status = AuthStatus.idle;
    notifyListeners();
  }

  //FORGOT PASSWORD
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

  // CHANGE PASSWORD
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
