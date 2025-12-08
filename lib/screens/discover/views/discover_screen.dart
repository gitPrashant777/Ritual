import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart'; // Ensure OnSaleScreen/others are exported here
import 'package:shop/screens/search/views/components/search_form.dart';

import '../../product/views/BestSellersScreen.dart';
import '../../product/views/MostPopularScreen.dart' show MostPopularScreen;
import '../../product/views/flash_sale_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of options to discover (UI Data only)
    final List<Map<String, dynamic>> discoverOptions = [
      {
        "title": "Flash Sale",
        "subtitle": "Limited Time Deals",
        "icon": Icons.bolt_rounded,
        "color": const Color(0xFFFFAB00), // Amber
      },
      {
        "title": "On Sale",
        "subtitle": "Up to 50% Off",
        "icon": Icons.local_offer_rounded,
        "color": const Color(0xFFFF5252), // Red
      },
      {
        "title": "Most Popular",
        "subtitle": "Trending Now",
        "icon": Icons.whatshot_rounded,
        "color": const Color(0xFFFF6D00), // Deep Orange
      },
      {
        "title": "Best Sellers",
        "subtitle": "Top Rated Items",
        "icon": Icons.star_rounded,
        "color": const Color(0xFF2962FF), // Blue
      },

    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Header & Search Bar Area
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Discover",
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF020953),
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the main Search Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        absorbing: true,
                        child: Hero(
                          tag: 'search_bar_hero',
                          child: const SearchForm(autofocus: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Sales Options Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: defaultPadding,
                  crossAxisSpacing: defaultPadding,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = discoverOptions[index];
                    return _buildDiscoverCard(
                      context: context,
                      title: item['title'],
                      subtitle: item['subtitle'],
                      icon: item['icon'],
                      iconColor: item['color'],
                      onTap: () {
                        // Call the helper method to handle unique navigation
                        _handleNavigation(context, index);
                      },
                    );
                  },
                  childCount: discoverOptions.length,
                ),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding * 4)),
          ],
        ),
      ),
    );
  }

  // --- Unique Navigation Logic ---
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FlashSaleScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnSaleScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MostPopularScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BestSellersScreen()),
        );
        break;

      default:
      // Default fallback
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OnSaleScreen()),
        );
    }
  }

  Widget _buildDiscoverCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF020953),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

