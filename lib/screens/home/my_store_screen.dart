import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyStoreScreen extends StatefulWidget {
  const MyStoreScreen({super.key});

  @override
  State<MyStoreScreen> createState() => _MyStoreScreenState();
}

class _MyStoreScreenState extends State<MyStoreScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('merchants').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading store data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Store not found'));
          }

          final merchant = snapshot.data!.data() as Map<String, dynamic>;
          final businessName = merchant['businessName'] ?? 'Unknown Business';
          final crNumber = merchant['crNumber'] ?? 'N/A';
          final branchNumber = merchant['branchNumber'] ?? '';
          final displayCr = branchNumber.isNotEmpty ? '$crNumber-$branchNumber' : crNumber;
          final contactName = merchant['contactName'] ?? 'N/A';
          final contactEmail = merchant['contactEmail'] ?? 'N/A';
          final phone = merchant['phone'] ?? 'N/A';
          final dateJoined = merchant['dateJoined'] ?? 'N/A';
          final imageUrl = merchant['imageUrl']?.toString() ?? '';

          final businessType = merchant['businessType'] ?? 'N/A';
          final category = merchant['category'] ?? 'N/A';
          final priceRange = merchant['priceRange'] ?? 'N/A';

          final address = merchant['address'] as Map<String, dynamic>?;
          final building = address?['building'] ?? 'N/A';
          final street = address?['street'] ?? 'N/A';
          final block = address?['block'] ?? 'N/A';
          final city = address?['city'] ?? 'N/A';
          final country = address?['country'] ?? 'Bahrain';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Profile
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.store, size: 48, color: Colors.grey),
                                )
                              : const Icon(Icons.store, size: 48, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(businessName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(contactEmail, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary Info
                _buildInfoCard(
                  context,
                  title: 'Primary Information',
                  items: [
                    _InfoItem(icon: Icons.work, label: 'Business Name', value: businessName),
                    _InfoItem(icon: Icons.tag, label: 'CR Number', value: displayCr),
                    _InfoItem(icon: Icons.person, label: 'Contact Person', value: contactName),
                    _InfoItem(icon: Icons.email, label: 'Contact Email', value: contactEmail),
                    _InfoItem(icon: Icons.phone, label: 'Mobile Number', value: phone),
                    _InfoItem(icon: Icons.calendar_today, label: 'Date Joined', value: dateJoined),
                  ],
                ),
                const SizedBox(height: 16),

                // Business Details
                _buildInfoCard(
                  context,
                  title: 'Business Details',
                  items: [
                    _InfoItem(icon: Icons.business, label: 'Merchant Type', value: businessType),
                    _InfoItem(icon: Icons.category, label: 'Category / Cuisine', value: category),
                    _InfoItem(icon: Icons.attach_money, label: 'Price Range', value: priceRange),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                _buildInfoCard(
                  context,
                  title: 'Address',
                  items: [
                    _InfoItem(icon: Icons.apartment, label: 'Building', value: building),
                    _InfoItem(icon: Icons.add_road, label: 'Street', value: street),
                    _InfoItem(icon: Icons.location_on, label: 'Block', value: block),
                    _InfoItem(icon: Icons.location_city, label: 'Area', value: city),
                    _InfoItem(icon: Icons.public, label: 'Country', value: country),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required List<_InfoItem> items}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 20, color: Colors.grey[500]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            const SizedBox(height: 2),
                            Text(item.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({required this.icon, required this.label, required this.value});
}
