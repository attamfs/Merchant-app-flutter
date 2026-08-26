import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'merchant_checkout_screen.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
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
        title: const Text('Admin Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('paymentRequests')
            .where('merchantId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }

          final allRequests = snapshot.data?.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['id'] = d.id;
            return data;
          }).toList() ?? [];

          // Filter for admin requests (has tierName)
          final adminRequests = allRequests.where((req) => req['tierName'] != null).toList();

          adminRequests.sort((a, b) {
            DateTime parseDate(dynamic val) {
              if (val is Timestamp) return val.toDate();
              if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
              return DateTime.now();
            }
            final dateA = parseDate(a['createdAt']);
            final dateB = parseDate(b['createdAt']);
            return dateB.compareTo(dateA); // Descending
          });

          if (adminRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.security, size: 48, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Admin Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'You don\'t have any subscription or administrative payment requests at this time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminRequests.length,
            itemBuilder: (context, index) {
              final req = adminRequests[index];
              return _buildRequestCard(req);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final tierName = req['tierName']?.toString() ?? 'Unknown Plan';
    final amount = (req['amount'] ?? 0).toDouble();
    final status = req['status']?.toString() ?? 'pending';
    
    DateTime createdAt = DateTime.now();
    if (req['createdAt'] is Timestamp) {
      createdAt = (req['createdAt'] as Timestamp).toDate();
    } else if (req['createdAt'] is String) {
      createdAt = DateTime.tryParse(req['createdAt']) ?? DateTime.now();
    }

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'paid':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[100]!;
        statusIcon = Icons.check_circle;
        statusLabel = 'Paid';
        break;
      case 'cancelled':
        statusColor = Colors.grey[700]!;
        statusBgColor = Colors.grey[200]!;
        statusIcon = Icons.cancel;
        statusLabel = 'Cancelled';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[100]!;
        statusIcon = Icons.access_time_filled;
        statusLabel = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan: $tierName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Received: ${DateFormat('MMM d, yyyy • h:mm a').format(createdAt)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(amount.toStringAsFixed(3), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                        const SizedBox(width: 4),
                        const Text('BHD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MerchantCheckoutScreen(
                            tierName: tierName,
                            price: amount,
                            durationMonths: 1, // Doesn't matter for non-subscription
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
