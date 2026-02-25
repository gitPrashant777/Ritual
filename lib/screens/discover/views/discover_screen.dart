import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/search/views/components/search_form.dart';

import '../../product/views/BestSellersScreen.dart';
import '../../product/views/MostPopularScreen.dart' show MostPopularScreen;
import '../../product/views/flash_sale_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  // Color Ritual Constants
  static const Color ritualBg = Color(0xFFF6EFE3); // Cream
  static const Color ritualDark = Color(0xFF0B3323); // Deep Green
  static const Color ritualAccent = Color(0xFF81C784); // Light Green

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> discoverOptions = [
      {"title": "Flash Sale", "subtitle": "Limited Time", "icon": Icons.bolt, "color": ritualAccent},
      {"title": "On Sale", "subtitle": "Up to 50% Off", "icon": Icons.local_offer, "color": const Color(0xFFBC9E82)},
      {"title": "Most Popular", "subtitle": "Trending Now", "icon": Icons.whatshot, "color": const Color(0xFFD4A373)},
      {"title": "Best Sellers", "subtitle": "Top Rated", "icon": Icons.star, "color": ritualDark},
    ];

    return Scaffold(
      backgroundColor: Colors.white, // Screen BG
      appBar: AppBar(
        // Removed green color, made it transparent to blend with white BG
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Discover",
          style: TextStyle(
            color: ritualDark,
            fontSize: 28, // Increased Title Size
            fontWeight: FontWeight.w800, // Made it bolder
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: ritualDark),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Search Bar Area
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
                  child: const AbsorbPointer(
                    absorbing: true,
                    child: Hero(tag: 'search_bar_hero', child: SearchForm(autofocus: false)),
                  ),
                ),
              ),
            ),

            // 2. Sales Options Grid
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1, // Adjusted for slightly taller cards
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
                      onTap: () => _handleNavigation(context, index),
                    );
                  },
                  childCount: discoverOptions.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Navigation logic remains the same ...
  void _handleNavigation(BuildContext context, int index) {
    final List<Widget> destinations = [
      const FlashSaleScreen(),
      const BestSellersScreen(),
      const MostPopularScreen(),
      const BestSellersScreen(),
    ];
    Navigator.push(context, MaterialPageRoute(builder: (context) => destinations[index]));
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
        color: ritualBg, // Card BG is Cream
        borderRadius: BorderRadius.circular(24), // Even rounder for a premium look
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white, // Clean white circle for the icon
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ritualDark
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: ritualDark.withOpacity(0.5),
                      fontSize: 12
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}