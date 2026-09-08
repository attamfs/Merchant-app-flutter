import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final List<Map<String, dynamic>> drivers;

  const ManageOrderCard({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.drivers,
  });

  Future<void> _updateOrderStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status changed to $newStatus.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  Future<void> _assignDriver(BuildContext context, String driverId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'driverId': driverId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver has been assigned.')));
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
      }
    }
  }

  void _showAssignDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Driver'),
          content: SizedBox(
            width: double.maxFinite,
            child: drivers.isEmpty
                ? const Text('No drivers registered yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text(driver['name'] ?? 'Unknown Driver'),
                        onTap: () => _assignDriver(context, driver['id']),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    switch (status) {
      case 'Pending': color = Colors.amber; break;
      case 'Preparing': color = Colors.orange; break;
      case 'Ready for Delivery': color = Colors.blue; break;
      case 'Out for Delivery': color = Colors.indigo; break;
      case 'Delivered': color = Colors.green; break;
      case 'Cancelled': color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = orderData['customerName'] ?? 'Unknown Customer';
    
    String dateStr = '';
    if (orderData['createdAt'] != null) {
      DateTime dt;
      if (orderData['createdAt'] is Timestamp) {
        dt = (orderData['createdAt'] as Timestamp).toDate();
      } else if (orderData['createdAt'] is String) {
        dt = DateTime.tryParse(orderData['createdAt']) ?? DateTime.now();
      } else {
        dt = DateTime.now();
      }
      dateStr = DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt);
    }
    
    final status = orderData['status'] ?? 'Pending';
    final items = (orderData['items'] as List<dynamic>?) ?? [];
    final totalAmount = (orderData['totalAmount'] ?? orderData['total'] ?? 0.0).toDouble();
    
    final assignedDriverId = orderData['driverId'];
    final assignedDriver = drivers.where((d) => d['id'] == assignedDriverId).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Date, Status, Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (newStatus) => _updateOrderStatus(context, newStatus),
                  itemBuilder: (context) => [
                    const PopupMenuItem(enabled: false, child: Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    const PopupMenuItem(value: 'Preparing', child: Text('Preparing')),
                    const PopupMenuItem(value: 'Ready for Delivery', child: Text('Ready for Delivery')),
                    const PopupMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                    const PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'Cancelled', child: Text('Cancel Order', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            
            // Order Items
            const Text('ORDER ITEMS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ...items.map((item) {
              final qty = item['quantity'] ?? 1;
              final name = item['name'] ?? 'Item';
              final instructions = item['specialInstructions'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: '${qty}x $name'),
                      if (instructions != null && instructions.toString().isNotEmpty)
                        TextSpan(text: ' ($instructions)', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            
            // Footer: Driver and Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (status == 'Pending' || status == 'Preparing')
                      const Text('Waiting for \'Ready\'', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else if (assignedDriver != null)
                      Text(assignedDriver['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                    else
                      OutlinedButton(
                        onPressed: () => _showAssignDriverDialog(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        child: const Text('Assign Driver', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(
                      'BHD ${totalAmount.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
