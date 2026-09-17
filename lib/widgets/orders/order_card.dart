import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  OrderCard({super.key, required this.orderId, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Fallbacks for data
    final String customerName = orderData['customerName'] ?? 'Guest Customer';
    final total = (orderData['total'] ?? 0) as num;
    final String displayTotal = total.toStringAsFixed(3);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${orderId.substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text('BHD $displayTotal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Decline'.tr(context)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Accept Order'.tr(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
