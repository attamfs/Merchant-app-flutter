import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'merchant_checkout_screen.dart';

class MyPackageScreen extends StatefulWidget {
  const MyPackageScreen({super.key});

  @override
  State<MyPackageScreen> createState() => _MyPackageScreenState();
}

class _MyPackageScreenState extends State<MyPackageScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _merchantData;
  bool _isLoadingMerchant = true;
  String _selectedPricingIndex = '0'; // Used per card ideally, but we'll simplify for MVP

  @override
  void initState() {
    super.initState();
    _fetchMerchantData();
  }

  Future<void> _fetchMerchantData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('merchants').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _merchantData = doc.data();
          _isLoadingMerchant = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingMerchant = false);
      }
    }
  }

  void _handleChoosePlan(Map<String, dynamic> tier, Map<String, dynamic>? activeSub) {
    final pricingTiers = (tier['pricingTiers'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? selectedPricing;
    if (pricingTiers.isNotEmpty) {
      selectedPricing = pricingTiers[0] as Map<String, dynamic>;
    }
    
    final price = (selectedPricing?['price'] ?? 0).toDouble();
    final duration = selectedPricing?['durationMonths'] ?? 0;
    final tierName = tier['name']?.toString() ?? 'Unknown Plan';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantCheckoutScreen(
          tierName: tierName,
          price: price,
          durationMonths: duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoadingMerchant
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('paymentTiers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading packages'));
                }

                var tiers = snapshot.data?.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;
                  return data;
                }).toList() ?? [];

                // Sort bronze, silver, gold
                final order = ['bronze', 'silver', 'gold'];
                tiers.sort((a, b) {
                  final nameA = (a['name'] ?? '').toString().toLowerCase();
                  final nameB = (b['name'] ?? '').toString().toLowerCase();
                  final indexA = order.indexOf(nameA);
                  final indexB = order.indexOf(nameB);
                  
                  if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
                  if (indexA != -1) return -1;
                  if (indexB != -1) return 1;
                  return nameA.compareTo(nameB);
                });

                final activeSub = _merchantData?['activeSubscription'] as Map<String, dynamic>?;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeSub != null && activeSub['status'] == 'active')
                        _buildActiveSubscriptionCard(activeSub),
                      
                      if (activeSub != null && activeSub['status'] == 'active')
                        const SizedBox(height: 24),
                        
                      const Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Choose a plan to upgrade or renew', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 16),
                      
                      ...tiers.map((tier) => _buildTierCard(tier, activeSub)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActiveSubscriptionCard(Map<String, dynamic> activeSub) {
    final tierName = activeSub['tierName'] ?? 'Unknown';
    final isLifetime = activeSub['isLifetime'] == true;
    final expiryDate = activeSub['expiryDate']?.toString();
    final durationMonths = activeSub['durationMonths'] ?? 0;

    String formattedExpiry = 'N/A';
    if (!isLifetime && expiryDate != null) {
      final dt = DateTime.tryParse(expiryDate);
      if (dt != null) {
        formattedExpiry = DateFormat('MMM d, yyyy').format(dt);
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
              ),
              child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.verified_user, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Already Subscribed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Your current business plan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildSubDetailRow(Icons.stars, 'Plan Name', tierName),
                const SizedBox(height: 12),
                _buildSubDetailRow(Icons.event, 'Expiry Date', isLifetime ? 'Lifetime' : formattedExpiry),
                const SizedBox(height: 12),
                _buildSubDetailRow(Icons.access_time, 'Period', isLifetime ? 'Unlimited' : '$durationMonths Months'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubDetailRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier, Map<String, dynamic>? activeSub) {
    final isRecommended = tier['isRecommended'] == true;
    final name = tier['name']?.toString() ?? 'Plan';
    final isCurrent = activeSub?['tierName'] == name;
    
    final pricingTiers = (tier['pricingTiers'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? selectedPricing;
    if (pricingTiers.isNotEmpty) {
      selectedPricing = pricingTiers[0] as Map<String, dynamic>; // Simplified for MVP
    }
    
    final price = (selectedPricing?['price'] ?? 0).toDouble();
    final duration = selectedPricing?['durationMonths'] ?? 0;

    final featuresList = tier['features'] as List<dynamic>?;
    final servicesList = tier['services'] as List<dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isRecommended ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
      ),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(
                    name.toLowerCase().contains('gold') ? Icons.workspace_premium : Icons.stars, 
                    size: 32, 
                    color: name.toLowerCase().contains('gold') ? Colors.yellow[700] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price.toStringAsFixed(3), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Text('BHD / $duration mo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (featuresList != null)
                  ...featuresList.where((f) => f['isAvailable'] == true).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${f['name']}${f['value'] != '✓' ? ' (${f['value']})' : ''}', style: TextStyle(color: Colors.grey[700]))),
                      ],
                    ),
                  )).toList()
                else if (servicesList != null)
                  ...servicesList.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.toString(), style: TextStyle(color: Colors.grey[700]))),
                      ],
                    ),
                  )).toList(),
                  
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (isCurrent || activeSub?['isLifetime'] == true) 
                        ? null 
                        : () => _handleChoosePlan(tier, activeSub),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      backgroundColor: isRecommended ? Theme.of(context).primaryColor : Colors.white,
                      foregroundColor: isRecommended ? Colors.white : Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: Text(
                      isCurrent ? 'Current Plan' : (activeSub?['isLifetime'] == true ? 'Managed by Admin' : 'Choose Plan'), 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
