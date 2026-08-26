import 'package:flutter/material.dart';

class DashboardOurServices extends StatelessWidget {
  const DashboardOurServices({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.card_giftcard, 'label': 'Atta Merchants'},
      {'icon': Icons.shopping_bag, 'label': 'E-Commerce'},
      {'icon': Icons.storefront, 'label': 'E-Merchant'},
      {'icon': Icons.store, 'label': 'E-tager'},
      {'icon': Icons.confirmation_number, 'label': 'Vouchers'},
      {'icon': Icons.badge, 'label': 'Membership Cards'},
      {'icon': Icons.shopping_basket, 'label': 'Order Progress'},
      {'icon': Icons.fitness_center, 'label': 'Fitness Centre'},
      {'icon': Icons.monitor_heart, 'label': 'Health Insurance'},
      {'icon': Icons.medical_services, 'label': 'Medical Services'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(
                context,
                icon: service['icon'] as IconData,
                label: service['label'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
