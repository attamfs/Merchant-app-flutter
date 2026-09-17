import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/translation_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantMainActions extends StatelessWidget {
  MerchantMainActions({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('display').snapshots(),
      builder: (context, displaySnapshot) {
        bool hideKycUpdate = false;
        if (displaySnapshot.hasData && displaySnapshot.data!.exists) {
          final displayData = displaySnapshot.data!.data() as Map<String, dynamic>? ?? {};
          hideKycUpdate = displayData['hideKycUpdate'] == true;
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionItem(Icons.qr_code, 'My QR'.tr(context)),
              if (!hideKycUpdate) _buildActionItem(Icons.verified_user, 'KYC Update'.tr(context)),
              _buildActionItem(Icons.credit_card, 'Payments'.tr(context)),
              _buildActionItem(Icons.send, 'Payment Request'.tr(context)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
