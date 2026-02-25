import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../constants.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _currentPage = 0;
  late PageController _pageController;

  // Fallback images
  final List<Map<String, dynamic>> fallbackBanners = [
    {
      'imageUrl': "https://www.meglow.in/cdn/shop/files/MeglowWomenBeautyComboCREAMFACEWASHPEEOFF1.png?v=1729852151",
      'title': 'MIDNIGHT\nLOTION',
      'subtitle': '55€'
    },
    {
      'imageUrl': "https://www.meglow.in/cdn/shop/files/01_Combo.jpg?v=1735824475",
      'title': 'SPECIAL\nOFFER',
      'subtitle': '30% OFF'
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double heroHeight = MediaQuery.of(context).size.width > 600
        ? MediaQuery.of(context).size.height * 0.4
        : MediaQuery.of(context).size.height * 0.56;

    // STREAM: Fetch 'Home Carousel' type only
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('type', isEqualTo: 'Home Carousel') // <--- FILTER
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> banners = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          banners = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        } else {
          banners = fallbackBanners;
        }

        return Container(
          height: heroHeight,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: defaultPadding * 0.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 23, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return Image.network(
                      banner['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
                    );
                  },
                ),
                // Content Overlay
                Positioned(
                  bottom: defaultPadding * 2.1,
                  left: defaultPadding * 1.1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banners[_currentPage]['title'] != null)
                        Text(
                          (banners[_currentPage]['title'] as String).replaceAll('\\n', '\n'),
                          style: const TextStyle(color: Color(0xFF0b3323), fontWeight: FontWeight.bold, fontSize: 24, height: 1.1),
                        ),
                      const SizedBox(height: 8),
                      if (banners[_currentPage]['subtitle'] != null)
                        Text(
                          banners[_currentPage]['subtitle'],
                          style: const TextStyle(color: Color(0xFF0b3323), fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      Row(children: List.generate(banners.length, (index) => _buildDot(isActive: index == _currentPage))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      height: 5,
      width: isActive ? 24 : 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0b3323) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}