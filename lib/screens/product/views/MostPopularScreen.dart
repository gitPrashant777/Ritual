// lib/screens/products/most_popular_screen.dart

import 'package:flutter/material.dart';
import '../../../components/product/product_card.dart' show ProductCard;
import '../../../constants.dart';
import '../../../models/product_model.dart';
import '../../../route/route_constants.dart';
import '../../../services/products_api_service.dart';

class MostPopularScreen extends StatefulWidget {
  const MostPopularScreen({super.key});

  @override
  State<MostPopularScreen> createState() => _MostPopularScreenState();
}

class _MostPopularScreenState extends State<MostPopularScreen> {
  final ProductsApiService _apiService = ProductsApiService();

  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _productsFuture = _apiService.getPopularProducts();
    });
  }

  void _retry() {
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // FIX 1: Removed PopScope wrapper.
    // Now the system back button (Android) or swipe back (iOS) works automatically.
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor:
        isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF9F6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          // FIX 2: Changed to pop() to go back to the previous screen
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Most Popular",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontFamily: 'Serif',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_outlined,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              // TODO: Add filter/sort functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(isDark, snapshot.error.toString());
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return _buildProductGrid(isDark, products);
        },
      ),
    );
  }

  Widget _buildProductGrid(bool isDark, List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Text(
            '${products.length} ${products.length == 1 ? 'Product' : 'Products'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildEnhancedProductCard(product, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedProductCard(ProductModel product, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          productDetailsScreenRoute,
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F0F0F)
                        : const Color(0xFFE8E6E3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFE8E6E3),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (product.priceAfetDiscount != null &&
                    product.dicountpercent != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.dicountpercent}% OFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                if (product.isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product.brandName ?? "Rituals").toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.priceAfetDiscount ?? product.price}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        if (product.priceAfetDiscount != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '₹${product.price}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!product.isOutOfStock)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: isDark
                                ? Colors.amber
                                : const Color(0xFF1A1A2E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (product.stockQuantity < 10 &&
                              product.stockQuantity > 0)
                            Text(
                              'Only ${product.stockQuantity} left',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load products. Please try again.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isDark ? Colors.white : const Color(0xFF1A1A2E),
                  foregroundColor:
                  isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                onPressed: _retry,
                child: const Text(
                  "RETRY",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            "No Products Found",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'Serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new arrivals",
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}