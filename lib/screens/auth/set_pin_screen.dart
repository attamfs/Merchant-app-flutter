import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/translation_extension.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN must be 4 digits'.trRead(context))),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PINs do not match'.trRead(context))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get userId and crNumber passed from registration
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final user = FirebaseAuth.instance.currentUser;
      final userId = args?['userId'] as String? ?? user?.uid;
      final crNumber = args?['crNumber'] as String?;

      if (userId == null) throw Exception('No user found');

      // Save PIN to Firestore on the merchant document
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('merchants').doc(userId).update({'pin': pin});

      // Also update password to match the supervisor login format: crNumber-pin
      if (crNumber != null) {
        final newPassword = '$crNumber-$pin';
        await user?.updatePassword(newPassword);
      }

      // Sign out — AuthWrapper will show Login screen
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful! Please log in.'.trRead(context))),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (e) {
      debugPrint('SetPin error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PIN. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Set PIN'.tr(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a 4-digit PIN'.tr(context),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This PIN will be used to log in to your account.'.tr(context),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              Text('PIN'.tr(context), style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _pinController,
                hintText: 'Enter 4-digit PIN',
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 4,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    setState(() => _obscurePin = !_obscurePin);
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text('Confirm PIN'.tr(context), style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _confirmPinController,
                hintText: 'Re-enter 4-digit PIN',
                keyboardType: TextInputType.number,
                obscureText: _obscureConfirmPin,
                maxLength: 4,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPin = !_obscureConfirmPin);
                  },
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Register Account',
                isLoading: _isLoading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
