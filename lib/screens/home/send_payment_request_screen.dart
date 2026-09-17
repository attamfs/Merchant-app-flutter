import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class SendPaymentRequestScreen extends StatefulWidget {
  final String merchantId;
  final bool isCashier;
  final String? cashierId;
  final String? counterNumber;
  final String targetId;
  final String targetType; // 'customer' or 'merchant'

  SendPaymentRequestScreen({
    super.key,
    required this.merchantId,
    required this.targetId,
    required this.targetType,
    this.isCashier = false,
    this.cashierId,
    this.counterNumber,
  });

  @override
  State<SendPaymentRequestScreen> createState() => _SendPaymentRequestScreenState();
}

class _SendPaymentRequestScreenState extends State<SendPaymentRequestScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _cashPaymentAllowed = false;

  Map<String, dynamic>? _targetProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchTargetProfile();
  }

  Future<void> _fetchTargetProfile() async {
    try {
      final collectionName = widget.targetType == 'merchant' ? 'merchants' : 'users';
      final doc = await FirebaseFirestore.instance.collection(collectionName).doc(widget.targetId).get();
      if (doc.exists) {
        setState(() {
          _targetProfile = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount greater than 0'.tr(context))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final requestData = <String, dynamic>{
        'merchantId': widget.merchantId,
        'amount': amount,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
        'notes': _notesController.text.trim(),
        'cashPaymentAllowed': _cashPaymentAllowed,
        '_allowedReadUIDs': [widget.merchantId, widget.targetId],
        'customerId': widget.targetId,
      };

      if (widget.isCashier && widget.cashierId != null) {
        requestData['cashierId'] = widget.cashierId;
        requestData['counterNumber'] = widget.counterNumber;
      }
      
      // Fetch merchant name for notifications and display
      String merchantName = 'a merchant';
      final merchantDoc = await FirebaseFirestore.instance.collection('merchants').doc(widget.merchantId).get();
      if (merchantDoc.exists) {
        merchantName = merchantDoc.data()?['businessName'] ?? merchantDoc.data()?['name'] ?? merchantName;
        requestData['merchantName'] = merchantName;
      }

      await FirebaseFirestore.instance.collection('paymentRequests').add(requestData);

      // Send notification
      final collectionPath = widget.targetType == 'merchant' 
          ? 'merchants/${widget.targetId}/notifications' 
          : 'users/${widget.targetId}/notifications';
          
      await FirebaseFirestore.instance.collection(collectionPath).add({
        'userId': widget.targetId,
        'type': 'paymentRequest',
        'title': 'Payment Request',
        'message': 'You have a new payment request from $merchantName for ${amount.toStringAsFixed(3)} BHD.',
        'amount': amount,
        'merchantName': merchantName,
        'read': false,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context); // Go back to search screen
        Navigator.pop(context); // Go back to payment requests screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment request sent successfully!'.tr(context))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.targetType == 'merchant' 
        ? (_targetProfile?['businessName'] ?? _targetProfile?['name'] ?? 'Unknown Merchant')
        : (_targetProfile?['name'] ?? 'Unknown User');
        
    final targetImageUrl = _targetProfile?['imageUrl'] ?? _targetProfile?['avatarUrl'] ?? _targetProfile?['photoURL'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Send Payment Request'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoadingProfile 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Target Profile Info
                  if (targetImageUrl != null && targetImageUrl.toString().isNotEmpty)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(targetImageUrl.toString()),
                    )
                  else
                    CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    targetName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Amount Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: '0.000',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Text('BHD',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Transaction Details
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Transaction Details'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Transaction details (required)',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Cash Payment Allowed
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      value: _cashPaymentAllowed,
                      onChanged: (val) {
                        setState(() {
                          _cashPaymentAllowed = val ?? false;
                        });
                      },
                      title: Text('Cash Payment Allowed?'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('Customer will be able to pay in cash.'.tr(context), style: TextStyle(fontSize: 12, color: Colors.grey)),
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  
                  SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1EBB5E), // Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _createRequest,
                      child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Send Request'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
