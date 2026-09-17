import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class VouchersScreen extends StatefulWidget {
  VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in'.tr(context))));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('My Vouchers'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('merchants')
            .doc(user.uid)
            .collection('vouchers')
            // Note: If you don't have an index for createdAt desc, this might fail initially. 
            // In that case, remove orderBy and sort client-side. Let's try client-side sorting for safety.
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading vouchers'.tr(context)));
          }

          final vouchers = snapshot.data?.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList() ?? [];

          // Client-side sort by createdAt descending
          vouchers.sort((a, b) {
            DateTime parseDate(dynamic val) {
              if (val is Timestamp) return val.toDate();
              if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
              return DateTime.now();
            }
            final dateA = parseDate(a['createdAt']);
            final dateB = parseDate(b['createdAt']);
            return dateB.compareTo(dateA); // Descending
          });

          if (vouchers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No Vouchers Found'.tr(context), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('You have not created any vouchers yet.'.tr(context), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final voucher = vouchers[index];
              return _buildVoucherCard(voucher);
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final name = voucher['name']?.toString() ?? 'Unknown Voucher';
    final value = (voucher['value'] ?? 0).toDouble();
    final quantity = voucher['quantity'] ?? 0;
    final imageUrl = voucher['imageUrl']?.toString() ?? '';
    final durationDays = voucher['durationDays'] ?? 0;
    
    DateTime createdAt = DateTime.now();
    if (voucher['createdAt'] is Timestamp) {
      createdAt = (voucher['createdAt'] as Timestamp).toDate();
    } else if (voucher['createdAt'] is String) {
      createdAt = DateTime.tryParse(voucher['createdAt']) ?? DateTime.now();
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey),
                      )
                    : Icon(Icons.image, color: Colors.grey),
              ),
            ),
            SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Value: ${value.toStringAsFixed(3)} BHD', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  SizedBox(height: 12),
                  _buildDetailRow('Quantity:', quantity.toString()),
                  SizedBox(height: 4),
                  _buildDetailRow('Created On:', DateFormat('MMM d, yyyy').format(createdAt)),
                  SizedBox(height: 4),
                  _buildDetailRow('Validity:', 'Valid for $durationDays days after purchase'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        SizedBox(width: 4),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 12))),
      ],
    );
  }
}
