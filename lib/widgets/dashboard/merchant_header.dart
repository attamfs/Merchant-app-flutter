import 'package:flutter/material.dart';
import '../../screens/home/my_qr_screen.dart';
import '../../screens/home/payments_screen.dart';
import '../../screens/home/payment_request_screen.dart';
import '../../services/merchant_service.dart';

class MerchantHeader extends StatefulWidget {
  final String merchantName;
  final String tier;
  final double loyaltyPoints;
  final double issuedLoyalty;
  final double issuedCashback;
  final VoidCallback onLogout;

  const MerchantHeader({
    super.key,
    required this.merchantName,
    required this.tier,
    required this.loyaltyPoints,
    this.issuedLoyalty = 0.0,
    this.issuedCashback = 0.0,
    required this.onLogout,
  });

  @override
  State<MerchantHeader> createState() => _MerchantHeaderState();
}

class _MerchantHeaderState extends State<MerchantHeader> {
  bool _showBD = false;
  double _bhdValuePerPoint = 0.01;

  @override
  void initState() {
    super.initState();
    _fetchBhdValuePerPoint();
  }

  Future<void> _fetchBhdValuePerPoint() async {
    final value = await MerchantService().getBhdValuePerPoint();
    if (mounted) {
      setState(() {
        _bhdValuePerPoint = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1EBB5E), // The specific green color from the screenshot
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          // Top Row: Logo & Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Placeholder for the "M" logo
              const Icon(Icons.maps_home_work, color: Colors.white, size: 36),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onLogout,
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.storefront, color: Colors.blue), // Placeholder avatar
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Middle Row: Greeting & Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Greeting & Tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Hi ${widget.merchantName}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.tier,
                          style: const TextStyle(
                            color: Color(0xFF1EBB5E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right side: Loyalty Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _showBD 
                      ? '${(widget.loyaltyPoints * _bhdValuePerPoint).toStringAsFixed(3)} BD' 
                      : '${widget.loyaltyPoints.toStringAsFixed(2)} LP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBD = !_showBD;
                      });
                    },
                    child: Text(
                      _showBD ? 'Click to check LP' : 'Click to check BD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Issued Loyalty: ${widget.issuedLoyalty.toStringAsFixed(0)} LP',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Issued Cashback: ${widget.issuedCashback.toStringAsFixed(2)} LP',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Bottom Row: Main Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildActionItem(
                  context,
                  Icons.qr_code, 
                  'My QR',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyQrScreen()),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildActionItem(
                  context,
                  Icons.verified_user_outlined, 
                  'KYC Update',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('KYC Update coming soon')),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildActionItem(
                  context, 
                  Icons.credit_card, 
                  'Payments',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildActionItem(
                  context, 
                  Icons.send, 
                  'Payment\nRequest',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentRequestScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
            fontSize: 11, // Slightly smaller font to fit 4 items better
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
        ),
      ],
      ),
    );
  }
}
