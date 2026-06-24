import 'package:flutter/material.dart';

// UserModel represents a user in the application, typically stored in Firestore
class UserModel {
  // Represents a user in the application
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;

// Constructor for creating a new UserModel instance
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from a map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Converts the UserModel instance to a map for storage (e.g., Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}