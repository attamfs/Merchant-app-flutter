import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class TransactionsScreen extends StatefulWidget {
  final bool isCashier;
  final String? merchantId;

  TransactionsScreen({
    super.key,
    this.isCashier = false,
    this.merchantId,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for user profiles
  final Map<String, Map<String, dynamic>> _userCache = {};

  DateTime? _parseDate(Map<String, dynamic> data) {
    if (data['timestamp'] is Timestamp) return (data['timestamp'] as Timestamp).toDate();
    if (data['date'] is Timestamp) return (data['date'] as Timestamp).toDate();
    if (data['createdAt'] is Timestamp) return (data['createdAt'] as Timestamp).toDate();
    
    if (data['timestamp'] is String) return DateTime.tryParse(data['timestamp']);
    if (data['date'] is String) return DateTime.tryParse(data['date']);
    if (data['createdAt'] is String) return DateTime.tryParse(data['createdAt']);
    
    return null;
  }

  void _showTransactionDetails(Map<String, dynamic> data, String id, Map<String, dynamic> userProfile) {
    final amount = (data['totalAmount'] ?? 0).toDouble();
    final date = data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate() 
        : (DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now());
    
    final payload = data['payload'] ?? {};
    final subtotal = (payload['subtotal'] ?? data['totalAmount'] ?? 0.0).toDouble();
    final taxAmount = (payload['taxAmount'] ?? data['taxAmount'] ?? 0.0).toDouble();
    final taxRate = (payload['taxRate'] ?? data['taxRate'] ?? 0.0).toDouble();
    final cashback = (data['cashbackAmountBHD'] ?? 0.0).toDouble();
    final loyaltyPoints = (data['cashbackToUser'] ?? 0.0).toDouble();
    
    final items = (payload['cartItems'] as List<dynamic>?) ?? (data['items'] as List<dynamic>?) ?? [];
    
    // Determine payment method
    String paymentMethod = 'Cash';
    List<dynamic> paymentMethods = [];
    if (payload['paymentMethodsPayload'] != null) {
      paymentMethods = payload['paymentMethodsPayload'];
    } else if (data['paymentMethods'] != null) {
      paymentMethods = data['paymentMethods'];
    }
    if (paymentMethods.isNotEmpty) {
      paymentMethod = paymentMethods.map((m) => m['method'] ?? 'Unknown').join(', ');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Transaction Details'.tr(context), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 1.5),
                          ),
                          child: Icon(Icons.close, size: 16, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Customer Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile['name']?.toString() ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy hh:mm a').format(date),
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Text('ID: ${id.substring(0, Math.min(20, id.length))}...',
                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                                SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('ID Copied'.tr(context)), duration: Duration(seconds: 1)),
                                    );
                                  },
                                  child: Icon(Icons.copy, size: 12, color: Colors.grey),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      if (userProfile['imageUrl'] != null && userProfile['imageUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            userProfile['imageUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                          ),
                        )
                      else
                        const _AvatarPlaceholder(),
                    ],
                  ),
                  
                  if (items.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text('ITEMS'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 8),
                    ...items.map((item) {
                      final name = item['name']?.toString() ?? 'Item';
                      final qty = item['quantity'] ?? 1;
                      final price = (item['price'] ?? 0.0).toDouble();
                      final rawImg = item['imageUrl']?.toString() ?? '';
                      final img = rawImg.replaceAll('studio-3536520071-24fe5', 'atta-studio-develop');
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: img.isNotEmpty 
                                ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.fastfood, size: 16, color: Colors.grey))
                                : Icon(Icons.fastfood, size: 16, color: Colors.grey),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${qty}x @ BHD ${price.toStringAsFixed(3)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('BHD ${(price * qty).toStringAsFixed(3)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  
                  Divider(height: 32),
                  
                  _buildSummaryRow('Subtotal', 'BHD ${subtotal.toStringAsFixed(3)}'),
                  SizedBox(height: 8),
                  if (taxAmount > 0)
                    _buildSummaryRow('VAT (${taxRate.toStringAsFixed(0)}%)', 'BHD ${taxAmount.toStringAsFixed(3)}'),
                  SizedBox(height: 12),
                  _buildSummaryRow('Total Amount', 'BHD ${amount.toStringAsFixed(3)}', isBold: true),
                  
                  Divider(height: 32),
                  
                  Text('PAYMENT METHOD'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 8),
                  _buildSummaryRow(paymentMethod, 'BHD ${amount.toStringAsFixed(3)}'),
                  
                  if (cashback > 0 || loyaltyPoints > 0) ...[
                    Divider(height: 32),
                    Text('REWARDS GRANTED'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 8),
                    if (cashback > 0)
                      _buildSummaryRow('Cashback', 'BHD ${cashback.toStringAsFixed(3)}', color: Colors.blue),
                    if (loyaltyPoints > 0)
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: _buildSummaryRow('Loyalty Points', '${loyaltyPoints.toStringAsFixed(0)} Pts', color: Colors.green),
                      ),
                  ],
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: color ?? (isBold ? Colors.black : Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in'.tr(context))));
    }

    final targetMerchantId = widget.isCashier ? (widget.merchantId ?? user.uid) : user.uid;
    Query streamQuery = _firestore
        .collection('transactions')
        .where('merchantId', isEqualTo: targetMerchantId);
        
    if (widget.isCashier) {
      streamQuery = streamQuery.where('cashierId', isEqualTo: user.uid);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Transactions'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: streamQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading transactions: ${snapshot.error}'));
          }

          final transactions = snapshot.data?.docs.toList() ?? [];
          
          transactions.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = _parseDate(aData) ?? DateTime.now();
            final bDate = _parseDate(bData) ?? DateTime.now();
            return bDate.compareTo(aDate);
          });

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No Transactions Yet'.tr(context), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Your payment history will appear here.'.tr(context), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = transactions[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final amount = (data['totalAmount'] ?? 0).toDouble();
              final date = _parseDate(data) ?? DateTime.now();
                  
              final customerId = data['customerId']?.toString() ?? '';
              
              // Resolve User Profile
              Map<String, dynamic> userProfile = {
                'name': data['customerName'] ?? 'Unknown',
                'imageUrl': null,
              };
              
              if (customerId.isNotEmpty) {
                if (_userCache.containsKey(customerId)) {
                  userProfile = _userCache[customerId]!;
                } else {
                  // Fire off request
                  _firestore.collection('users').doc(customerId).get().then((userDoc) {
                    if (userDoc.exists && mounted) {
                      final uData = userDoc.data();
                      setState(() {
                        _userCache[customerId] = {
                          'name': uData?['name']?.toString() ?? userProfile['name'],
                          'imageUrl': (uData?['imageUrl'] ?? uData?['avatarUrl'] ?? uData?['photoURL'])?.toString(),
                        };
                      });
                    } else if (mounted) {
                      _firestore.collection('merchants').doc(customerId).get().then((merchantDoc) {
                        if (merchantDoc.exists && mounted) {
                          final mData = merchantDoc.data();
                          setState(() {
                            _userCache[customerId] = {
                              'name': mData?['businessName']?.toString() ?? mData?['name']?.toString() ?? userProfile['name'],
                              'imageUrl': (mData?['imageUrl'] ?? mData?['avatarUrl'] ?? mData?['photoURL'])?.toString(),
                            };
                          });
                        }
                      });
                    }
                  });
                }
              }

              final payload = data['payload'] ?? {};
              final taxAmount = (payload['taxAmount'] ?? data['taxAmount'] ?? 0.0).toDouble();
              final taxRate = (payload['taxRate'] ?? data['taxRate'] ?? 0.0).toDouble();
              final cashback = (data['cashbackAmountBHD'] ?? 0.0).toDouble();
              
              return InkWell(
                onTap: () => _showTransactionDetails(data, doc.id, userProfile),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userProfile['imageUrl'] != null && userProfile['imageUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            userProfile['imageUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                          ),
                        )
                      else
                        const _AvatarPlaceholder(),
                        
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile['name']?.toString() ?? 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Text('+ '.tr(context), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${amount.toStringAsFixed(3)} ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('BHD', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (taxAmount > 0) ...[
                              SizedBox(height: 4),
                              Text('Includes VAT (${taxRate.toStringAsFixed(0)}%): BHD ${taxAmount.toStringAsFixed(3)}',
                                style: TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            ],
                            if (cashback > 0) ...[
                              SizedBox(height: 4),
                              Text('Cashback: ${cashback.toStringAsFixed(3)} BHD',
                                style: TextStyle(color: Color(0xFF1EBB5E), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                            SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy, hh:mm a').format(date),
                              style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Text('ID: ${doc.id.substring(0, 16)}...',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 9),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.copy, size: 10, color: Colors.grey[400])
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: Colors.grey, size: 24),
    );
  }
}
