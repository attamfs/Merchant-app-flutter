import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'merchant_payment_screen.dart';
import '../../models/merchant_user.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class PaymentsScreen extends StatefulWidget {
  PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Make a Payment'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search for a merchant',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('merchants').orderBy('businessName').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading merchants'.tr(context)));
                }

                final allMerchants = snapshot.data?.docs ?? [];
                
                final filteredMerchants = allMerchants.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final businessName = (data['businessName'] ?? '').toString().toLowerCase();
                  return businessName.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredMerchants.isEmpty) {
                  return Center(child: Text('No merchants found.'.tr(context), style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: filteredMerchants.length,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final doc = filteredMerchants[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MerchantPaymentScreen(merchantId: doc.id),
                            ),
                          );
                        },
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 24,
                          backgroundImage: data['imageUrl'] != null ? NetworkImage(data['imageUrl']) : null,
                          child: data['imageUrl'] == null ? Icon(Icons.business, color: Colors.grey) : null,
                        ),
                        title: Text(
                          data['businessName'] ?? 'Unknown',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          data['category'] ?? 'Retail',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
