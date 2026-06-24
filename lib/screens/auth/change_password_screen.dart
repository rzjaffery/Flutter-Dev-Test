import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

// Screen for changing the user's password


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  // Form key to manage form state and validation
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input for current, new, and confirm password fields
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dispose controllers to free up resources when the widget is removed from the widget tree
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Failed to update password'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    // Watch the AuthProvider to rebuild the UI when its state changes (e.g., loading state)
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body:
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child:Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security, size: 56, color: AppTheme.primary),
                const SizedBox(height: 24),
                const Text(
                  'Update Password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new one.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // Current Password Field
                CustomTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  prefixIcon: Icons.lock_outlined,
                  isPassword: true,
                  validator: (val) => Validators.required(val, 'Current password'),
                ),
                const SizedBox(height: 16),

                // New Password Field

                CustomTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) => Validators.password(val),
                ),
                const SizedBox(height: 16),

                // Confirm New Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (val != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Update Password Button
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Update Password'),
                ),
              ],
            )
          )
        )
    );
  }
}
