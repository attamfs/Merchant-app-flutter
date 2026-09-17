import '../../providers/translation_extension.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class MerchantRegistrationScreen extends StatefulWidget {
  const MerchantRegistrationScreen({super.key});

  @override
  State<MerchantRegistrationScreen> createState() =>
      _MerchantRegistrationScreenState();
}

class _MerchantRegistrationScreenState
    extends State<MerchantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameCtrl = TextEditingController();
  final _crNumberCtrl = TextEditingController();
  final _branchNumberCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  final _shopNoCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();

  String _selectedCountryCode = '+973';
  String _selectedCountry = 'Bahrain';
  bool _isLoading = false;

  final List<String> _countryCodes = [
    '+973',
    '+966',
    '+974',
    '+965',
    '+968',
    '+971',
  ];
  final List<String> _countries = [
    'Bahrain',
    'Saudi Arabia',
    'Qatar',
    'Kuwait',
    'Oman',
    'UAE',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from mobile verification screen (called after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['phone'] != null) {
          _contactNumberCtrl.text = args['phone'] as String;
        }
        if (args['countryCode'] != null) {
          setState(() => _selectedCountryCode = args['countryCode'] as String);
        }
      }
    });
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _crNumberCtrl.dispose();
    _branchNumberCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactNumberCtrl.dispose();
    _shopNoCtrl.dispose();
    _buildingCtrl.dispose();
    _streetCtrl.dispose();
    _blockCtrl.dispose();
    _areaCtrl.dispose();
    _mapLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final crNumberWithBranch = _branchNumberCtrl.text.isNotEmpty
          ? '${_crNumberCtrl.text.trim()}-${_branchNumberCtrl.text.trim()}'
          : _crNumberCtrl.text.trim();

      final address = {
        'building': _buildingCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'block': _blockCtrl.text.trim(),
        'city': _areaCtrl.text.trim(),
        'country': _selectedCountry,
      };

      if (_shopNoCtrl.text.isNotEmpty) {
        address['flat'] = _shopNoCtrl.text.trim();
      }
      if (_mapLinkCtrl.text.isNotEmpty) {
        address['googleMapLink'] = _mapLinkCtrl.text.trim();
      }

      final merchantData = {
        'businessName': _businessNameCtrl.text.trim(),
        'crNumber': crNumberWithBranch,
        'contactName': _contactNameCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'phone': '$_selectedCountryCode${_contactNumberCtrl.text.trim()}',
        'address': address,
        'status': 'Active',
        'loyaltyPoints': 0,
        'dateJoined': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'businessType': 'N/A',
        'category': 'N/A',
        'priceRange': 'N/A',
      };

      final authService = AuthService();
      final userCredential = await authService.registerMerchant(
        merchantData: merchantData,
        crNumberWithBranch: crNumberWithBranch,
        contactName: _contactNameCtrl.text.trim(),
      );

      if (mounted && userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful. Please set your PIN.'.tr(context)),
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/set-pin',
          arguments: {
            'userId': userCredential.user!.uid,
            'crNumber': crNumberWithBranch,
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'An unexpected error occurred.';
      if (e.code == 'email-already-in-use') {
        msg = 'This CR Number is already registered.';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _requiredLabel(String label) {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: '* ',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
          TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant Registration'.tr(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Fill out the form below to create your merchant account.'.tr(context),
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Primary Information'),

                      TextFormField(
                        controller: _businessNameCtrl,
                        decoration: InputDecoration(
                          label: _requiredLabel('Merchant Name'),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _crNumberCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('CR Number'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _branchNumberCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Branch Number'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _contactNameCtrl,
                        decoration: InputDecoration(
                          label: _requiredLabel('Contact Person'),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _contactEmailCtrl,
                        decoration: InputDecoration(
                          label: _requiredLabel('Contact Email'),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v!.isEmpty || !v.contains('@'))
                            ? 'Valid email required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes
                                .map(
                                  (code) => DropdownMenuItem(
                                    value: code,
                                    child: Text('${{'+973':'🇧🇭','+966':'🇸🇦','+974':'🇶🇦','+965':'🇰🇼','+968':'🇴🇲','+971':'🇦🇪'}[code] ?? ""} \u200E$code', textDirection: ui.TextDirection.ltr),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCountryCode = v!),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _contactNumberCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Contact Number'),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSectionTitle('Address'),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shopNoCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Shop No.'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _buildingCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Building'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _streetCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Street'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _blockCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Block'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaCtrl,
                              decoration: InputDecoration(
                                label: _requiredLabel('Area'),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCountry,
                              decoration: InputDecoration(
                                label: _requiredLabel('Country'),
                              ),
                              items: _countries
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCountry = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _mapLinkCtrl,
                        decoration: InputDecoration(
                          labelText: 'Google Map Link (Optional)'.tr(context),
                        ),
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        child: Text(
                          'Submit Application'.tr(context),
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
