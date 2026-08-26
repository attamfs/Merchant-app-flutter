import 'package:flutter/material.dart';

class DashboardOrderAgain extends StatelessWidget {
  const DashboardOrderAgain({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder merchants
    final merchants = [
      'Al Abraaj',
      'Roast',
      'KFC',
      'McDonalds',
      'Pizza Hut',
      'Subway',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Again',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: merchants.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildMerchantItem(context, merchants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantItem(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Icon(
              Icons.store,
              color: Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
