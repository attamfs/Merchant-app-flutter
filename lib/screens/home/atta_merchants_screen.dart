import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class AttaMerchantsScreen extends StatefulWidget {
  AttaMerchantsScreen({super.key});

  @override
  State<AttaMerchantsScreen> createState() => _AttaMerchantsScreenState();
}

class _AttaMerchantsScreenState extends State<AttaMerchantsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Atta Merchants'.tr(context), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by merchant name or category',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('merchants').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading merchants'.tr(context)));
                }

                var merchants = snapshot.data?.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return data;
                }).toList() ?? [];

                // Filter for active and visible in merchant app
                merchants = merchants.where((m) {
                  return m['visibleInMerchantApp'] == true && m['status'] == 'active';
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  merchants = merchants.where((m) {
                    final name = (m['businessName'] ?? m['name'] ?? '').toString().toLowerCase();
                    final category = (m['category'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || category.contains(_searchQuery);
                  }).toList();
                }

                if (merchants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text('No Merchants Found'.tr(context), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: merchants.length,
                  itemBuilder: (context, index) {
                    final m = merchants[index];
                    return _buildMerchantCard(m);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant) {
    final name = merchant['businessName'] ?? merchant['name'] ?? 'Unknown Merchant';
    final category = merchant['category'] ?? 'Retail';
    final logoUrl = merchant['logoUrl']?.toString() ?? '';
    final address = merchant['address'] != null && merchant['address'] is Map 
        ? merchant['address']['city'] ?? merchant['address']['address'] ?? 'Unknown location'
        : 'Unknown location';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(Icons.store, color: Colors.grey),
                      )
                    : Icon(Icons.store, color: Colors.grey),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(category, style: TextStyle(fontSize: 12, color: Colors.indigo[800], fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address, 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
