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
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(authService, user),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1E293B), // Dark slate color
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home, label: 'Home', index: 0, isActive: _currentIndex == 0),
              _buildNavItem(icon: Icons.list_alt, label: 'Transactions', index: 1, isActive: _currentIndex == 1),
              const SizedBox(width: 48), // Empty space for the FAB
              _buildNavItem(icon: Icons.settings, label: 'Settings', index: 2, isActive: _currentIndex == 2),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 3, isActive: _currentIndex == 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isActive}) {
    final activeColor = const Color(0xFF1EBB5E);
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
              const SizedBox(height: 2),
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
        return const TransactionsScreen();
      case 2:
        return const SettingsScreen();
      case 3:
        return const MyStoreScreen();
      case 0:
      default:
        return _buildHomeDashboard(authService, user);
    }
  }

  Widget _buildHomeDashboard(AuthService authService, User user) {
    return FutureBuilder<MerchantUser?>(
      future: authService.getMerchantUser(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Failed to load merchant data'));
        }

        final merchantUser = snapshot.data!;
        final merchantService = MerchantService();

        return StreamBuilder<DocumentSnapshot>(
          stream: merchantService.streamMerchant(merchantUser.merchantId),
          builder: (context, merchantSnapshot) {
            
            String businessName = 'Loading...';
            String tier = 'STANDARD TIER';
            double loyaltyPoints = 0.0;
            double issuedLoyalty = 0.0;
            double issuedCashback = 0.0;

            if (merchantSnapshot.hasData && merchantSnapshot.data!.exists) {
              final data = merchantSnapshot.data!.data() as Map<String, dynamic>;
              businessName = data['businessName'] ?? 'Unknown';
              loyaltyPoints = (data['loyaltyPoints'] ?? 0).toDouble();
              issuedLoyalty = (data['issuedMerchantLoyaltyPoints'] ?? 0).toDouble();
              issuedCashback = (data['issuedMerchantCashbackPoints'] ?? 0).toDouble();
              if (data['activeSubscription'] != null) {
                tier = (data['activeSubscription']['tierName'] ?? 'STANDARD TIER').toString().toUpperCase() + ' TIER';
              }
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: MerchantHeader(
                    merchantName: businessName,
                    tier: tier,
                    loyaltyPoints: loyaltyPoints,
                    issuedLoyalty: issuedLoyalty,
                    issuedCashback: issuedCashback,
                    onLogout: () async {
                      await authService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                SliverToBoxAdapter(
                  child: MerchantSummary(merchantUser: merchantUser),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                const SliverToBoxAdapter(
                  child: MerchantServicesGrid(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
                const SliverToBoxAdapter(
                  child: MerchantCarousel(),
                ),
                const SliverToBoxAdapter(
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
