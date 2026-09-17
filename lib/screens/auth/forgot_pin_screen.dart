import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class ForgotPinScreen extends StatefulWidget {
  ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _selectedCountryCode = '+973';
  final List<String> _countryCodes = ['+973', '+966', '+974', '+965', '+968', '+971'];
  
  bool _isLoading = false;
  bool _otpSent = false;
  int _timeLeft = 180;
  bool _timerActive = false;
  String? _phoneErrorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _phoneErrorText = 'Please enter a valid mobile number';
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
      _phoneErrorText = null;
      _isLoading = true;
    });

    try {
      final cleanCountryCode = _selectedCountryCode.replaceAll('+', '');
      final identifier = '$cleanCountryCode$phone';
      
      final methods1 = await FirebaseAuth.instance.fetchSignInMethodsForEmail('$identifier@customer.app');
      final methods2 = await FirebaseAuth.instance.fetchSignInMethodsForEmail('$identifier@dualverse.app');

      if (methods1.isEmpty && methods2.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Not Registered'.tr(context)),
            content: Text('This mobile number is not registered in our system.'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/mobile_verification');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Register'.tr(context)),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking registration: $e');
    }

    // TODO: Implement actual OTP sending logic (e.g. Firebase or custom API)
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
          _timeLeft = 180;
          _timerActive = true;
        });
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code sent to $_selectedCountryCode $phone'.trRead(context))),
        );
      }
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timerActive = false;
        }
      });
      return _timerActive;
    });
  }

  void _verifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a 6-digit OTP'.trRead(context))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual OTP verification logic
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Identity verified. Please reset your PIN.'.trRead(context))),
        );
        Navigator.pushReplacementNamed(context, '/forgot-pin/reset');
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_otpSent) {
              setState(() {
                _otpSent = false;
                _timerActive = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                SizedBox(height: 24),
                
                Text(
                  _otpSent ? 'Verify OTP' : 'Forgot PIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                Text(
                  _otpSent 
                      ? 'Enter the code sent to your mobile'
                      : 'Enter your mobile to receive an OTP',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                if (!_otpSent) ...[
                  Row(
                    children: [
                      Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            isExpanded: true,
                            items: _countryCodes.map((code) {
                              return DropdownMenuItem(
                                value: code,
                                child: Text('${{'+973':'🇧🇭','+966':'🇸🇦','+974':'🇶🇦','+965':'🇰🇼','+968':'🇴🇲','+971':'🇦🇪'}[code] ?? ""} \u200E$code', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCountryCode = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
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
                                _phoneErrorText = 'Please enter a valid mobile number';
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
                  SizedBox(height: 24),
                  CustomButton(
                    text: 'Send OTP',
                    isLoading: _isLoading,
                    onPressed: _sendOtp,
                  ),
                ] else ...[
                  CustomTextField(
                    controller: _otpController,
                    hintText: 'Enter 6-digit OTP',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_timeLeft > 0) ...[
                        Icon(Icons.timer, size: 16),
                        SizedBox(width: 4),
                        Text(
                          _formatTime(_timeLeft),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          child: Text('Resend OTP'.tr(context)),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  CustomButton(
                    text: 'Verify',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
