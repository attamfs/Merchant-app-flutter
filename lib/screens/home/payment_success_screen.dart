import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String transactionId;

  PaymentSuccessScreen({super.key, required this.transactionId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _transactionDetails;
  bool _hasProcessed = false;

  @override
  void initState() {
    super.initState();
    _finalizePayment();
  }

  Future<void> _finalizePayment() async {
    if (_hasProcessed) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = "User not logged in.";
        _isLoading = false;
      });
      return;
    }

    try {
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc(widget.transactionId);
      final transactionSnap = await transactionRef.get();

      if (!transactionSnap.exists) {
        throw Exception("Transaction details not found.");
      }

      final txData = transactionSnap.data()!;
      final payload = txData['payload'] as Map<String, dynamic>?;

      if (txData['status'] == 'Completed') {
        if (mounted) {
          setState(() {
            _transactionDetails = payload ?? txData;
            _isLoading = false;
            _hasProcessed = true;
          });
        }
        return;
      }

      if (payload == null) {
        throw Exception("Transaction payload is missing.");
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1. Mark Transaction as Completed
      batch.update(transactionRef, {
        'status': 'Completed',
      });

      // 2. Update Payer Profile
      final payerRef = FirebaseFirestore.instance.collection('merchants').doc(user.uid);
      
      if (payload['purchaseType'] == 'subscription') {
        final startDate = DateTime.now();
        final duration = (payload['durationMonths'] as num?)?.toInt() ?? 0;
        final expiryDate = DateTime(startDate.year, startDate.month + duration, startDate.day);
        
        batch.set(payerRef, {
          'activeSubscription': {
            'tierName': payload['tierName'],
            'startDate': startDate.toIso8601String(),
            'expiryDate': expiryDate.toIso8601String(),
            'status': 'active',
            'durationMonths': duration,
            'transactionId': widget.transactionId,
          },
          'tier': (payload['tierName']?.toString() ?? '').toLowerCase(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _transactionDetails = payload;
          _hasProcessed = true;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err.toString();
          _isLoading = false;
          _hasProcessed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finalizing your payment...'.tr(context), style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Payment Status'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        automaticallyImplyLeading: false, // Prevent going back to checkout
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: _error != null
              ? _buildErrorCard()
              : _buildSuccessCard(),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text('Payment Error'.tr(context), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
          SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => DashboardScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Go to Home'.tr(context), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    final amount = (_transactionDetails?['totalAmount'] ?? 0.0).toDouble();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 16),
          Text('Payment Successful!'.tr(context), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Your subscription has been upgraded.'.tr(context), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 32),
          _buildDetailRow('Amount Paid', 'BHD ${amount.toStringAsFixed(3)}'),
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildDetailRow('Transaction ID', widget.transactionId, isMono: true),
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _buildDetailRow('Date', DateFormat('PPp').format(DateTime.now())),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => DashboardScreen()),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Home Page'.tr(context), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
              fontSize: isMono ? 10 : null,
            ),
          ),
        ),
      ],
    );
  }
}
