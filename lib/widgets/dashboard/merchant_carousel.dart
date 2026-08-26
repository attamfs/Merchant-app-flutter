import 'package:flutter/material.dart';

class MerchantCarousel extends StatelessWidget {
  const MerchantCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 180,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCarouselItem('Diversey Hand Wash Soap', Colors.teal.shade100),
            const SizedBox(width: 16),
            _buildCarouselItem('Intercare Hand Wash Soap', Colors.yellow.shade100),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(String title, Color bgColor) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white.withOpacity(0.8),
            padding: const EdgeInsets.all(4),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
