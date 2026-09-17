import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class MerchantPaymentScreen extends StatefulWidget {
  final String merchantId;
  final String? cashierId;
  final String? counterNumber;

  MerchantPaymentScreen({super.key, required this.merchantId, this.cashierId, this.counterNumber});

  @override
  State<MerchantPaymentScreen> createState() => _MerchantPaymentScreenState();
}

class _MerchantPaymentScreenState extends State<MerchantPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic>? _merchantData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchant();
  }

  Future<void> _loadMerchant() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('merchants').doc(widget.merchantId).get();
      if (doc.exists) {
        setState(() {
          _merchantData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _proceedToPay() {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount greater than 0.'.tr(context))),
      );
      return;
    }
    
    // In the real app, this would route to a checkout screen or initiate the transaction.
    // We will show a placeholder success message for now, mimicking standard payment flow.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Proceeding to pay BHD ${amount.toStringAsFixed(3)} to ${_merchantData?['businessName'] ?? 'Unknown'}')),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_merchantData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Merchant not found'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Go Back'.tr(context))),
            ],
          ),
        ),
      );
    }

    final businessName = _merchantData!['businessName'] ?? 'Unknown';
    final imageUrl = _merchantData!['imageUrl'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pay $businessName'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null ? Icon(Icons.business, size: 48, color: Colors.grey) : null,
            ),
            SizedBox(height: 16),
            Text(
              businessName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0.000',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  Text('BHD',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: (double.tryParse(_amountController.text) ?? 0) > 0 ? _proceedToPay : null,
                child: Text('Proceed to Pay'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
