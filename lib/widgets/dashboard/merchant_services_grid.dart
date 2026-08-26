import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/dashboard/incoming_orders_list.dart';
import '../../screens/home/my_store_screen.dart';
import '../../screens/home/atta_merchants_screen.dart';
import '../../screens/home/vouchers_screen.dart';
import '../../screens/home/sales_summary_screen.dart';
import '../../screens/home/shift_history_screen.dart';
import '../../screens/home/promotions_screen.dart';
import '../../screens/home/atta_merchants_screen.dart';
import '../../screens/home/register_user_screen.dart';
import '../../screens/home/my_package_screen.dart';
import '../../screens/home/admin_requests_screen.dart';
import '../../screens/home/my_store_screen.dart';
import '../../screens/home/manage_cashiers_screen.dart';

class MerchantServicesGrid extends StatefulWidget {
  const MerchantServicesGrid({super.key});

  @override
  State<MerchantServicesGrid> createState() => _MerchantServicesGridState();
}

class _MerchantServicesGridState extends State<MerchantServicesGrid> {
  bool _showOrders = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('settings').doc('display').snapshots(),
            builder: (context, snapshot) {
              Map<String, dynamic> vis = {};
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                vis = (data['merchantServicesVisibility'] as Map<String, dynamic>?) ?? {};
              }

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  if (vis['myStore'] != false) _buildServiceCard(
                    Icons.store, 
                    'My Store',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyStoreScreen()),
                      );
                    },
                  ),
                  if (vis['merchants'] != false) _buildServiceCard(
                    Icons.storefront, 
                    'Atta Merchants',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AttaMerchantsScreen()),
                      );
                    },
                  ),
                  if (vis['vouchers'] != false) _buildServiceCard(
                    Icons.local_activity, 
                    'Vouchers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VouchersScreen()),
                      );
                    },
                  ),
                  if (vis['salesSummary'] != false) _buildServiceCard(
                    Icons.bar_chart, 
                    'Sales Summary',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesSummaryScreen()),
                      );
                    },
                  ),
                  if (vis['shiftHistory'] != false) _buildServiceCard(
                    Icons.history, 
                    'Shift History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShiftHistoryScreen()),
                      );
                    },
                  ),
                  if (vis['promotions'] != false) _buildServiceCard(
                    Icons.card_giftcard, 
                    'Promotions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PromotionsScreen()),
                      );
                    },
                  ),
                  if (vis['registerUser'] != false) _buildServiceCard(
                    Icons.person_add, 
                    'Register User',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterUserScreen()),
                      );
                    },
                  ),
                  if (vis['myPackage'] != false) _buildServiceCard(
                    Icons.card_membership, 
                    'My Package',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyPackageScreen()),
                      );
                    },
                  ),
                  if (vis['adminRequests'] != false) _buildServiceCard(
                    Icons.description, 
                    'Admin Requests',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminRequestsScreen()),
                      );
                    },
                  ),
                  if (vis['manageOrders'] != false) _buildServiceCard(
                    Icons.shopping_bag, 
                    'Manage Orders',
                    onTap: () {
                      setState(() {
                        _showOrders = !_showOrders;
                      });
                    },
                  ),
                  if (vis['manageDrivers'] != false) _buildServiceCard(Icons.local_shipping, 'Manage Drivers'),
                  if (vis['manageCashiers'] != false) _buildServiceCard(
                    Icons.people, 
                    'Manage Cashiers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageCashiersScreen()),
                      );
                    },
                  ),
                ],
              );
            }
          ),
          if (_showOrders) ...[
            const SizedBox(height: 24),
            const Text(
              'Incoming Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const IncomingOrdersList(),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
