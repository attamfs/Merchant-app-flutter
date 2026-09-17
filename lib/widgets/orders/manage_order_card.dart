import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class ManageOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final List<Map<String, dynamic>> drivers;

  ManageOrderCard({
    super.key,
    required this.orderId,
    required this.orderData,
    required this.drivers,
  });

  Future<void> _updateOrderStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status changed to $newStatus.'.tr(context))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e'.tr(context))));
      }
    }
  }

  Future<void> _assignDriver(BuildContext context, String driverId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'driverId': driverId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Driver has been assigned.'.tr(context))));
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e'.tr(context))));
      }
    }
  }

  void _showAssignDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Driver'.tr(context)),
          content: SizedBox(
            width: double.maxFinite,
            child: drivers.isEmpty
                ? Text('No drivers registered yet.'.tr(context), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return ListTile(
                        leading: Icon(Icons.local_shipping),
                        title: Text(driver['name'] ?? 'Unknown Driver'),
                        onTap: () => _assignDriver(context, driver['id']),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr(context)),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
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
                      Text(customerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 2),
                      Text("${'Order'.tr(context)} #$orderId", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (newStatus) => _updateOrderStatus(context, newStatus),
                  itemBuilder: (context) => [
                    PopupMenuItem(enabled: false, child: Text('Change Status'.tr(context), style: TextStyle(fontWeight: FontWeight.bold))),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'Pending', child: Text('Pending'.tr(context))),
                    PopupMenuItem(value: 'Preparing', child: Text('Preparing'.tr(context))),
                    PopupMenuItem(value: 'Ready for Delivery', child: Text('Ready for Delivery'.tr(context))),
                    PopupMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery'.tr(context))),
                    PopupMenuItem(value: 'Delivered', child: Text('Delivered'.tr(context))),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'Cancelled', child: Text('Cancel Order'.tr(context), style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            
            // Order Items
            Text('ORDER ITEMS:'.tr(context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 8),
            ...items.map((item) {
              final qty = item['quantity'] ?? 1;
              final name = item['name'] ?? 'Item';
              final instructions = item['specialInstructions'];
              return Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: '${qty}x $name'),
                      if (instructions != null && instructions.toString().isNotEmpty)
                        TextSpan(text: ' ($instructions)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
            
            Padding(
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
                    Text('DRIVER'.tr(context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 4),
                    if (status == 'Pending' || status == 'Preparing')
                      Text('Waiting for \'Ready\''.tr(context), style: TextStyle(fontSize: 12, color: Colors.grey))
                    else if (assignedDriver != null)
                      Text(assignedDriver['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                    else
                      OutlinedButton(
                        onPressed: () => _showAssignDriverDialog(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, 32),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        child: Text('Assign Driver'.tr(context), style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TOTAL'.tr(context), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('BHD ${totalAmount.toStringAsFixed(3)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
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
