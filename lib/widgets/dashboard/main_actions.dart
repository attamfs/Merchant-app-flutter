import 'package:flutter/material.dart';

class DashboardMainActions extends StatelessWidget {
  const DashboardMainActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionItem(
              context, 
              icon: Icons.qr_code, 
              label: 'My QR', 
              onTap: () {}
            ),
            _buildActionItem(
              context, 
              icon: Icons.verified_user_outlined, 
              label: 'KYC Update', 
              onTap: () {}
            ),
            _buildActionItem(
              context, 
              icon: Icons.credit_card, 
              label: 'Payments', 
              onTap: () {}
            ),
            _buildActionItem(
              context, 
              icon: Icons.send, 
              label: 'Payment Request', 
              onTap: () {}
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
