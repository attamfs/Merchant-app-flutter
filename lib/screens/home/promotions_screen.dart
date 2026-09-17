import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class PromotionsScreen extends StatefulWidget {
  PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
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
        title: Text('My Promotions'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('merchants')
            .doc(user.uid)
            .collection('promotions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading promotions'.tr(context)));
          }

          final promotions = snapshot.data?.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList() ?? [];

          // Client-side sort by createdAt descending
          promotions.sort((a, b) {
            DateTime parseDate(dynamic val) {
              if (val is Timestamp) return val.toDate();
              if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
              return DateTime.now();
            }
            final dateA = parseDate(a['createdAt']);
            final dateB = parseDate(b['createdAt']);
            return dateB.compareTo(dateA);
          });

          if (promotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No Promotions Found'.tr(context), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('You have not created any promotions yet.'.tr(context), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promotion = promotions[index];
              return _buildPromotionCard(promotion);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final title = promotion['title']?.toString() ?? 'Unknown Promotion';
    final description = promotion['description']?.toString() ?? '';
    final imageUrl = promotion['imageUrl']?.toString() ?? '';
    final isActive = promotion['isActive'] == true;
    
    DateTime createdAt = DateTime.now();
    if (promotion['createdAt'] is Timestamp) {
      createdAt = (promotion['createdAt'] as Timestamp).toDate();
    } else if (promotion['createdAt'] is String) {
      createdAt = DateTime.tryParse(promotion['createdAt']) ?? DateTime.now();
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
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.card_giftcard, color: Colors.grey),
                      )
                    : Icon(Icons.card_giftcard, color: Colors.grey),
              ),
            ),
            SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green[800] : Colors.grey[600],
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  _buildDetailRow('Created On:', DateFormat('MMM d, yyyy').format(createdAt)),
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
