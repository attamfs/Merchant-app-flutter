import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class MobileVerificationScreen extends StatefulWidget {
  const MobileVerificationScreen({super.key});

  @override
  State<MobileVerificationScreen> createState() => _MobileVerificationScreenState();
}

class _MobileVerificationScreenState extends State<MobileVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _selectedCountryCode = '+973';
  final List<String> _countryCodes = ['+973', '+966', '+974', '+965', '+968', '+971'];
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _testMode = false;
  String? _phoneErrorText;

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneErrorText = 'Please enter a mobile number';
      });
      return;
    }

    if (_selectedCountryCode == '+973' && phone.length != 8) {
      setState(() {
        _phoneErrorText = 'Bahrain numbers must be 8 digits.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Sent! (Use 123456 in test mode)')),
      );
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate verification
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      
      if (_testMode && otp != '123456') {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid test OTP. Use 123456.')),
        );
        return;
      }

      // Navigate to Set PIN screen
      Navigator.pushReplacementNamed(context, '/set-pin');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _otpSent ? Icons.check : Icons.smartphone,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _otpSent ? 'Enter OTP' : 'Mobile Verification',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  _otpSent 
                      ? 'Enter the 6-digit code sent to your mobile'
                      : 'Enter your mobile number to receive a verification code',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Test Mode Toggle (visible only before sending OTP)
                if (!_otpSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Switch(
                        value: _testMode,
                        onChanged: (val) {
                          setState(() {
                            _testMode = val;
                          });
                        },
                      ),
                      const Text('Test Mode'),
                    ],
                  ),
                
                if (_testMode && !_otpSent)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Test Mode Active. You can use any phone number and enter 123456 as the OTP.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                if (!_otpSent) ...[
                  // Phone Input Row
                  Row(
                    children: [
                      // Country Code Dropdown
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            isExpanded: true,
                            items: _countryCodes.map((code) {
                              return DropdownMenuItem(
                                value: code,
                                child: Text(code, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCountryCode = value!;
                                final phone = _phoneController.text;
                                if (phone.isNotEmpty) {
                                  if (_selectedCountryCode == '+973' && phone.length != 8) {
                                    _phoneErrorText = 'Bahrain numbers must be 8 digits.';
                                  } else {
                                    _phoneErrorText = null;
                                  }
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Phone Number Field
                      Expanded(
                        child: CustomTextField(
                          controller: _phoneController,
                          hintText: 'Mobile Number',
                          keyboardType: TextInputType.phone,
                          maxLength: _selectedCountryCode == '+973' ? 8 : 15,
                          errorText: _phoneErrorText,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _phoneErrorText = 'Please enter a mobile number';
                              });
                            } else if (_selectedCountryCode == '+973' && value.length != 8) {
                              setState(() {
                                _phoneErrorText = 'Bahrain numbers must be 8 digits.';
                              });
                            } else {
                              if (_phoneErrorText != null) {
                                setState(() {
                                  _phoneErrorText = null;
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Send OTP',
                    isLoading: _isLoading,
                    onPressed: _sendOtp,
                  ),
                ] else ...[
                  // OTP Input
                  CustomTextField(
                    controller: _otpController,
                    hintText: 'Enter 6-digit OTP',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Verify & Continue',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                  ),
                ],
                
                const SizedBox(height: 24),

                // Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Log In',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
