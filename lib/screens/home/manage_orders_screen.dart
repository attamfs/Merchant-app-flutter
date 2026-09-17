import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/orders/manage_order_card.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class ManageOrdersScreen extends StatefulWidget {
  ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    if (user == null) return Scaffold(body: Center(child: Text('Not logged in'.tr(context))));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Manage Orders'.tr(context), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
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
                return Center(child: CircularProgressIndicator());
              }

              if (ordersSnapshot.hasError) {
                return Center(child: Text('Error loading orders: ${ordersSnapshot.error}'));
              }

              final orders = ordersSnapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('No orders found'.tr(context), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Incoming orders will appear here.'.tr(context), style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
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
