import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/merchant_user.dart';
import '../../services/merchant_service.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class MerchantSummary extends StatelessWidget {
  final MerchantUser merchantUser;
  
  MerchantSummary({super.key, required this.merchantUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Overview".tr(context),
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildDataRow(),
        ],
      ),
    );
  }

  Widget _buildDataRow() {
    final service = MerchantService();
    
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: service.streamTodaysTransactions(merchantUser),
      builder: (context, txSnapshot) {
        return StreamBuilder<List<DocumentSnapshot>>(
          stream: service.streamActiveOrders(merchantUser),
          builder: (context, orderSnapshot) {
            
            int txCount = 0;
            double totalSales = 0.0;
            int orderCount = 0;

            if (txSnapshot.hasData) {
              final txs = txSnapshot.data!;
              txCount = txs.length;
              for (var tx in txs) {
                final data = tx.data() as Map<String, dynamic>?;
                if (data != null && data.containsKey('totalAmount')) {
                  final amount = double.tryParse(data['totalAmount'].toString()) ?? 0.0;
                  totalSales += amount;
                }
              }
            }

            if (orderSnapshot.hasData) {
              orderCount = orderSnapshot.data!.length;
            }

            return Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Sales'.tr(context),
                    value: '${totalSales.toStringAsFixed(3)} ${'BD'.tr(context)}',
                    icon: Icons.show_chart,
                    iconColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Trans.'.tr(context),
                    value: '$txCount',
                    icon: Icons.show_chart_outlined, // Placeholder for pulse icon
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Orders'.tr(context),
                    value: '$orderCount',
                    icon: Icons.shopping_cart_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
