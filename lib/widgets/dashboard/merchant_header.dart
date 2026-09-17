import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/home/my_qr_screen.dart';
import '../../screens/home/payments_screen.dart';
import '../../screens/home/payment_request_screen.dart';
import '../../services/merchant_service.dart';
import '../../screens/home/settings_screen.dart';
import '../../screens/home/notifications_screen.dart';
import 'package:provider/provider.dart';
import '../../models/merchant_user.dart';
import '../../providers/translation_extension.dart';

class MerchantHeader extends StatefulWidget {
  final String merchantName;
  final String tier;
  final double loyaltyPoints;
  final double issuedLoyalty;
  final double issuedCashback;
  final String? imageUrl;
  final VoidCallback onLogout;
  final bool isCashier;
  final String? cashierName;
  final String? counterNumber;
  final bool isShiftClosed;
  final String merchantId;

  MerchantHeader({
    super.key,
    required this.merchantName,
    required this.tier,
    required this.loyaltyPoints,
    this.issuedLoyalty = 0.0,
    this.issuedCashback = 0.0,
    this.imageUrl,
    required this.onLogout,
    this.isCashier = false,
    this.cashierName,
    this.counterNumber,
    this.isShiftClosed = false,
    required this.merchantId,
  });

  @override
  State<MerchantHeader> createState() => _MerchantHeaderState();
}

class _MerchantHeaderState extends State<MerchantHeader> {
  final GlobalKey _avatarKey = GlobalKey();
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
        color: Color(
          0xFF1EBB5E,
        ), // The specific green color from the screenshot
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          // Top Row: Logo & Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (widget.merchantId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsScreen(
                                  merchantId: widget.merchantId,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      if (widget.merchantId.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('merchants')
                                .doc(widget.merchantId)
                                .collection('notifications')
                                .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty)
                                    return SizedBox.shrink();

                                  int unreadCount = snapshot.data!.docs.where((
                                    doc,
                                  ) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return data['read'] != true &&
                                        data['isRead'] != true;
                                  }).length;

                                  if (unreadCount == 0)
                                    return SizedBox.shrink();

                                  return Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                  ),
                  SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Dismiss',
                        barrierColor: Colors.black12,
                        pageBuilder: (context, anim1, anim2) => SafeArea(
                          child: Stack(
                            children: [
                              Positioned(
                                top: 60,
                                right: 16,
                                child: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  child: Container(
                                    width: 220,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'My Account'.tr(context),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.settings),
                                          title: Text('Settings'.tr(context)),
                                          visualDensity: VisualDensity.compact,
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SettingsScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.logout),
                                          title: Text('Logout'.tr(context)),
                                          visualDensity: VisualDensity.compact,
                                          onTap: () {
                                            Navigator.pop(context);
                                            widget.onLogout();
                                          },
                                        ),
                                        SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      backgroundImage: widget.imageUrl != null
                          ? NetworkImage(widget.imageUrl!)
                          : null,
                      child: widget.imageUrl == null
                          ? Text(
                              widget.merchantName.isNotEmpty
                                  ? widget.merchantName[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
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
                            '${'Hi'.tr(context)} ${widget.merchantName}!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.tier,
                            style: TextStyle(
                              color: Color(0xFF1EBB5E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.isCashier && widget.cashierName != null) ...[
                      SizedBox(height: 4),
                      Text(
                        '${'Cashier'.tr(context)}: ${widget.cashierName} ${widget.counterNumber != null ? '| ${'Counter'.tr(context)}: ${widget.counterNumber}' : ''}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Right side: Loyalty Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _showBD
                        ? '${(widget.loyaltyPoints * _bhdValuePerPoint).toStringAsFixed(3)} ${'BD'.tr(context)}'
                        : '${widget.loyaltyPoints.toStringAsFixed(2)} ${'LP'.tr(context)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBD = !_showBD;
                      });
                    },
                    child: Text(
                      _showBD ? 'Click to check LP'.tr(context) : 'Click to check BD'.tr(context),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${'Issued Loyalty'.tr(context)}: ${widget.issuedLoyalty.toStringAsFixed(0)} ${'LP'.tr(context)}',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    '${'Issued Cashback'.tr(context)}: ${widget.issuedCashback.toStringAsFixed(2)} ${'LP'.tr(context)}',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          // Bottom Row: Main Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildActionItem(
                  context,
                  Icons.qr_code,
                  'My QR',
                  disabled: widget.isCashier && widget.isShiftClosed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyQrScreen()),
                    );
                  },
                ),
              ),
              if (!widget.isCashier)
                Expanded(
                  child: _buildActionItem(
                    context,
                    Icons.verified_user_outlined,
                    'KYC Update',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('KYC Update coming soon'.tr(context)),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: _buildActionItem(
                  context,
                  Icons.credit_card,
                  'Payments',
                  disabled: widget.isCashier && widget.isShiftClosed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentsScreen()),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildActionItem(
                  context,
                  Icons.send,
                  'Payment\nRequest',
                  disabled: widget.isCashier && widget.isShiftClosed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentRequestScreen(),
                      ),
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

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Open counter to access this feature'.tr(context),
                  ),
                ),
              );
            }
          : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              label.tr(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11, // Slightly smaller font to fit 4 items better
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
