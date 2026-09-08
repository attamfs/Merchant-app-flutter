import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/orders/manage_order_card.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manage Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch drivers for this merchant
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('merchantId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, driversSnapshot) {
          final drivers = driversSnapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>..['id'] = d.id).toList() ?? [];

          return StreamBuilder<QuerySnapshot>(
            // Fetch orders for this merchant
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('merchantId', isEqualTo: user!.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, ordersSnapshot) {
              if (ordersSnapshot.connectionState == ConnectionState.waiting && !ordersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ordersSnapshot.hasError) {
                return Center(child: Text('Error loading orders: ${ordersSnapshot.error}'));
              }

              final orders = ordersSnapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Incoming orders will appear here.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderDoc = orders[index];
                  final orderData = orderDoc.data() as Map<String, dynamic>;
                  return ManageOrderCard(
                    orderId: orderDoc.id,
                    orderData: orderData,
                    drivers: drivers,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
