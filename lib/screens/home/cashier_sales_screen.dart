import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class CashierSalesScreen extends StatefulWidget {
  final String? merchantId;

  CashierSalesScreen({
    super.key,
    this.merchantId,
  });

  @override
  State<CashierSalesScreen> createState() => _CashierSalesScreenState();
}

class _CashierSalesScreenState extends State<CashierSalesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in'.tr(context))));
    }

    final targetMerchantId = widget.merchantId ?? user.uid;
    Query streamQuery = _firestore
        .collection('merchants')
        .doc(targetMerchantId)
        .collection('shiftClosings')
        .orderBy('closingTime', descending: true);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Cashier Sales'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final shifts = snapshot.data?.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList() ?? [];

          if (shifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No Cashier Sales Found'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('There are no closed shift records yet.'.tr(context), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, index) {
              final shift = shifts[index];
              final closingTimeStr = shift['closingTime'] as String?;
              final closingDate = closingTimeStr != null ? DateTime.tryParse(closingTimeStr) : null;
              final formattedDate = closingDate != null ? DateFormat('MMM d, yyyy • h:mm a').format(closingDate) : 'Unknown Date';
              
              final cashierName = shift['cashierName'] ?? 'Unknown Cashier';
              final counterNumber = shift['counterNumber'];
              final totalDigitalSales = (shift['totalDigitalSales'] ?? 0).toDouble();
              final transactionCount = shift['transactionCount'] ?? 0;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cashierName, 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (counterNumber != null)
                                        Text('Counter: $counterNumber'.tr(context), style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Digital Sales'.tr(context), style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text('${totalDigitalSales.toStringAsFixed(3)} BHD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Transactions'.tr(context), style: TextStyle(color: Colors.grey, fontSize: 13)),
                              SizedBox(height: 4),
                              Text('$transactionCount'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
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
