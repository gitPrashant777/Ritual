import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/components/Banner/S/banner_s_style_1.dart';
import 'package:shop/components/Banner/S/banner_s_style_5.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';

import 'components/best_sellers.dart';
import 'components/flash_sale.dart';
import 'components/most_popular.dart';
import 'components/offer_carousel_and_categories.dart';
import 'components/popular_products.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- COLOR RITUAL ---
  static const brandPrimary = Color(0xFF0b3323); // Deep Green
  static const creamColor = Color(0xFFf6efe3);   // Cream BG
  static const lightGreen = Color(0xFF81C784);   // Light Green Accent
  // --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamColor, // RITUAL CREAM BG
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Top Carousel (Handled by OffersCarousel - Dynamic)
            const SliverToBoxAdapter(child: OffersCarouselAndCategories()),

            // 2. Most Popular Products
            const SliverToBoxAdapter(child: MostPopular()),

            // 3. Flash Sale Section
            SliverPadding(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.width < 600
                    ? defaultPadding
                    : defaultPadding * 1.1,
              ),
              sliver: const SliverToBoxAdapter(child: FlashSale()),
            ),

            // 4. Middle Banner (Dynamic with Fallback)
            SliverToBoxAdapter(
              child: _buildDynamicBanner(
                context,
                'Home Middle Banner', // Type to fetch from Firebase
                // Fallback Widget (Static)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Consistent Padding
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BannerSStyle5(
                      title: ' ',
                      subtitle: "",
                      bottomText: " 50% Off SALE".toUpperCase(),
                      press: () => Navigator.pushNamed(context, onSaleScreenRoute),
                    ),
                  ),
                ),
              ),
            ),

            // 5. Best Sellers
            const SliverToBoxAdapter(child: BestSellers()),

            // 6. Bottom Banner (Dynamic with Fallback)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 600
                      ? defaultPadding
                      : defaultPadding, // Removed / 2 for consistency
                ),
                child: _buildDynamicBanner(
                  context,
                  'Home Bottom Banner', // Type to fetch from Firebase
                  // Fallback Widget (Static)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BannerSStyle1(
                        title: "",
                        subtitle: "SPECIAL OFFER",
                        discountParcent: 25,
                        press: () => Navigator.pushNamed(context, onSaleScreenRoute),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 7. Popular Products Grid
            const SliverToBoxAdapter(child: PopularProducts()),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: defaultPadding * 3)),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget to Fetch Banner from Firebase ---
  Widget _buildDynamicBanner(BuildContext context, String type, Widget fallback) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('type', isEqualTo: type) // Filter by Location Type
          .orderBy('createdAt', descending: true) // Get newest first
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Handle Errors (Missing Index, Permission, Network)
        if (snapshot.hasError) {
          print("🔥 Banner Error ($type): ${snapshot.error}");
          return fallback; // Show fallback on error
        }

        // 2. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 160,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: brandPrimary.withOpacity(0.05), // Light tint placeholder
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: brandPrimary
                )
            ),
          );
        }

        // 3. Data Loaded & Banner Exists
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final imageUrl = data['imageUrl'] ?? '';
          final title = data['title'] ?? '';
          final subtitle = data['subtitle'] ?? '';

          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, onSaleScreenRoute),
            child: Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: brandPrimary.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => Icon(
                      Icons.broken_image,
                      color: brandPrimary.withOpacity(0.3)
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      brandPrimary.withOpacity(0.85), // Deep Green overlay
                      Colors.transparent
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          color: creamColor, // Cream text on dark bg
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: creamColor.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        // 4. No Banner Found -> Show Fallback
        return fallback;
      },
    );
  }
}