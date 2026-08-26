import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantMainActions extends StatelessWidget {
  const MerchantMainActions({super.key});

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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionItem(Icons.qr_code, 'My QR'),
              if (!hideKycUpdate) _buildActionItem(Icons.verified_user, 'KYC Update'),
              _buildActionItem(Icons.credit_card, 'Payments'),
              _buildActionItem(Icons.send, 'Payment Request'),
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
