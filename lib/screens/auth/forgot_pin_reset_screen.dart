import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPinResetScreen extends StatefulWidget {
  const ForgotPinResetScreen({super.key});

  @override
  State<ForgotPinResetScreen> createState() => _ForgotPinResetScreenState();
}

class _ForgotPinResetScreenState extends State<ForgotPinResetScreen> {
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  bool _isLoading = false;

  void _resetPin() {
    final pin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Connect to backend to reset PIN
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN Reset Successful! Please log in.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a new 4-digit PIN',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This PIN will be used to log in to your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),

              const Text('New PIN', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _newPinController,
                hintText: 'Enter 4-digit PIN',
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 4,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePin = !_obscurePin;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              const Text('Confirm New PIN', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPin = !_obscureConfirmPin;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Reset PIN',
                isLoading: _isLoading,
                onPressed: _resetPin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }
}
