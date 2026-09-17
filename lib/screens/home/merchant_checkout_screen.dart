import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_success_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class MerchantCheckoutScreen extends StatefulWidget {
  final String tierName;
  final double price;
  final int durationMonths;

  MerchantCheckoutScreen({
    super.key,
    required this.tierName,
    required this.price,
    required this.durationMonths,
  });

  @override
  State<MerchantCheckoutScreen> createState() => _MerchantCheckoutScreenState();
}

class _MerchantCheckoutScreenState extends State<MerchantCheckoutScreen> {
  bool _isProcessing = false;
  String? _merchantBusinessName;

  @override
  void initState() {
    super.initState();
    _fetchMerchantDetails();
  }

  Future<void> _fetchMerchantDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('merchants').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _merchantBusinessName = doc.data()?['businessName'] ?? 'Merchant';
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not logged in'.tr(context))));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      final transactionId = transactionRef.id;

      final payload = {
        'transactionId': transactionId,
        'payerBusinessName': _merchantBusinessName ?? 'Merchant',
        'paymentMethodsPayload': [
          {'method': 'Debit/Credit Card', 'amount': widget.price}
        ],
        'totalAmount': widget.price,
        'subtotal': widget.price,
        'purchaseType': 'subscription',
        'merchantId': 'gZDXuwyVWMf3NwXWcalOERZJX362', // ADMIN_RECIPIENT_ID (Supporting Technologies)
        'merchantBusinessName': 'Atta Technologies',
        'appliedAttaPoints': 0,
        'appliedMerchantPoints': 0,
        'appliedVouchers': [],
        'tierName': widget.tierName,
        'durationMonths': widget.durationMonths,
      };

      await transactionRef.set({
        'id': transactionId,
        'customerId': user.uid,
        'customerName': _merchantBusinessName ?? 'Merchant',
        'merchantId': 'gZDXuwyVWMf3NwXWcalOERZJX362',
        'merchantBusinessName': 'Atta Technologies',
        'totalAmount': widget.price,
        'status': 'Pending',
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'credit',
        'purchaseType': 'subscription',
        'payload': payload,
        '_allowedReadUIDs': [user.uid, 'gZDXuwyVWMf3NwXWcalOERZJX362'],
      });

      if (!mounted) return;

      // Navigate to PaymentSuccessScreen to simulate Gateway success and provision subscription
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(transactionId: transactionId),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'.tr(context))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Checkout'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Plan'.tr(context), style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(widget.tierName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration'.tr(context), style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text('${widget.durationMonths} Months', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to Pay'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('BHD ${widget.price.toStringAsFixed(3)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('Payment Method'.tr(context), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: Theme.of(context).primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Credit / Debit Card'.tr(context), style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Gateway Simulation'.tr(context), style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isProcessing
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Pay BHD ${widget.price.toStringAsFixed(3)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
