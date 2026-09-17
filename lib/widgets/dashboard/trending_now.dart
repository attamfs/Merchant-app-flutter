import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/translation_extension.dart';

class DashboardTrendingNow extends StatelessWidget {
  DashboardTrendingNow({super.key});

  @override
  Widget build(BuildContext context) {
    final trendingTerms = ['Burgers', 'Coffee', 'Pizza', 'Shawarma', 'Sushi'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue[500]),
                  SizedBox(width: 8),
                  Text('Trending Now'.tr(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.map, color: Theme.of(context).colorScheme.primary),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trendingTerms.length,
              separatorBuilder: (context, index) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _buildTrendingBadge(trendingTerms[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 14, color: Colors.blue[700]),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
