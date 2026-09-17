import 'package:flutter/material.dart';

class DashboardImageCarousel extends StatefulWidget {
  DashboardImageCarousel({super.key});

  @override
  State<DashboardImageCarousel> createState() => _DashboardImageCarouselState();
}

class _DashboardImageCarouselState extends State<DashboardImageCarousel> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 160,
        child: PageView(
          controller: _pageController,
          children: [
            _buildAdCard(context, 'Advertisement 1', Colors.blue[100]!),
            _buildAdCard(context, 'Advertisement 2', Colors.purple[100]!),
            _buildAdCard(context, 'Advertisement 3', Colors.green[100]!),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(BuildContext context, String text, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
