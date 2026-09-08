import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/field_label.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _crNumberCtrl = TextEditingController();
  final TextEditingController _branchNumberCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final cr = _crNumberCtrl.text.trim();
      final branch = _branchNumberCtrl.text.trim();
      final crNumberWithBranch = branch.isNotEmpty ? '$cr-$branch' : cr;
      final pin = _pinCtrl.text.trim();

      final email = '$crNumberWithBranch@dualverse.app';
      final password = '$crNumberWithBranch-$pin';

      // Capture current user to re-auth later if needed, but Firebase Auth 
      // createUserWithEmailAndPassword will sign the new user in automatically
      // which is problematic for an admin creating a user. 
      // In Flutter, standard FirebaseAuth signs you in. We will use it for now, 
      // but note that the admin will be logged out and logged in as the new merchant.
      // A common workaround is a secondary FirebaseApp, but we'll stick to standard for MVP.
      
      final currentApp = FirebaseAuth.instance.app;
      // We will try to create without secondary app, but warn that it logs them in
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      final user = userCredential.user;

      if (user != null) {
        final merchantData = {
          'id': user.uid,
          'businessName': _businessNameCtrl.text.trim(),
          'crNumber': crNumberWithBranch,
          'branchNumber': branch,
          'pin': pin,
          'status': 'Active',
          'loyaltyPoints': 0,
          'dateJoined': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'businessType': 'N/A',
          'category': 'N/A',
          'priceRange': 'N/A',
          'contactName': 'N/A',
          'contactEmail': 'N/A',
          'phone': 'N/A',
          'address': {
              'building': 'N/A',
              'street': 'N/A',
              'block': 'N/A',
              'city': 'N/A',
              'country': 'Bahrain',
          }
        };

        final batch = _firestore.batch();
        
        batch.set(_firestore.collection('merchants').doc(user.uid), merchantData);
        batch.set(_firestore.collection('roles_merchants').doc(user.uid), {
          'merchantId': user.uid,
          'role': 'merchant',
          'crNumber': crNumberWithBranch
        });

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${_businessNameCtrl.text} created successfully!'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context); // Go back
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Admin: Create Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield, size: 48, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16),
              const Text('Register a new merchant account directly.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _businessNameCtrl,
                decoration: InputDecoration(
                  label: const FieldLabel(text: 'Business Name'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _crNumberCtrl,
                      decoration: InputDecoration(
                        label: const FieldLabel(text: 'CR Number'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _branchNumberCtrl,
                      decoration: InputDecoration(
                        label: const FieldLabel(text: 'Branch Number'),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  label: const FieldLabel(text: '4-Digit PIN'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.length != 4 ? 'Requires 4 digits' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
