import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantCarousel extends StatefulWidget {
  MerchantCarousel({super.key});

  @override
  State<MerchantCarousel> createState() => _MerchantCarouselState();
}

class _MerchantCarouselState extends State<MerchantCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<QueryDocumentSnapshot> _ads = [];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;
    
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= itemCount) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('advertisements')
            .where('target', isEqualTo: 'merchant')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SizedBox.shrink();
          }

          final ads = snapshot.data!.docs;
          
          if (_ads.length != ads.length) {
            _ads = ads;
            _startTimer(ads.length);
          }

          return SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                _currentPage = page;
              },
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index].data() as Map<String, dynamic>;
                final imageUrl = ad['imageUrl'] as String?;
                final linkUrl = ad['linkUrl'] as String?;

                return GestureDetector(
                  onTap: () => _launchUrl(linkUrl),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(child: Icon(Icons.broken_image)),
                          )
                        : Center(child: Icon(Icons.image)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
