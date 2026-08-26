import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Merchant Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('merchants').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile not found'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                final String businessName = data['businessName'] ?? 'Unknown Business';
                final String imageUrl = data['imageUrl'] ?? '';
                final String contactEmail = data['contactEmail'] ?? '';
                final String contactName = data['contactName'] ?? '';
                final String crNumber = data['crNumber'] ?? '';
                final String branchNumber = data['branchNumber']?.toString() ?? '';
                final String vatNumber = data['taxRegistrationNumber'] ?? '';
                final String phone = data['phone'] ?? '';
                final String dateJoined = data['dateJoined'] ?? '';
                final String businessType = data['businessType'] ?? '';
                final String category = data['category'] ?? '';
                final String priceRange = data['priceRange'] ?? '';
                final String deliveryModel = data['deliveryPricingModel'] ?? 'flat';
                final double deliveryPrice = (data['deliveryPrice'] ?? 0.0).toDouble();

                final address = data['address'] as Map<String, dynamic>? ?? {};

                final String fullCr = branchNumber.isNotEmpty ? '$crNumber-$branchNumber' : crNumber;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFF1EBB5E).withOpacity(0.1),
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? Text(businessName.isNotEmpty ? businessName[0].toUpperCase() : 'M', 
                                    style: const TextStyle(fontSize: 32, color: Color(0xFF1EBB5E), fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(contactEmail, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Primary Information
                      _buildSectionHeader('Primary Information'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.business_center, 'Business Name', businessName),
                        _buildInfoRow(Icons.numbers, 'CR Number', fullCr),
                        if (vatNumber.isNotEmpty)
                          _buildInfoRow(Icons.receipt_long, 'VAT Registration Number', vatNumber),
                        _buildInfoRow(Icons.person, 'Contact Person', contactName),
                        _buildInfoRow(Icons.email, 'Contact Email', contactEmail),
                        _buildInfoRow(Icons.phone, 'Mobile Number', phone),
                        _buildInfoRow(Icons.calendar_today, 'Date Joined', dateJoined),
                      ]),
                      const SizedBox(height: 24),

                      // Business Details
                      _buildSectionHeader('Business Details'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.store, 'Merchant Type', businessType),
                        _buildInfoRow(Icons.category, 'Category / Cuisine', category),
                        _buildInfoRow(Icons.attach_money, 'Price Range', priceRange),
                        if (deliveryModel == 'hybrid')
                          _buildInfoRow(Icons.delivery_dining, 'Delivery Model', 'Hybrid Dynamic (Zone + Distance)')
                        else
                          _buildInfoRow(Icons.delivery_dining, 'Delivery Price', '${deliveryPrice.toStringAsFixed(3)} BHD'),
                      ]),
                      const SizedBox(height: 24),

                      // Address
                      _buildSectionHeader('Address'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.home_work, 'Shop No.', address['flat']?.toString() ?? ''),
                        _buildInfoRow(Icons.apartment, 'Building', address['building']?.toString() ?? ''),
                        _buildInfoRow(Icons.add_road, 'Street', address['street']?.toString() ?? ''),
                        _buildInfoRow(Icons.map, 'Block', address['block']?.toString() ?? ''),
                        _buildInfoRow(Icons.location_city, 'Area', address['city']?.toString() ?? ''),
                        _buildInfoRow(Icons.public, 'Country', address['country']?.toString() ?? ''),
                      ]),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children.expand((widget) => [widget, const Divider(height: 1)]).toList()..removeLast(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
