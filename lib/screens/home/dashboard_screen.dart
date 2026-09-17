import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard/merchant_header.dart';
import '../../widgets/dashboard/merchant_services_grid.dart';
import '../../widgets/dashboard/merchant_summary.dart';
import '../../widgets/dashboard/merchant_carousel.dart';
import '../../models/merchant_user.dart';
import '../../services/merchant_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/home/transactions_screen.dart';
import '../../screens/home/settings_screen.dart';
import '../../screens/home/my_store_screen.dart';
import '../../screens/home/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'end_of_day_screen.dart';
import 'my_qr_screen.dart';
import 'merchant_payment_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_provider.dart';
import 'create_payment_request_screen.dart';
import '../../providers/translation_extension.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _shiftStatus = 'closed';
  String? _counterNumber;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shiftStatus = prefs.getString('cashier_shift_status') ?? 'closed';
      _counterNumber = prefs.getString('cashier_counter_number');
      _prefsLoaded = true;
    });
  }

  Future<void> _openCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cashier_shift_status', 'open');
    setState(() {
      _shiftStatus = 'open';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Counter Opened: You can now accept payments and process transactions.'.tr(context))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TranslationProvider>().t;
    final theme = Theme.of(context);
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in'.tr(context))));
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(authService, user),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFF1E293B), // Dark slate color
        shape: CircleBorder(),
        child: Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home, label: 'Home'.tr(context), index: 0, isActive: _currentIndex == 0),
              _buildNavItem(icon: Icons.list_alt, label: 'Transactions'.tr(context), index: 1, isActive: _currentIndex == 1),
              SizedBox(width: 48), // Empty space for the FAB
              _buildNavItem(icon: Icons.settings, label: 'Settings'.tr(context), index: 2, isActive: _currentIndex == 2),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile'.tr(context), index: 3, isActive: _currentIndex == 3),
            ],
          ),
        ),
      ),
    );
  }

  void _showCounterClosedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please open your counter to accept payments.'.tr(context))),
    );
  }

  Widget _buildTopAction(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.black87, size: 28),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isActive}) {
    final activeColor = Color(0xFF1EBB5E);
    final inactiveColor = Colors.grey;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AuthService authService, User user) {
    switch (_currentIndex) {
      case 1:
        return TransactionsScreen();
      case 2:
        return SettingsScreen();
      case 3:
        return ProfileScreen();
      case 0:
      default:
        return _buildHomeDashboard(authService, user);
    }
  }

  Widget _buildHomeDashboard(AuthService authService, User user) {
    return FutureBuilder<MerchantUser?>(
      future: authService.getMerchantUser(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !_prefsLoaded) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Failed to load merchant data'.tr(context)));
        }

        final merchantUser = snapshot.data!;

        if (merchantUser.role == MerchantRole.unauthorized || merchantUser.merchantId.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 16),
                Text('Access Denied or Missing Data'.tr(context),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('We could not find your merchant profile.'.tr(context)),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await authService.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  child: Text('Logout'.tr(context)),
                ),
              ],
            ),
          );
        }

        final merchantService = MerchantService();

        return StreamBuilder<DocumentSnapshot>(
          stream: merchantService.streamMerchant(merchantUser.merchantId),
          builder: (context, merchantSnapshot) {
            
            String businessName = 'Loading...';
            String tier = 'STANDARD TIER';
            double loyaltyPoints = 0.0;
            double issuedLoyalty = 0.0;
            double issuedCashback = 0.0;
            String? imageUrl;

            if (merchantSnapshot.hasData && merchantSnapshot.data!.exists) {
              final data = merchantSnapshot.data!.data() as Map<String, dynamic>;
              businessName = data['businessName'] ?? 'Unknown';
              loyaltyPoints = (data['loyaltyPoints'] ?? 0).toDouble();
              issuedLoyalty = (data['issuedMerchantLoyaltyPoints'] ?? 0).toDouble();
              issuedCashback = (data['issuedMerchantCashbackPoints'] ?? 0).toDouble();
              imageUrl = (data['imageUrl'] ?? data['logoUrl'])?.toString();
              if (data['activeSubscription'] != null) {
                tier = (data['activeSubscription']['tierName'] ?? 'STANDARD TIER').toString().toUpperCase() + ' TIER';
              }
            }

            final isCashier = merchantUser.role == MerchantRole.cashier;
            final isShiftClosed = _shiftStatus == 'closed';
            final cashierName = merchantUser.cashierData?['name']?.toString();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: MerchantHeader(
                    merchantName: businessName,
                    tier: tier,
                    loyaltyPoints: loyaltyPoints,
                    issuedLoyalty: issuedLoyalty,
                    issuedCashback: issuedCashback,
                    imageUrl: imageUrl,
                    isCashier: isCashier,
                    cashierName: cashierName,
                    counterNumber: _counterNumber,
                    isShiftClosed: isShiftClosed,
                    merchantId: merchantUser.merchantId,
                    onLogout: () async {
                      await authService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ),
                if (isCashier && isShiftClosed)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Counter is Closed'.tr(context),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text('Open counter to accept payments.'.tr(context),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _openCounter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Open Counter'.tr(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                SliverToBoxAdapter(
                  child: MerchantSummary(merchantUser: merchantUser),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                SliverToBoxAdapter(
                  child: MerchantServicesGrid(
                    isCashier: isCashier,
                    merchantId: merchantUser.merchantId,
                    onEndOfDay: () async {
                      if (isCashier) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EndOfDayScreen(
                            merchantId: merchantUser.merchantId,
                            cashierData: merchantUser.cashierData,
                          ),
                        ));
                      } else {
                        await authService.logout();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      }
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                SliverToBoxAdapter(
                  child: MerchantCarousel(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Padding for the floating action button
                ),
              ],
            );
          },
        );
      },
    );
  }
}
